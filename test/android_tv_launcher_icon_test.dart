import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _androidAttribute(String source, String element, String attribute) {
  final elementTag = RegExp('<$element\\b[^>]*>').firstMatch(source)!.group(0)!;
  return RegExp(
    'android:$attribute="([^"]+)"',
  ).firstMatch(elementTag)!.group(1)!;
}

void main() {
  test('TV adaptive launcher icon reuses the app brand assets', () {
    final adaptiveIcon = File(
      'android/app/src/main/res/'
      'mipmap-television-anydpi-v26/ic_launcher.xml',
    ).readAsStringSync();
    expect(
      _androidAttribute(adaptiveIcon, 'foreground', 'drawable'),
      '@drawable/ic_launcher_foreground',
    );
    expect(
      _androidAttribute(adaptiveIcon, 'background', 'drawable'),
      '@color/ic_launcher_background',
    );

    for (final density in ['hdpi', 'mdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']) {
      final file = File(
        'android/app/src/main/res/'
        'drawable-$density/ic_launcher_foreground.png',
      );
      expect(file.existsSync(), isTrue, reason: 'missing ${file.path}');
    }
  });
}
