import 'dart:async';
import 'dart:io';

import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/pages/error.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rust_api/rust_api.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'application.dart';
import 'bootstrap.dart';
import 'common/app_data.dart';
import 'common/common.dart';
import 'common/legacy_data.dart';
import 'common/preferences_store.dart';
import 'common/window.dart';

void main(List<String> args) {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      // Package icons are the only images held; the default 100 MB cap would
      // keep every icon of a long app list decoded.
      PaintingBinding.instance.imageCache.maximumSizeBytes = 32 << 20;
      if (Platform.isWindows || Platform.isLinux) {
        SharedPreferencesStorePlatform.instance = AtomicFilePreferencesStore(
          appPath.sharedPreferencesPath,
        );
      }
      if (Platform.isLinux) {
        linkManager.seedInitialLink(args);
      }
      FlutterError.onError = logFlutterError;
      try {
        await RustLib.init();
        await importLegacyData(await appPath.homeDirPath);
        final version = await system.init();
        final container = await bootstrap.init(version);
        await FlClashHttpOverrides.trustCoreRoots();
        HttpOverrides.global = FlClashHttpOverrides(container);
        request.attach(container.read);
        runApp(
          UncontrolledProviderScope(
            container: container,
            child: const Application(),
          ),
        );
      } catch (e, s) {
        runApp(initFailureApp(e, s));
        unawaited(window?.showInitFailure(onExit: _exitAfterInitFailure));
      }
    },
    (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stack),
      );
    },
  );
}

/// Logs a framework error on the next microtask, off the frame that hit it.
@visibleForTesting
void logFlutterError(FlutterErrorDetails details) {
  Future.microtask(() {
    commonPrint.log(
      'exception: ${details.exception} stack: ${details.stack}',
      logLevel: LogLevel.warning,
    );
  });
}

@visibleForTesting
Widget initFailureApp(Object error, StackTrace stack) {
  commonPrint.log('Startup failed: $error\n$stack', logLevel: LogLevel.error);
  return InitErrorApp(
    error: error,
    stack: stack,
    onClearData: clearAppData,
    onExit: _exitAfterInitFailure,
  );
}

Future<void> _exitAfterInitFailure() async {
  await system.exit();
  window?.forceExit();
}
