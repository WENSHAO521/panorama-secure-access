import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'invite_access.dart';

/// Shows [child] once this install is admitted, the code entry until then.
class InviteGate extends ConsumerWidget {
  const InviteGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final granted = ref.watch(inviteProvider.select((state) => state.granted));
    return granted ? child : const InviteView();
  }
}

String inviteRefusalText(BuildContext context, InviteRefusal refusal) {
  final localizations = context.appLocalizations;
  return switch (refusal) {
    InviteRefusal.invalid => localizations.inviteInvalid,
    InviteRefusal.revoked => localizations.inviteRevoked,
    InviteRefusal.expired => localizations.inviteExpired,
    InviteRefusal.exhausted => localizations.inviteExhausted,
    InviteRefusal.unbound => localizations.inviteUnbound,
    InviteRefusal.network => localizations.inviteNetworkError,
  };
}

class InviteView extends ConsumerStatefulWidget {
  const InviteView({super.key});

  @override
  ConsumerState<InviteView> createState() => _InviteViewState();
}

class _InviteViewState extends ConsumerState<InviteView> {
  static const _maxWidth = 420.0;

  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _controller.text.trim();
    if (code.isEmpty) return;
    ref.read(inviteProvider.notifier).redeem(code);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inviteProvider);
    final localizations = context.appLocalizations;
    final colorScheme = context.colorScheme;
    final secondary = AppTextStyle.subheadline
        .of(context)
        .copyWith(color: colorScheme.onSurfaceVariant, height: 1.5);
    final refusal = state.refusal;
    return Surface(
      color: colorScheme.surface,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxWidth),
              child: StarFramed(
                radius: AppRadius.xl,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: context.raisedSurfaceLevel.colorOf(colorScheme),
                    shape: AppShape.xl,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GlyphIcon(
                          AppGlyphs.key,
                          size: 36,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          localizations.inviteTitle,
                          textAlign: TextAlign.center,
                          style: AppTextStyle.title2.of(
                            context,
                            emphasized: true,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          localizations.inviteDescription,
                          textAlign: TextAlign.center,
                          style: secondary,
                        ),
                        const SizedBox(height: 24),
                        FilledInputTheme(
                          borderRadius: AppRadius.lg,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: TextField(
                            controller: _controller,
                            enabled: !state.busy,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.characters,
                            textAlign: TextAlign.center,
                            textInputAction: TextInputAction.done,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp('[A-Za-z0-9-]'),
                              ),
                              LengthLimitingTextInputFormatter(32),
                            ],
                            style: AppTextStyle.title3.of(context).toTabular,
                            onSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              hintText: 'XXXX-XXXX',
                              errorText: refusal == null
                                  ? null
                                  : inviteRefusalText(context, refusal),
                              errorMaxLines: 3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: state.busy ? null : _submit,
                          child: state.busy
                              ? const ActivityIndicator(size: 18)
                              : Text(localizations.inviteSubmit),
                        ),
                        const SizedBox(height: 20),
                        _DeviceLine(device: state.device),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The install's id, for the person handing out codes to unbind it.
class _DeviceLine extends StatelessWidget {
  const _DeviceLine({required this.device});

  final String device;

  @override
  Widget build(BuildContext context) {
    final localizations = context.appLocalizations;
    final style = AppTextStyle.caption1
        .of(context)
        .copyWith(color: context.colorScheme.onSurfaceVariant);
    return PressRegion(
      shape: AppShape.xs,
      onTap: () {
        Clipboard.setData(ClipboardData(text: device));
        dialogs.showBanner(localizations.copySuccess);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 6,
          children: [
            Flexible(
              child: Text(
                '${localizations.inviteDevice} $device',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style.toTabular,
              ),
            ),
            GlyphIcon(
              AppGlyphs.copy,
              size: 14,
              color: context.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
