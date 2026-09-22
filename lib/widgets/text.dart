import 'package:emoji_regex/emoji_regex.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:flutter/material.dart';

import '../state.dart';

/// Names the app's type hierarchy the way the design spec's Apple-HIG
/// scale does (Large Title/Title/Title 2/Headline/Body/Callout/
/// Subheadline/Footnote/Caption), mapped onto this app's already-tuned
/// Material [TextTheme] (Inter, sized/weighted per role in
/// `application.dart`) rather than introducing a second, parallel font
/// scale. [AppTitle]/[AppBody]/[AppParagraph] above are a *usage-role*
/// abstraction (heading vs. label vs. long-form prose) and stay as the
/// default choice for those three common cases; reach for these named
/// getters directly when a widget's role doesn't fit one of those three
/// (a compact secondary line, a section eyebrow) and you'd otherwise
/// reach for a bare `context.textTheme.someSize` with no semantic name
/// attached — see [ConnectionStatusHeader] for a real call site.
extension AppTypography on BuildContext {
  /// A screen's single biggest heading — this app doesn't currently have
  /// one (no page uses a collapsing/hero title), but the token exists so
  /// one doesn't get invented ad hoc as a one-off font size when it does.
  TextStyle? get largeTitleStyle => textTheme.headlineLarge;

  /// Page/dialog heading — same role and same underlying style as
  /// [AppTitle]'s default.
  TextStyle? get titleStyle => textTheme.headlineSmall;

  /// A secondary heading one step down from [titleStyle]: a prominent
  /// inline label that isn't the page's own title (e.g. the connection
  /// state word atop Home).
  TextStyle? get title2Style => textTheme.titleLarge;

  /// Bold, body-sized emphasis — a row's own sub-heading, not a page
  /// heading.
  TextStyle? get headlineStyle => textTheme.titleMedium;

  /// Slightly larger than [bodyStyle]; for a control's primary label
  /// where [AppBody]'s default reads a touch small.
  TextStyle? get calloutStyle => textTheme.bodyLarge;

  /// Same role and same underlying style as [AppBody]'s default.
  TextStyle? get bodyStyle => textTheme.bodyMedium;

  /// A secondary line directly under a title/headline (e.g. the current
  /// profile name under Home's connection state) — smaller than body,
  /// larger than footnote.
  TextStyle? get subheadlineStyle => textTheme.bodySmall;

  /// Metadata/timestamps/counts — smaller and quieter than body text but
  /// not as small as [captionStyle].
  TextStyle? get footnoteStyle => textTheme.labelMedium;

  /// The smallest role: chip labels, inline status tags.
  TextStyle? get captionStyle => textTheme.labelSmall;
}

/// Page/dialog heading. Always start-aligned — titles are never prose and
/// must never be justified.
class AppTitle extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const AppTitle(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedStyle = style ?? context.textTheme.headlineSmall;
    return Text(
      text,
      textAlign: TextAlign.start,
      style: resolvedStyle,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Normal UI body/label text: settings rows, list titles, short
/// descriptions, technical values. Always start-aligned.
class AppBody extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const AppBody(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedStyle = style ?? context.textTheme.bodyMedium;
    return Text(
      text,
      textAlign: TextAlign.start,
      style: resolvedStyle,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Long-form prose: disclaimers, agreements, help/documentation content.
/// Justifies on comfortably wide layouts and falls back to start alignment
/// on narrow ones, where CJK justification would stretch characters
/// unnaturally (small phones, narrow dialogs, split-screen windows).
class AppParagraph extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final bool selectable;
  final int? maxLines;

  /// Escape hatch for paragraphs that read worse justified — most often
  /// CJK prose carrying a long, unbreakable Latin run (a brand name, a
  /// product name) where justify's gap distribution lands unevenly next
  /// to it. Set false to keep AppParagraph's line height/selectable
  /// behavior while pinning alignment to start regardless of width.
  final bool allowJustify;

  static const double _justifyMinWidth = 280;

  const AppParagraph(
    this.text, {
    super.key,
    this.style,
    this.selectable = false,
    this.maxLines,
    this.allowJustify = true,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedStyle =
        style ?? context.textTheme.bodyMedium?.copyWith(height: 1.55);

    return LayoutBuilder(
      builder: (context, constraints) {
        final align = allowJustify && constraints.maxWidth >= _justifyMinWidth
            ? TextAlign.justify
            : TextAlign.start;

        if (selectable) {
          return SelectableText(
            text,
            textAlign: align,
            style: resolvedStyle,
            maxLines: maxLines,
          );
        }

        return Text(
          text,
          textAlign: align,
          style: resolvedStyle,
          maxLines: maxLines,
        );
      },
    );
  }
}

class TooltipText extends StatelessWidget {
  final Text text;

  const TooltipText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final isOverflow = globalState.measure.computeTextIsOverflow(
          text,
          maxWidth: maxWidth,
        );
        if (isOverflow) {
          return Tooltip(
            triggerMode: TooltipTriggerMode.longPress,
            preferBelow: false,
            message: text.data,
            child: text,
          );
        }
        return text;
      },
    );
  }
}

class TooltipTextV2 extends StatefulWidget {
  final Text text;

  const TooltipTextV2({super.key, required this.text});

  @override
  State<TooltipTextV2> createState() => _TooltipTextV2State();
}

class _TooltipTextV2State extends State<TooltipTextV2> {
  bool _isOverflow = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOverflow();
    });
  }

  void _checkOverflow() {
    if (!mounted) {
      return;
    }
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final isOverflow = globalState.measure.computeTextIsOverflow(
      widget.text,
      maxWidth: renderBox.size.width,
    );
    setState(() => _isOverflow = isOverflow);
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      triggerMode: TooltipTriggerMode.longPress,
      preferBelow: false,
      message: _isOverflow ? widget.text.data : '',
      child: widget.text,
    );
  }
}

class EmojiText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const EmojiText(
    this.text, {
    super.key,
    this.maxLines,
    this.overflow,
    this.style,
  });

  List<TextSpan> _buildTextSpans(String emojis) {
    final List<TextSpan> spans = [];
    final matches = emojiRegex().allMatches(text);

    int lastMatchEnd = 0;
    for (final match in matches) {
      if (match.start > lastMatchEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastMatchEnd, match.start),
            style: style,
          ),
        );
      }
      spans.add(
        TextSpan(
          text: match.group(0),
          style: style?.copyWith(fontFamily: FontFamily.twEmoji.value),
        ),
      );
      lastMatchEnd = match.end;
    }
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd), style: style));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      textScaler: MediaQuery.of(context).textScaler,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
      text: TextSpan(children: _buildTextSpans(text)),
    );
  }
}

// class HighlightText extends StatelessWidget {
//   const HighlightText({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return RichText(
//       textScaler: MediaQuery.of(context).textScaler,
//       maxLines: maxLines,
//       overflow: overflow ?? TextOverflow.clip,
//       text: TextSpan(
//         children: _buildTextSpans(text),
//       ),
//     );
//   }
// }
