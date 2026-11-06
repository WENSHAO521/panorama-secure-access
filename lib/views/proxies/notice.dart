import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prism_ui/prism_ui.dart';

/// Why the group sends traffic somewhere its user likely did not mean, or
/// null when it does not.
String? groupNoticeOf(BuildContext context, WidgetRef ref, String groupName) {
  final group = ref.watch(
    groupsProvider.select((state) => state.getGroup(groupName)),
  );
  if (group == null) {
    return null;
  }
  if (group.isEmptyFiltered) {
    return context.appLocalizations.groupEmptyFallbackTip(group.emptyFallback!);
  }
  if (groupName != GroupName.GLOBAL.name) {
    return null;
  }
  final isGlobal = ref.watch(
    patchClashConfigProvider.select((state) => state.mode == Mode.global),
  );
  final selected = ref.watch(selectedProxyNameProvider(groupName));
  if (isGlobal && selected == RuleTarget.DIRECT.value) {
    return context.appLocalizations.globalDirectTip;
  }
  return null;
}

class GroupNoticeText extends StatelessWidget {
  const GroupNoticeText(
    this.notice, {
    super.key,
    this.style = AppTextStyle.caption1,
    this.maxLines = 1,
  });

  final String notice;
  final AppTextStyle style;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(
      notice,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: style
          .of(context, emphasized: true)
          .copyWith(color: context.colorScheme.warning),
    );
  }
}
