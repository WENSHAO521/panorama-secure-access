import 'package:fl_clash/common/app_localizations.dart';
import 'package:fl_clash/common/legacy_data.dart';
import 'package:fl_clash/common/legacy_install.dart';
import 'package:fl_clash/common/startup_checks.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism_ui/banner.dart';

class _Harness {
  final asked = <String>[];
  final banners = <(String, BannerLevel)>[];
  final removed = <LegacyInstall>[];
  var answer = true;
  var offered = false;
  var marks = 0;
  Set<int> busy = {};
  List<String> processes = const [];
  List<LegacyInstall> installs = const [];
  Set<LegacyInstall> failing = {};

  StartupChecks get checks => StartupChecks(
    confirm:
        ({
          required String title,
          required String message,
          required String confirmText,
        }) async {
          asked.add(title);
          return answer;
        },
    notify: (message, level) => banners.add((message, level)),
    findProcesses: () async => processes,
    isPortFree: (port) async => !busy.contains(port),
    findInstalls: () async => installs,
    removeInstall: (install) async {
      removed.add(install);
      return !failing.contains(install);
    },
    wasOffered: () async => offered,
    markOffered: () async {
      offered = true;
      marks++;
    },
  );
}

void main() {
  late _Harness harness;
  late AppLocalizations l10n;

  setUp(() async {
    await AppLocalizations.load(const Locale('en'));
    l10n = currentAppLocalizations;
    harness = _Harness();
  });

  group('checkConflicts', () {
    test('offers the next free port and returns it once accepted', () async {
      harness.busy = {7890, 7891};

      final port = await harness.checks.checkConflicts(
        mixedPort: 7890,
        silent: false,
      );

      expect(port, 7892);
      expect(harness.asked, [l10n.portInUseTitle(7890)]);
    });

    test('keeps the port when the user declines', () async {
      harness
        ..busy = {7890}
        ..answer = false;

      expect(
        await harness.checks.checkConflicts(mixedPort: 7890, silent: false),
        isNull,
      );
    });

    test('only warns during a silent start', () async {
      harness.busy = {7890};

      expect(
        await harness.checks.checkConflicts(mixedPort: 7890, silent: true),
        isNull,
      );
      expect(harness.asked, isEmpty);
      expect(harness.banners, [
        (l10n.portInUseBanner(7890), BannerLevel.error),
      ]);
    });

    test('names other clients when the port is free', () async {
      harness.processes = ['clash-verge', 'sing-box'];

      await harness.checks.checkConflicts(mixedPort: 7890, silent: false);

      expect(harness.banners, [
        (
          l10n.conflictingClientsTip('clash-verge, sing-box'),
          BannerLevel.warning,
        ),
      ]);
    });

    test('says nothing when all is clear', () async {
      await harness.checks.checkConflicts(mixedPort: 7890, silent: false);

      expect(harness.banners, isEmpty);
      expect(harness.asked, isEmpty);
    });
  });

  group('handleLegacyDesktop', () {
    const deb = LegacyInstall(LegacyInstallKind.deb, 'flclash');
    const app = LegacyInstall(LegacyInstallKind.macApp, '/Applications/x');

    test('reports imported data and removes what the user agrees to', () async {
      harness
        ..installs = [deb, app]
        ..failing = {app};

      await harness.checks.handleLegacyDesktop(
        imported: const LegacyDataImport(source: '/old', preferences: false),
        silent: false,
      );

      expect(harness.removed, [deb, app]);
      expect(harness.marks, 1);
      expect(harness.banners, [
        (l10n.legacyDataImported('/old'), BannerLevel.info),
        (l10n.legacyInstallRemoveFailed, BannerLevel.error),
      ]);
    });

    test('asks only once and never during a silent start', () async {
      harness.installs = [deb];

      await harness.checks.handleLegacyDesktop(imported: null, silent: true);
      expect(harness.asked, isEmpty);

      harness.answer = false;
      await harness.checks.handleLegacyDesktop(imported: null, silent: false);
      await harness.checks.handleLegacyDesktop(imported: null, silent: false);

      expect(harness.asked, [l10n.legacyInstallTitle]);
      expect(harness.removed, isEmpty);
    });

    test('remembers nothing while no old install exists', () async {
      await harness.checks.handleLegacyDesktop(imported: null, silent: false);

      expect(harness.offered, isFalse);
    });
  });

  group('guideAndroidImport', () {
    Future<bool> guide({bool hasProfiles = false, List<String>? installed}) {
      return harness.checks.guideAndroidImport(
        silent: false,
        hasProfiles: hasProfiles,
        installedPackages: () async =>
            installed ?? ['com.example', legacyBundleId],
      );
    }

    test('points to a restore while an old app is installed', () async {
      expect(await guide(), isTrue);
      expect(harness.asked, [l10n.legacyAndroidImportTitle]);
      expect(harness.offered, isTrue);
    });

    test('stays quiet once profiles exist or no old app is left', () async {
      expect(await guide(hasProfiles: true), isFalse);
      harness.offered = false;
      expect(await guide(installed: ['com.example']), isFalse);
      expect(harness.asked, isEmpty);
    });

    test('never asks twice', () async {
      harness.answer = false;
      expect(await guide(), isFalse);
      expect(await guide(), isFalse);
      expect(harness.asked, hasLength(1));
    });
  });
}
