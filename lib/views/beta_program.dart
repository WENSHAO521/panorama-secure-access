import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/ui/ui.dart';
import 'package:fl_clash/views/about.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BetaProgramView extends ConsumerStatefulWidget {
  const BetaProgramView({super.key});

  @visibleForTesting
  static Future<bool> Function(Config config) saveConfig =
      preferences.saveConfig;

  @override
  ConsumerState<BetaProgramView> createState() => _BetaProgramViewState();
}

class _BetaProgramViewState extends ConsumerState<BetaProgramView> {
  static const _badgeSize = 72.0;

  bool _switching = false;

  /// The channel changes only after the user confirms and the setting is on
  /// disk; any other ending leaves it where it was.
  Future<void> _requestChange(bool join) async {
    if (_switching) return;
    setState(() => _switching = true);
    try {
      final appLocalizations = context.appLocalizations;
      final confirmed = await dialogs.showMessage(
        title: join
            ? appLocalizations.betaJoinConfirmTitle
            : appLocalizations.betaLeaveConfirmTitle,
        message: TextSpan(
          text: join
              ? appLocalizations.betaJoinConfirmDesc
              : appLocalizations.betaLeaveConfirmDesc,
        ),
        confirmText: join
            ? appLocalizations.betaJoinConfirm
            : appLocalizations.betaLeaveConfirm,
        cancelText: join ? appLocalizations.cancel : appLocalizations.betaStay,
      );
      if (confirmed != true || !mounted) return;
      final config = ref.read(configProvider);
      if (config.appSettingProps.betaUpdates == join) return;
      final next = config.copyWith(
        appSettingProps: config.appSettingProps.copyWith(betaUpdates: join),
      );
      bool saved;
      try {
        saved = await BetaProgramView.saveConfig(next);
      } catch (error) {
        commonPrint.log(
          'beta channel save failed ${compactError(error)}',
          logLevel: LogLevel.warning,
        );
        saved = false;
      }
      if (!mounted) return;
      if (!saved) {
        dialogs.showBanner(
          appLocalizations.betaChannelSaveFailed,
          level: BannerLevel.error,
        );
        return;
      }
      ref
          .read(appSettingProvider.notifier)
          .update((state) => state.copyWith(betaUpdates: join));
      if (!join) {
        ref.read(updateControllerProvider.notifier).dropPreRelease();
      }
    } finally {
      if (mounted) setState(() => _switching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final colorScheme = context.colorScheme;
    final isLoading = ref.watch(loadingProvider(LoadingTag.checkUpdate));
    final joined = ref.watch(
      appSettingProvider.select((state) => state.betaUpdates),
    );
    final isBetaBuild = globalState.appVersion.contains('-');
    return Scaffold(
      isLoading: isLoading,
      title: appLocalizations.betaProgram,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(
          top: context.contentTopPadding,
          bottom: 32 + context.bottomInset,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Column(
              children: [
                DecoratedBox(
                  decoration: ShapeDecoration(
                    color: context.raisedSurfaceLevel.colorOf(colorScheme),
                    shape: AppShape.all(AppCorner.fit(_badgeSize)),
                  ),
                  child: SizedBox.square(
                    dimension: _badgeSize,
                    child: Center(
                      child: GlyphIcon(
                        AppGlyphs.sparkle,
                        size: 36,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  appLocalizations.betaProgram,
                  style: AppTextStyle.title2.of(context, emphasized: true),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Text(
                    appLocalizations.betaProgramDesc,
                    textAlign: TextAlign.center,
                    style: AppTextStyle.subheadline
                        .of(context)
                        .copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                  ),
                ),
              ],
            ),
          ),
          generateSection(
            items: [
              ListItem.toggle(
                title: Text(appLocalizations.betaUpdates),
                subtitle: Text(
                  joined
                      ? appLocalizations.betaJoinedTip
                      : appLocalizations.betaNotJoinedTip,
                ),
                value: joined,
                onChanged: _switching ? null : _requestChange,
              ),
            ],
            footer: appLocalizations.betaProgramFooter,
          ),
          generateSection(
            items: [
              ListItem(
                title: Text(appLocalizations.updateChannel),
                trailing: Text(
                  joined
                      ? appLocalizations.betaChannel
                      : appLocalizations.stableChannel,
                  style: AppTextStyle.subheadline
                      .of(context)
                      .copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ),
              ListItem(
                title: Text(appLocalizations.installedVersion),
                subtitle: Text(
                  isBetaBuild
                      ? appLocalizations.betaChannel
                      : appLocalizations.stableChannel,
                ),
                trailing: Text(
                  'v${globalState.appVersion}',
                  style: AppTextStyle.subheadline
                      .of(context)
                      .copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ),
              ListItem(
                leading: const GlyphIcon(AppGlyphs.sync),
                title: Text(appLocalizations.checkUpdate),
                onTap: isLoading || _switching
                    ? null
                    : () => checkUpdateByUser(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
