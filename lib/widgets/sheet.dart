import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/common.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/inherited.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'glass.dart';
import 'scaffold.dart';
import 'side_sheet.dart';

@immutable
class SheetProps {
  final double? maxWidth;
  final double? maxHeight;
  final bool isScrollControlled;
  final bool useSafeArea;
  final Color? backgroundColor;
  final bool blur;

  const SheetProps({
    this.maxWidth,
    this.maxHeight,
    this.backgroundColor,
    this.useSafeArea = true,
    this.isScrollControlled = false,
    this.blur = true,
  });
}

@immutable
class ExtendProps {
  final double? maxWidth;
  final bool useSafeArea;
  final bool blur;
  final bool forceFull;

  const ExtendProps({
    this.maxWidth,
    this.useSafeArea = true,
    this.blur = true,
    this.forceFull = false,
  });
}

enum SheetType { page, bottomSheet, sideSheet }

Future<T?> showSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  SheetProps props = const SheetProps(),
}) {
  final isMobile = globalState.container.read(isMobileViewProvider);
  return switch (isMobile) {
    // The physical sheet (drag handle + header + body) paints its own real
    // blur via GlassSurface.modal in AdaptiveSheetScaffold — this route's
    // own backgroundColor must stay transparent, or the sheet would carry a
    // second, unblurred flat-color layer that lets whatever is behind it
    // (the BottomNavigationBar included) stay sharply readable underneath
    // the "glass".
    true => showModalBottomSheet<T>(
      context: context,
      isScrollControlled: props.isScrollControlled,
      builder: (_) {
        return SheetProvider(
          type: SheetType.bottomSheet,
          child: builder(context),
        );
      },
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      useSafeArea: props.useSafeArea,
    ),
    false => showModalSideSheet<T>(
      useSafeArea: props.useSafeArea,
      isScrollControlled: props.isScrollControlled,
      context: context,
      backgroundColor:
          props.backgroundColor ??
          context.colorScheme.surfaceContainerLow.withValues(
            alpha: GlassTokens.opacityFor(
              GlassSurfaceType.modal,
              context.colorScheme.brightness,
            ),
          ),
      constraints: BoxConstraints(maxWidth: props.maxWidth ?? 360),
      filter: props.blur ? commonFilter : null,
      builder: (_) {
        return SheetProvider(
          type: SheetType.sideSheet,
          child: builder(context),
        );
      },
    ),
  };
}

Future<T?> showExtend<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  ExtendProps props = const ExtendProps(),
}) {
  final isMobile = globalState.container.read(isMobileViewProvider);
  return switch (isMobile || props.forceFull) {
    true => BaseNavigator.push(
      context,
      SheetProvider(type: SheetType.page, child: builder(context)),
    ),
    false => showModalSideSheet<T>(
      useSafeArea: props.useSafeArea,
      context: context,
      backgroundColor: context.colorScheme.surface.withValues(
        alpha: GlassTokens.opacityFor(
          GlassSurfaceType.modal,
          context.colorScheme.brightness,
        ),
      ),
      constraints: BoxConstraints(maxWidth: props.maxWidth ?? 360),
      filter: props.blur ? commonFilter : null,
      builder: (context) {
        return SheetProvider(
          type: SheetType.sideSheet,
          child: builder(context),
        );
      },
    ),
  };
}

class AdaptiveSheetScaffold extends StatefulWidget {
  final Widget body;
  final String title;
  final bool sheetTransparentToolBar;
  final List<IconButtonData> actions;
  final VoidCallback? backAction;

  const AdaptiveSheetScaffold({
    super.key,
    required this.body,
    required this.title,
    this.sheetTransparentToolBar = false,
    this.actions = const [],
    this.backAction,
  });

  @override
  State<AdaptiveSheetScaffold> createState() => _AdaptiveSheetScaffoldState();
}

class _AdaptiveSheetScaffoldState extends State<AdaptiveSheetScaffold> {
  final _isScrolledController = ValueNotifier<bool>(false);

  IconData get backIconData {
    if (kIsWeb) {
      return Icons.arrow_back;
    }
    switch (Theme.of(context).platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return Icons.arrow_back;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return Icons.arrow_back_ios_new_rounded;
    }
  }

  @override
  void didUpdateWidget(covariant AdaptiveSheetScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.backAction != widget.backAction) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _isScrolledController.dispose();
    super.dispose();
  }

  Widget _buildIconButton(SheetType type, IconButtonData data) {
    if (type == SheetType.bottomSheet) {
      return IconButton.filledTonal(
        onPressed: data.onPressed,
        style: IconButton.styleFrom(
          visualDensity: VisualDensity.standard,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: Icon(data.icon),
      );
    }
    return IconButton(
      onPressed: data.onPressed,
      style: IconButton.styleFrom(
        visualDensity: VisualDensity.standard,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(data.icon),
    );
  }

  /// A deterministic bottom-sheet header: drag handle above, then a title
  /// row where the leading and trailing slots reserve their own width
  /// (rather than relying on AppBar's leading/actions centring math), so a
  /// long title or an extra action can never collide with the close button.
  Widget _buildSheetHeader({
    required Widget? leading,
    required List<Widget> actions,
  }) {
    const handleSize = Size(28, 4);
    const slotWidth = 48.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 6),
          child: Container(
            alignment: Alignment.center,
            height: handleSize.height,
            width: handleSize.width,
            decoration: ShapeDecoration(
              color: context.colorScheme.onSurfaceVariant,
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(handleSize.height / 2),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 48,
          child: Row(
            children: [
              SizedBox(
                width: slotWidth,
                child: leading != null ? Center(child: leading) : null,
              ),
              Expanded(
                child: Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleLarge?.adjustSize(-4),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: slotWidth),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [...genActions(actions)],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final sheetProvider = SheetProvider.of(context);
    final nestedNavigatorPop = sheetProvider?.nestedNavigatorPop;
    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    final type = sheetProvider?.type ?? SheetType.page;
    final colorScheme = context.colorScheme;
    final glassColor = type == SheetType.bottomSheet
        ? colorScheme.surfaceContainerLow
        : colorScheme.surface;
    final useCloseIcon =
        type != SheetType.page &&
        (nestedNavigatorPop != null && route?.impliesAppBarDismissal == false ||
            nestedNavigatorPop == null);

    final actions = widget.actions
        .map((data) => _buildIconButton(type, data))
        .toList();

    final popButton = type != SheetType.page
        ? (useCloseIcon
              ? _buildIconButton(
                  type,
                  IconButtonData(
                    icon: Icons.close,
                    onPressed: context.safeNestedPop,
                  ),
                )
              : _buildIconButton(
                  type,
                  IconButtonData(
                    icon: backIconData,
                    onPressed:
                        widget.backAction ??
                        () {
                          Navigator.of(context).pop();
                        },
                  ),
                ))
        : null;

    final suffixPop = type != SheetType.page && actions.isEmpty && useCloseIcon;

    if (type == SheetType.bottomSheet) {
      final header = _buildSheetHeader(
        leading: suffixPop ? null : popButton,
        actions: !suffixPop ? actions : [?popButton],
      );
      // Exactly one physical blur for the whole sheet (header + body). The
      // scroll-driven "solidify" effect below only shifts the header's own
      // tint on top of this shared glass — it must NOT add a second
      // BackdropFilter, or the sheet would double-blur its own header.
      return GlassSurface.modal(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        color: glassColor,
        boxShadow: GlassTokens.modalShadowFor(colorScheme.brightness),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!widget.sheetTransparentToolBar) ...[
                header,
                Flexible(child: widget.body),
              ] else ...[
                Flexible(
                  child: Stack(
                    children: [
                      NotificationListener<ScrollNotification>(
                        child: widget.body,
                        onNotification: (notification) {
                          if (notification is ScrollUpdateNotification) {
                            final pixels = notification.metrics.pixels;
                            _isScrolledController.value = pixels > 6;
                          }
                          return false;
                        },
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: ValueListenableBuilder(
                          valueListenable: _isScrolledController,
                          builder: (_, isScrolled, child) {
                            return ColoredBox(
                              color: isScrolled
                                  ? glassColor.opacity60
                                  : Colors.transparent,
                              child: child,
                            );
                          },
                          child: header,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      );
    }

    final appBar = AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      forceMaterialTransparency: true,
      // suffixPop: a side sheet with no caller-supplied actions and a
      // closeable (not back-navigable) state moves the close button into
      // the trailing slot instead of leading, matching the bottom-sheet
      // header's placement below.
      leading: suffixPop ? null : popButton,
      automaticallyImplyLeading: type == SheetType.page,
      // A page pushed full-screen (SheetType.page) centres its title only
      // when there's no leading back button contending for the same space;
      // a long localized title otherwise gets squeezed from both sides.
      // Left-aligned next to the back arrow can never collide.
      centerTitle: type != SheetType.page,
      titleSpacing: 16,
      title: Text(widget.title, overflow: TextOverflow.ellipsis),
      actions: genActions(!suffixPop ? actions : [?popButton]),
      flexibleSpace: LiquidGlassChrome(
        color: glassColor,
        edge: LiquidGlassChromeEdge.bottom,
      ),
    );
    return CommonScaffold(appBar: appBar, body: widget.body);
  }
}
