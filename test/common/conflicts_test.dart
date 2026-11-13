import 'package:fl_clash/common/conflicts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads tasklist CSV rows without the .exe suffix', () {
    expect(
      parseProcessNames(
        '"System Idle Process","0","Services","0","8 K"\n'
        '"verge-mihomo.exe","4120","Console","1","40,112 K"\n'
        '"panorama-secure-access-core.exe","5120","Console","1","1 K"\n',
        windows: true,
      ),
      {'system idle process', 'verge-mihomo', 'panorama-secure-access-core'},
    );
  });

  test('reads ps paths by their last component', () {
    expect(
      parseProcessNames(
        '/Applications/Clash Verge.app/Contents/MacOS/clash-verge\n'
        '/usr/bin/sing-box\n'
        'launchd\n',
        windows: false,
      ),
      {'clash-verge', 'sing-box', 'launchd'},
    );
  });

  test('reports other clients and never this app', () {
    expect(
      conflictingProcesses({
        'clash-verge',
        'sing-box',
        'launchd',
        'panorama-secure-access',
        'panorama-secure-access-core',
        'flclashcore',
      }),
      ['clash-verge', 'flclashcore', 'sing-box'],
    );
  });

  test('the next free port skips busy ones and stops at the span', () async {
    expect(
      await nextFreePort(7890, isFree: (port) async => port == 7893),
      7893,
    );
    expect(
      await nextFreePort(7890, span: 2, isFree: (port) async => false),
      isNull,
    );
    expect(await nextFreePort(65535, isFree: (port) async => true), isNull);
  });
}
