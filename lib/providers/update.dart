import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/update_backup.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/action.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/painting.dart' show TextSpan;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'generated/update.g.dart';

const _progressInterval = Duration(milliseconds: 120);
const _speedSmoothing = 0.3;

@Riverpod(keepAlive: true)
class UpdateController extends _$UpdateController {
  @visibleForTesting
  static Future<String> Function() currentVersion = () async =>
      globalState.appVersion;

  CancelToken? _cancelToken;
  List<UpdateAsset> _assets = const [];

  @override
  UpdateState? build() {
    ref.onDispose(() => _cancelToken?.cancel());
    return null;
  }

  /// Registers [release] and, when [download] is set, starts fetching it in the
  /// background. Returns false when this platform has no matching package.
  Future<bool> offer(
    Map<String, dynamic> release, {
    required bool download,
  }) async {
    final tag = release['tag_name'] as String;
    final current = state;
    // A download under way finishes into whatever state is current, so a
    // newer release waits for the next check instead of replacing it.
    if (current != null &&
        (current.isBusy ||
            current.tag == tag && current.stage != UpdateStage.failed)) {
      show();
      return true;
    }
    _assets = parseUpdateAssets(release['assets'] as List<dynamic>? ?? []);
    final asset = await Updater.pickAsset(
      _assets,
      releaseBody: release['body'] as String?,
    );
    if (asset == null) return false;
    state = UpdateState(
      tag: tag,
      asset: asset,
      body: release['body'] as String?,
    );
    if (download) {
      unawaited(start());
    }
    return true;
  }

  Future<bool> canDownloadInBackground() async {
    if (!system.isAndroid) return true;
    final results = await Connectivity().checkConnectivity();
    return results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet);
  }

  Future<void> start() async {
    final current = state;
    if (current == null || current.isBusy) return;
    if (current.stage == UpdateStage.ready && current.filePath != null) {
      await install();
      return;
    }
    final token = CancelToken();
    _cancelToken = token;
    state = current.copyWith(
      stage: UpdateStage.downloading,
      received: 0,
      speed: 0,
      cardVisible: true,
    );
    final clock = Stopwatch()..start();
    var lastTick = Duration.zero;
    var lastReceived = 0;
    var speed = 0.0;
    try {
      final sha256 = await Updater.expectedChecksum(_assets, current.asset);
      final file = await Updater.download(
        current.asset,
        sha256: sha256,
        cancelToken: token,
        onProgress: (received, total) {
          final elapsed = clock.elapsed - lastTick;
          if (elapsed.inMicroseconds == 0) return;
          if (elapsed < _progressInterval && received != total) return;
          final instant =
              (received - lastReceived) * 1000000 / elapsed.inMicroseconds;
          speed = speed == 0
              ? instant
              : speed + (instant - speed) * _speedSmoothing;
          lastTick = clock.elapsed;
          lastReceived = received;
          _patch(
            (value) => value.copyWith(
              received: received,
              total: total > 0 ? total : value.total,
              speed: speed,
            ),
          );
        },
        onVerifying: () => _patch(
          (value) => value.copyWith(stage: UpdateStage.verifying, speed: 0),
        ),
      );
      _patch(
        (value) => value.copyWith(
          stage: UpdateStage.ready,
          filePath: file.path,
          speed: 0,
          cardVisible: true,
        ),
      );
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) {
        _patch(
          (value) => value.copyWith(
            stage: UpdateStage.available,
            received: 0,
            speed: 0,
          ),
        );
        return;
      }
      _fail(error);
    } catch (error) {
      _fail(error);
    } finally {
      if (_cancelToken == token) _cancelToken = null;
    }
  }

  void cancel() => _cancelToken?.cancel();

  /// Leaving the beta drops a pre-release found or fetched while in it, so no
  /// check from the old channel installs one afterwards.
  void dropPreRelease() {
    final current = state;
    if (current == null || !current.tag.contains('-')) return;
    _cancelToken?.cancel();
    _assets = const [];
    state = null;
  }

  Future<void> install() async {
    final path = state?.filePath;
    if (path == null) return;
    try {
      await _backupBeforeInstall();
      if (!await Updater.install(File(path))) {
        _fail('installer did not start');
        return;
      }
      if (system.isWindows) {
        await ref.read(systemActionProvider.notifier).handleExit();
      }
      if (system.isOstree) {
        await _showOstreeUpdateCommand(path);
      }
    } catch (error) {
      _fail(error);
    }
  }

  /// A failed backup is logged and does not hold back the update.
  Future<void> _backupBeforeInstall() async {
    final tag = state?.tag;
    if (tag == null) return;
    try {
      final version = await currentVersion();
      await ref.read(backupActionProvider.notifier).backup((archive) async {
        await updateBackups.save(archive, fromVersion: version, toTag: tag);
        return true;
      });
    } catch (error) {
      commonPrint.log(
        'pre-update backup failed ${compactError(error)}',
        logLevel: LogLevel.warning,
      );
    }
  }

  Future<void> _showOstreeUpdateCommand(String path) async {
    final command = Linux.ostreeUpdateCommand(
      path,
      await linux?.installedPackageName(),
    );
    await dialogs.showAlert(
      title: currentAppLocalizations.ostreeUpdateTitle,
      message: TextSpan(
        text: '${currentAppLocalizations.ostreeUpdateTip}\n\n$command',
      ),
    );
  }

  void show() => _patch((value) => value.copyWith(cardVisible: true));

  void hide() => _patch((value) => value.copyWith(cardVisible: false));

  void _fail(Object error) {
    commonPrint.log(
      'update failed ${compactError(error)}',
      logLevel: LogLevel.warning,
    );
    _patch(
      (value) => value.copyWith(
        stage: UpdateStage.failed,
        speed: 0,
        cardVisible: true,
      ),
    );
  }

  void _patch(UpdateState Function(UpdateState value) update) {
    if (!ref.mounted) return;
    final current = state;
    if (current == null) return;
    state = update(current);
  }
}
