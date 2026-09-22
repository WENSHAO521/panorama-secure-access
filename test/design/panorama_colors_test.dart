import 'package:fl_clash/design/colors/panorama_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PanoramaColorsExt', () {
    final scheme = ColorScheme.fromSeed(seedColor: Colors.blue);

    test(
      'accent maps to the theme primary color, never a fixed brand wash',
      () {
        expect(scheme.accent, scheme.primary);
      },
    );

    test('danger maps to the theme error color', () {
      expect(scheme.danger, scheme.error);
      expect(scheme.latencyPoor, scheme.error);
    });

    test('label tokens map to on-surface roles', () {
      expect(scheme.labelPrimary, scheme.onSurface);
      expect(scheme.labelSecondary, scheme.onSurfaceVariant);
    });

    test('surfaceGlass applies alpha, not a plain opaque passthrough', () {
      expect(
        scheme.surfaceGlass,
        isNot(equals(scheme.surfaceContainerHighest)),
      );
    });
  });
}
