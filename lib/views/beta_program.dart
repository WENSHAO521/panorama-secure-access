import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/ui/ui.dart';
import 'package:fl_clash/views/about.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BetaProgramView extends ConsumerWidget {
  const BetaProgramView({super.key});

  static const _badgeSize = 72.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final colorScheme = context.colorScheme;
    final isLoading = ref.watch(loadingProvider(LoadingTag.checkUpdate));
    final joined = ref.watch(
      appSettingProvider.select((state) => state.betaUpdates),
    );
    final isBetaBuild = globalState.appVersion.contains('-');
    return CommonScaffold(
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
                onChanged: (value) => ref
                    .read(appSettingProvider.notifier)
                    .update((state) => state.copyWith(betaUpdates: value)),
              ),
            ],
            footer: appLocalizations.betaProgramFooter,
          ),
          generateSection(
            items: [
              ListItem(
                title: Text(appLocalizations.currentVersion),
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
                onTap: isLoading ? null : () => checkUpdateByUser(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
