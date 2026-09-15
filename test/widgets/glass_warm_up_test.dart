import 'package:fl_clash/widgets/glass.dart';
import 'package:flutter_test/flutter_test.dart';

// LiquidGlassShaderWarmUp regression coverage: execute() actually runs the
// real dart:ui canvas operations (saveLayer/clipRRect/gradient shaders/
// path stroke) rather than just type-checking, since a bad canvas call
// (unbalanced save/restore, an invalid rect) would only surface at
// runtime, not at analyze time — and this is exactly the code path that
// runs, unobserved, before the very first frame in production.

void main() {
  testWidgets('LiquidGlassShaderWarmUp.execute runs without throwing', (
    tester,
  ) async {
    await const LiquidGlassShaderWarmUp().execute();
  });
}
