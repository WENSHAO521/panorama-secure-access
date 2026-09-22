import 'dart:ui';

import 'package:fl_clash/widgets/glass.dart';
import 'package:flutter_test/flutter_test.dart';

// Regression coverage for GlassTokens.modalBackdropFilter (see
// widgets/sheet.dart's side-sheet filter): must match the modal tier's
// calibrated blur, not the much weaker flat sigma the side sheet used
// before (measured visually: sigma 5 left a detailed background largely
// legible, sigma 24 fully frosted it).
void main() {
  test('modalBackdropFilter blurs at the modal tier strength', () {
    expect(
      GlassTokens.modalBackdropFilter,
      ImageFilter.blur(
        sigmaX: GlassTokens.blurModal,
        sigmaY: GlassTokens.blurModal,
      ),
    );
    // Regression guard for the actual bug: the side sheet previously used
    // a flat sigma 5 (commonFilter) instead of the modal tier's 24.
    expect(
      GlassTokens.modalBackdropFilter,
      isNot(ImageFilter.blur(sigmaX: 5, sigmaY: 5)),
    );
  });
}
