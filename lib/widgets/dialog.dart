import 'dart:math';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'glass.dart';

/// Desktop max-width tokens for [CommonDialog]. A dialog is never forced
/// to actually reach these — [_dialogMaxWidth] is still clamped against
/// the window size — but combined with [CrossAxisAlignment.stretch] below,
/// title/content/actions always end up sharing the same width instead of a
/// wide [GlassSurface] with narrow, left-aligned content rattling around
/// inside it (the old fixed 300-content-width regression).
const double _kDialogDefaultMaxWidth = 560;
const double _kDialogLargeMaxWidth = 640;

/// Minimum breathing room kept between the dialog and the window/screen
/// edge on each side, on both mobile and desktop.
const double _kDialogHorizontalMargin = 20;

double _dialogMaxWidth(
  Size size, {
  required bool isMobile,
  required bool isLarge,
}) {
  if (isMobile) {
    return size.width - _kDialogHorizontalMargin * 2;
  }
  final cap = isLarge ? _kDialogLargeMaxWidth : _kDialogDefaultMaxWidth;
  return min(size.width - _kDialogHorizontalMargin * 2, cap);
}

class CommonDialog extends ConsumerWidget {
  final String title;
  final Widget? child;
  final List<Widget>? actions;
  final EdgeInsets? padding;
  final bool overrideScroll;
  final Color? backgroundColor;

  /// Opts into the wider (~640px) desktop cap for content-heavy dialogs
  /// (multiple fields, dropdowns, chip rows) that feel cramped at the
  /// ~560px default. Ignored on mobile, where width is always
  /// screen-width minus the safe horizontal margin.
  final bool isLarge;

  const CommonDialog({
    super.key,
    required this.title,
    this.actions,
    this.child,
    this.padding,
    this.overrideScroll = false,
    this.backgroundColor,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context, ref) {
    final size = ref.watch(viewSizeProvider);
    final isMobile = ref.watch(isMobileViewProvider);
    final maxWidth = _dialogMaxWidth(
      size,
      isMobile: isMobile,
      isLarge: isLarge,
    );
    final content = Container(
      constraints: BoxConstraints(maxHeight: min(size.height - 40, 500)),
      padding: padding ?? const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: !overrideScroll ? SingleChildScrollView(child: child) : child,
    );
    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      // Real BackdropFilter blur here (via GlassSurface.modal), unlike the
      // old AlertDialog which only tinted a flat color — matches the
      // AppBar, NavigationBar, and CommonPopupMenu, which all blur for
      // real. Modal-level opacity so the dialog reads as clearly in front
      // of whatever's behind it, not just tinted.
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: GlassSurface.modal(
          shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          color: backgroundColor ?? context.colorScheme.surfaceContainerHigh,
          boxShadow: GlassTokens.modalShadowFor(context.colorScheme.brightness),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            // Forces title/content/actions to the same width (the
            // ConstrainedBox above) instead of each shrink-wrapping to its
            // own intrinsic size — that mismatch is what let a wide title
            // or actions row stretch the glass surface while a
            // separately width-capped content area stayed narrow and
            // left-aligned inside it, with text fields unable to fill the
            // extra space.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Text(title, style: context.textTheme.headlineSmall),
              ),
              Flexible(child: content),
              if (actions != null && actions!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: actions!
                        .separated(const SizedBox(width: 8))
                        .toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class CommonModal extends ConsumerWidget {
  final Widget? child;

  const CommonModal({super.key, this.child});

  @override
  Widget build(BuildContext context, ref) {
    final size = ref.watch(viewSizeProvider);
    return Center(
      child: Container(
        width: size.width * 0.85,
        height: size.height * 0.85,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}
