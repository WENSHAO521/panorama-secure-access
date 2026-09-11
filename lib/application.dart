import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/core/core.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/manager/hotkey_manager.dart';
import 'package:fl_clash/manager/manager.dart';
import 'package:fl_clash/plugins/app.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pages/pages.dart';

class Application extends ConsumerStatefulWidget {
  const Application({super.key});

  @override
  ConsumerState<Application> createState() => ApplicationState();
}

class ApplicationState extends ConsumerState<Application> {
  Timer? _autoUpdateProfilesTaskTimer;
  bool _preHasVpn = false;

  final _pageTransitionsTheme = const PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.android: commonSharedXPageTransitions,
      TargetPlatform.windows: commonSharedXPageTransitions,
      TargetPlatform.linux: commonSharedXPageTransitions,
      TargetPlatform.macOS: commonSharedXPageTransitions,
    },
  );

  ColorScheme _getAppColorScheme({
    required Brightness brightness,
    int? primaryColor,
  }) {
    return ref.read(genColorSchemeProvider(brightness));
  }

  // Fills in ThemeData sub-themes (chips, dialogs, sheets) that Flutter
  // otherwise defaults to opaque Material colors, so they read as part of
  // the glass shell instead of standing out against it.
  //
  // Deliberately NOT included: InputDecorationTheme. Every TextField in
  // this app already defines its own decoration (border, fill, padding) —
  // a global filled/fillColor/OutlineInputBorder here would paint a second,
  // differently-shaped border/fill underneath each field's own, producing
  // double borders and broken sizing (see the config/profile editor
  // regression). Glass-styled inputs are opt-in via `glassInputDecoration()`
  // (lib/widgets/glass.dart), applied per field, never globally.
  ThemeData _buildThemeData(ColorScheme colorScheme) {
    final brightness = colorScheme.brightness;
    final borderSide = BorderSide(
      color: colorScheme.outlineVariant.withValues(
        alpha: GlassTokens.borderOpacityFor(brightness),
      ),
    );
    return ThemeData(
      useMaterial3: true,
      // Inter (OFL-licensed, bundled in assets/fonts/) instead of the
      // Material default (Roboto/San Francisco/Segoe depending on
      // platform) for a consistent brand look across desktop and mobile.
      // Only covers Latin/Cyrillic/Greek — CJK glyphs (zh/ja locales) fall
      // through to the platform's system font automatically, the same way
      // they already render today.
      fontFamily: 'Inter',
      pageTransitionsTheme: _pageTransitionsTheme,
      // Transparent so every Scaffold reveals the AmbientBackground
      // painted once behind the app shell (see HomePage) instead of
      // painting its own opaque surface color over it.
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: colorScheme,
      chipTheme: ChipThemeData(
        // Chips are lightweight, often-repeated controls, not mini glass
        // panels — a low tint (same family as GlassSurfaceType.repeated)
        // instead of a near-opaque fill.
        backgroundColor: colorScheme.surfaceContainerHighest.withValues(
          alpha: GlassTokens.opacityFor(GlassSurfaceType.repeated, brightness),
        ),
        selectedColor: colorScheme.primary.withValues(alpha: 0.16),
        side: borderSide,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        // Both showModalBottomSheet and our ModalSideSheetRoute fall back to
        // this when no explicit barrierColor is passed. Flutter's own
        // default (Colors.black54) reads as an excessively grey/dark scrim;
        // low, brightness-aware alpha keeps the page behind recognizable.
        modalBarrierColor: Colors.black.withValues(
          alpha: GlassTokens.modalBarrierOpacityFor(brightness),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(
          alpha: GlassTokens.dividerOpacityFor(brightness),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      if (globalState.navigatorKey.currentContext != null) {
        await globalState.attach();
      } else {
        exit(0);
      }
      _autoUpdateProfilesTask();
      _initLink();
      app?.initShortcuts();
    });
  }

  void _initLink() {
    linkManager.initAppLinksListen((url) async {
      final res = await globalState.showMessage(
        title: currentAppLocalizations.addProfile,
        message: TextSpan(
          children: [
            TextSpan(text: currentAppLocalizations.doYouWantToPass),
            TextSpan(
              text: ' $url ',
              style: TextStyle(
                color: context.colorScheme.primary,
                decoration: TextDecoration.underline,
                decorationColor: context.colorScheme.primary,
              ),
            ),
            TextSpan(text: currentAppLocalizations.createProfile),
          ],
        ),
      );
      if (res != true) return;
      ref.read(profilesActionProvider.notifier).addProfileFormURL(url);
    });
  }

  void _autoUpdateProfilesTask() {
    _autoUpdateProfilesTaskTimer = Timer(const Duration(minutes: 20), () async {
      await ref.read(profilesActionProvider.notifier).autoUpdateProfiles();
      _autoUpdateProfilesTask();
    });
  }

  Widget _buildPlatformState({required Widget child}) {
    if (system.isDesktop) {
      return WindowManager(
        child: TrayManager(
          child: HotKeyManager(child: ProxyManager(child: child)),
        ),
      );
    }
    return AndroidManager(child: TileManager(child: child));
  }

  Widget _buildState({required Widget child}) {
    return AppStateManager(
      child: CoreManager(
        child: ConnectivityManager(
          onConnectivityChanged: (results) async {
            commonPrint.log('connectivityChanged ${results.toString()}');
            ref.read(systemActionProvider.notifier).updateLocalIp();
            final hasVpn = results.contains(ConnectivityResult.vpn);
            if (_preHasVpn == hasVpn) {
              ref.read(checkIpNumProvider.notifier).add();
            }
            _preHasVpn = hasVpn;
          },
          child: child,
        ),
      ),
    );
  }

  Widget _buildPlatformApp({required Widget child}) {
    if (system.isDesktop) {
      return WindowHeaderContainer(child: child);
    }
    return VpnManager(child: child);
  }

  Widget _buildApp({required Widget child}) {
    return StatusManager(child: ThemeManager(child: child));
  }

  @override
  Widget build(context) {
    return Consumer(
      builder: (_, ref, child) {
        final locale = ref.watch(
          appSettingProvider.select((state) => state.locale),
        );
        final themeProps = ref.watch(themeSettingProvider);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: globalState.navigatorKey,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          builder: (_, child) {
            return AppEnvManager(
              child: _buildApp(
                child: _buildPlatformState(
                  child: _buildState(child: _buildPlatformApp(child: child!)),
                ),
              ),
            );
          },
          scrollBehavior: BaseScrollBehavior(),
          title: appName,
          locale: utils.getLocaleForString(locale),
          supportedLocales: AppLocalizations.delegate.supportedLocales,
          themeMode: themeProps.themeMode,
          theme: _buildThemeData(
            _getAppColorScheme(
              brightness: Brightness.light,
              primaryColor: themeProps.primaryColor,
            ),
          ),
          darkTheme: _buildThemeData(
            _getAppColorScheme(
              brightness: Brightness.dark,
              primaryColor: themeProps.primaryColor,
            ).toPureBlack(themeProps.pureBlack),
          ),
          home: child!,
        );
      },
      child: const HomePage(),
    );
  }

  @override
  Future<void> dispose() async {
    linkManager.destroy();
    _autoUpdateProfilesTaskTimer?.cancel();
    await coreController.destroy();
    await ref.read(systemActionProvider.notifier).handleExit();
    super.dispose();
  }
}
