import 'dart:async';
import 'dart:io';

import 'package:fl_clash/pages/error.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rust_api/rust_api.dart';

import 'application.dart';
import 'common/common.dart';
import 'widgets/glass.dart';

Future<void> main() async {
  // Must be set before WidgetsFlutterBinding.ensureInitialized() —
  // PaintingBinding.initInstances (which that call triggers) is what
  // actually runs it. See LiquidGlassShaderWarmUp's own doc: this moves
  // first-use shader compilation for the Liquid Glass material system's
  // blur/gradient combinations from the first time they appear mid-
  // interaction (e.g. the first tab switch that reveals a new glass
  // surface) to this one predictable moment at launch instead.
  PaintingBinding.shaderWarmUp = const LiquidGlassShaderWarmUp();
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (system.isDesktop) {
      await RustLib.init();
    }
    final version = await system.version;
    final container = await globalState.init(version);
    HttpOverrides.global = FlClashHttpOverrides();
    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const Application(),
      ),
    );
  } catch (e, s) {
    runApp(
      MaterialApp(
        home: InitErrorScreen(error: e, stack: s),
      ),
    );
  }
}
