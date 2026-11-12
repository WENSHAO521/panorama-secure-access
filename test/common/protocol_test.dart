import 'package:fl_clash/common/protocol.dart';
import 'package:test/test.dart';

void main() {
  group('ProtocolRegistrationPlan', () {
    test('builds registry writes for URL protocol registration', () {
      const plan = ProtocolRegistrationPlan(
        scheme: 'clash',
        executable:
            r'C:\Program Files\Panorama Secure Access\panorama-secure-access.exe',
      );

      expect(plan.protocolKey, r'Software\Classes\clash');
      expect(plan.commandKey, r'shell\open\command');
      expect(plan.protocolValueName, 'URL Protocol');
      expect(plan.protocolValue, '');
      expect(
        plan.command,
        r'"C:\Program Files\Panorama Secure Access\panorama-secure-access.exe" "%1"',
      );
    });
  });

  group('LinuxProtocolRegistrationPlan', () {
    const plan = LinuxProtocolRegistrationPlan(
      schemes: protocolSchemes,
      executable: '/home/me/Apps/panorama-secure-access.AppImage',
      applicationsDir: '/home/me/.local/share/applications',
    );

    test('writes a hidden desktop entry claiming every scheme', () {
      expect(
        plan.desktopPath,
        '/home/me/.local/share/applications/panorama-secure-access-url-handler.desktop',
      );
      expect(
        plan.desktopEntry,
        '[Desktop Entry]\n'
        'Type=Application\n'
        'Name=Panorama Secure Access\n'
        'NoDisplay=true\n'
        'Exec="/home/me/Apps/panorama-secure-access.AppImage" %u\n'
        'MimeType=x-scheme-handler/clash;x-scheme-handler/clashmeta;\n',
      );
    });

    test('makes the entry the default handler for every scheme', () {
      expect(plan.xdgMimeArguments, [
        'default',
        'panorama-secure-access-url-handler.desktop',
        'x-scheme-handler/clash',
        'x-scheme-handler/clashmeta',
      ]);
    });

    test('never claims FlClash\'s own scheme', () {
      expect(protocolSchemes, isNot(contains('flclash')));
      expect(importSchemes, contains('flclash'));
    });

    test('escapes reserved characters in the executable path', () {
      const plan = LinuxProtocolRegistrationPlan(
        schemes: ['clash'],
        executable: r'/opt/my "apps"/$HOME/100%/Fl`Clash\bin',
        applicationsDir: '/tmp',
      );

      expect(plan.exec, r'"/opt/my \"apps\"/\$HOME/100%%/Fl\`Clash\\bin" %u');
    });
  });
}
