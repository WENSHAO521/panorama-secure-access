import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:prism_ui/banner.dart';

import 'app_localizations.dart';
import 'conflicts.dart';
import 'dialog.dart';
import 'legacy_data.dart';
import 'legacy_install.dart';
import 'preferences.dart';

typedef StartupConfirm =
    Future<bool> Function({
      required String title,
      required String message,
      required String confirmText,
    });

typedef StartupNotify = void Function(String message, BannerLevel level);

Future<bool> _confirm({
  required String title,
  required String message,
  required String confirmText,
}) async {
  final result = await dialogs.showMessage(
    title: title,
    message: TextSpan(text: message),
    confirmText: confirmText,
    cancelText: currentAppLocalizations.updateLater,
  );
  return result == true;
}

void _notify(String message, BannerLevel level) {
  dialogs.showBanner(message, level: level);
}

/// What runs before the first Core start: leftovers of FlClash-era installs
/// and anything else already holding this app's port.
class StartupChecks {
  final StartupConfirm confirm;
  final StartupNotify notify;
  final Future<List<String>> Function() findProcesses;
  final Future<bool> Function(int port) isPortFree;
  final Future<List<LegacyInstall>> Function() findInstalls;
  final Future<bool> Function(LegacyInstall install) removeInstall;
  final Future<bool> Function() wasOffered;
  final Future<void> Function() markOffered;

  StartupChecks({
    this.confirm = _confirm,
    this.notify = _notify,
    this.findProcesses = findConflictingProcesses,
    this.isPortFree = isLoopbackPortFree,
    Future<List<LegacyInstall>> Function()? findInstalls,
    Future<bool> Function(LegacyInstall install)? removeInstall,
    Future<bool> Function()? wasOffered,
    Future<void> Function()? markOffered,
  }) : findInstalls = findInstalls ?? findLegacyDesktopInstalls,
       removeInstall = removeInstall ?? legacyInstalls.remove,
       wasOffered = wasOffered ?? preferences.getLegacyInstallOffered,
       markOffered = markOffered ?? preferences.setLegacyInstallOffered;

  /// Returns the port the user switched to, if any.
  Future<int?> checkConflicts({
    required int mixedPort,
    required bool silent,
  }) async {
    final others = await findProcesses();
    if (mixedPort > 0 && !await isPortFree(mixedPort)) {
      final free = await nextFreePort(mixedPort, isFree: isPortFree);
      if (free == null || silent) {
        notify(
          currentAppLocalizations.portInUseBanner(mixedPort),
          BannerLevel.error,
        );
        return null;
      }
      final switched = await confirm(
        title: currentAppLocalizations.portInUseTitle(mixedPort),
        message: currentAppLocalizations.portInUseTip(mixedPort, free),
        confirmText: currentAppLocalizations.portInUseSwitch,
      );
      return switched ? free : null;
    }
    if (others.isNotEmpty) {
      notify(
        currentAppLocalizations.conflictingClientsTip(others.join(', ')),
        BannerLevel.warning,
      );
    }
    return null;
  }

  Future<void> handleLegacyDesktop({
    required LegacyDataImport? imported,
    required bool silent,
  }) async {
    _reportImport(imported);
    if (silent || await wasOffered()) {
      return;
    }
    final installs = await findInstalls();
    if (installs.isEmpty) {
      return;
    }
    await markOffered();
    final confirmed = await confirm(
      title: currentAppLocalizations.legacyInstallTitle,
      message: currentAppLocalizations.legacyInstallTip(
        installs.map((item) => item.id).join(', '),
      ),
      confirmText: currentAppLocalizations.legacyInstallRemove,
    );
    if (!confirmed) {
      return;
    }
    for (final install in installs) {
      if (!await removeInstall(install)) {
        notify(
          currentAppLocalizations.legacyInstallRemoveFailed,
          BannerLevel.error,
        );
      }
    }
  }

  /// A new application id cannot replace the old app, and Android keeps each
  /// app's data private, so the user moves it through a backup file.
  /// Returns whether the user chose to restore one now.
  Future<bool> guideAndroidImport({
    required bool silent,
    required bool hasProfiles,
    required Future<List<String>> Function() installedPackages,
  }) async {
    if (silent || await wasOffered()) {
      return false;
    }
    if (hasProfiles) {
      await markOffered();
      return false;
    }
    final legacy = (await installedPackages())
        .where(legacyAndroidPackages.contains)
        .toList();
    await markOffered();
    if (legacy.isEmpty) {
      return false;
    }
    return confirm(
      title: currentAppLocalizations.legacyAndroidImportTitle,
      message: currentAppLocalizations.legacyAndroidImportTip(
        legacy.join(', '),
      ),
      confirmText: currentAppLocalizations.legacyAndroidImportAction,
    );
  }

  void _reportImport(LegacyDataImport? imported) {
    if (imported != null) {
      notify(
        currentAppLocalizations.legacyDataImported(imported.source),
        BannerLevel.info,
      );
    }
  }
}

final startupChecks = StartupChecks();
