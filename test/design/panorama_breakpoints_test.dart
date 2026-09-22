import 'package:fl_clash/design/adaptive/panorama_breakpoints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PanoramaLayoutClass.fromWidth', () {
    test('classifies phone-width layouts as compact', () {
      expect(
        PanoramaLayoutClass.fromWidth(360),
        PanoramaLayoutClass.compact,
      );
      expect(
        PanoramaLayoutClass.fromWidth(599),
        PanoramaLayoutClass.compact,
      );
    });

    test('classifies tablet/small-window layouts as medium', () {
      expect(PanoramaLayoutClass.fromWidth(600), PanoramaLayoutClass.medium);
      expect(PanoramaLayoutClass.fromWidth(768), PanoramaLayoutClass.medium);
      expect(
        PanoramaLayoutClass.fromWidth(1023),
        PanoramaLayoutClass.medium,
      );
    });

    test('classifies desktop-width layouts as expanded', () {
      expect(
        PanoramaLayoutClass.fromWidth(1024),
        PanoramaLayoutClass.expanded,
      );
      expect(
        PanoramaLayoutClass.fromWidth(1920),
        PanoramaLayoutClass.expanded,
      );
    });
  });
}
