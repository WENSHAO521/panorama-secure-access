import 'package:flutter/material.dart';

/// Design tokens for the "editorial minimal" redesign (Direction C from
/// the redesign proposal). Used by the screens/chrome that have opted
/// into this look; not wired into the app's global ThemeData/ColorScheme,
/// so screens that haven't been converted yet are unaffected.
abstract final class EditorialPalette {
  static const paper = Color(0xFFFAF9F6);
  static const ink = Color(0xFF1C1B18);
  static const muted = Color(0xFF8A8676);
  static const mutedStrong = Color(0xFF5C594E);
  static const hairline = Color(0xFFE4E1D8);
  static const accent = Color(0xFF4338CA);
}

// No bundled serif ships with the app yet, so this falls back through
// whatever serif each platform already has (including CJK serifs, since
// most of this screen's text is Chinese) rather than pulling in a new
// font asset for a single prototype screen.
const editorialSerifFallback = [
  'Noto Serif SC',
  'Songti SC',
  'STSong',
  'SimSun',
  'Georgia',
  'serif',
];

/// Forces a screen onto a light color scheme (still seeded from the
/// user's chosen accent color, so it stays on-brand) regardless of the
/// app's dark-mode setting. Direction C is a light-only design — without
/// this, widgets that pull their color from `context.colorScheme`
/// (list tiles, chips, log-level text, …) would keep resolving the
/// dark-mode-tuned near-white values and go unreadable against the flat
/// paper background this redesign uses everywhere.
ThemeData editorialLightTheme(BuildContext context) {
  final theme = Theme.of(context);
  final lightScheme = ColorScheme.fromSeed(
    seedColor: theme.colorScheme.primary,
    brightness: Brightness.light,
  );
  return theme.copyWith(brightness: Brightness.light, colorScheme: lightScheme);
}

TextStyle editorialSerif({
  double size = 20,
  FontWeight weight = FontWeight.w600,
  Color? color,
  double? height,
}) {
  return TextStyle(
    fontFamily: 'Georgia',
    fontFamilyFallback: editorialSerifFallback,
    fontSize: size,
    fontWeight: weight,
    color: color ?? EditorialPalette.ink,
    height: height,
  );
}

/// One row of the dashboard's "ledger": a muted label on the left and a
/// serif value on the right, separated from the next row by a hairline
/// instead of living inside its own card.
class LedgerRow extends StatelessWidget {
  final String label;
  final Widget value;
  final bool showDivider;

  const LedgerRow({
    super.key,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: showDivider
          ? const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: EditorialPalette.hairline),
              ),
            )
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: EditorialPalette.mutedStrong,
            ),
          ),
          value,
        ],
      ),
    );
  }
}
