import 'package:fl_clash/design/icons/panorama_icon_resolver.dart';
import 'package:fl_clash/design/icons/panorama_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PanoramaIconResolver', () {
    const token = PanoramaIconToken(
      material: Icons.arrow_back,
      apple: Icons.arrow_back_ios_new_rounded,
    );

    test('uses the Apple glyph on Apple platforms', () {
      expect(
        PanoramaIconResolver.resolve(token, apple: true),
        Icons.arrow_back_ios_new_rounded,
      );
    });

    test('uses the Material glyph elsewhere', () {
      expect(
        PanoramaIconResolver.resolve(token, apple: false),
        Icons.arrow_back,
      );
    });

    test('falls back to the Material glyph without an Apple variant', () {
      const plain = PanoramaIconToken(material: Icons.close);
      expect(PanoramaIconResolver.resolve(plain, apple: true), Icons.close);
    });
  });

  group('PanoramaIcons', () {
    test('one meaning, one glyph: former duplicate variants are unified', () {
      // Call sites used Icons.delete, Icons.delete_outlined and
      // Icons.delete_outline for the same action.
      expect(PanoramaIcons.actions.delete, Icons.delete_outline);
      // Icons.sync and Icons.sync_alt_sharp were both "sync".
      expect(PanoramaIcons.actions.sync, Icons.sync);
    });

    test('status glyphs are distinct from each other', () {
      const s = PanoramaIcons.status;
      final glyphs = [
        s.ok,
        s.partial,
        s.blocked,
        s.failed,
        s.unknown,
        s.notChecked,
      ];
      expect(glyphs.toSet(), hasLength(glyphs.length));
    });

    test('window caption glyphs are distinct from each other', () {
      const w = PanoramaIcons.window;
      final glyphs = [w.pin, w.unpin, w.minimize, w.maximize, w.restore];
      expect(glyphs.toSet(), hasLength(glyphs.length));
    });
  });
}
