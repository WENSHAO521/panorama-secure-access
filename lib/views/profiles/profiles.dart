import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/design/colors/panorama_colors.dart';
import 'package:fl_clash/design/icons/panorama_icons.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/profiles/overwrite/overwrite.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'add.dart';
import 'edit.dart';
import 'preview.dart';
import 'profile_summary.dart';

class ProfilesView extends StatefulWidget {
  const ProfilesView({super.key});

  @override
  State<ProfilesView> createState() => _ProfilesViewState();
}

class _ProfilesViewState extends State<ProfilesView> {
  Function? applyConfigDebounce;
  bool _isUpdating = false;

  // final GlobalKey _targetKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   final context = _targetKey.currentContext;
    //   if (context == null) {
    //     return;
    //   }
    //   Scrollable.ensureVisible(
    //     context,
    //     duration: commonDuration,
    //     alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    //   );
    // });
  }

  void _handleShowAddExtendPage() {
    showExtend(
      globalState.navigatorKey.currentState!.context,
      builder: (_) {
        return AdaptiveSheetScaffold(
          body: AddProfileView(
            context: globalState.navigatorKey.currentState!.context,
          ),
          title: context.appLocalizations.addProfile,
        );
      },
    );
  }

  Future<void> _updateProfiles(List<Profile> profiles) async {
    if (_isUpdating == true) {
      return;
    }
    _isUpdating = true;
    final List<UpdatingMessage> messages = [];
    final updateProfiles = profiles.map<Future>((profile) async {
      if (profile.type == ProfileType.file) return;
      try {
        await globalState.container
            .read(profilesActionProvider.notifier)
            .updateProfile(profile, showLoading: true);
      } catch (e) {
        messages.add(
          UpdatingMessage(label: profile.realLabel, message: e.toString()),
        );
      }
    });
    await Future.wait(updateProfiles);
    if (messages.isNotEmpty) {
      globalState.showAllUpdatingMessagesDialog(messages);
    }
    _isUpdating = false;
  }

  List<Widget> _buildActions(List<Profile> profiles) {
    return profiles.isNotEmpty
        ? [
            IconButton(
              onPressed: () {
                _updateProfiles(profiles);
              },
              icon: Icon(PanoramaIcons.actions.sync),
            ),
            IconButton(
              onPressed: () {
                showSheet(
                  context: context,
                  builder: (_) {
                    return ReorderableProfilesSheet(profiles: profiles);
                  },
                );
              },
              icon: Icon(PanoramaIcons.actions.sort),
              iconSize: 26,
            ),
          ]
        : [];
  }

  Widget _buildFAB() {
    return CommonFloatingActionButton(
      onPressed: _handleShowAddExtendPage,
      icon: Icon(PanoramaIcons.actions.add),
      label: context.appLocalizations.addProfile,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (_, ref, _) {
        final appLocalizations = context.appLocalizations;
        final isLoading = ref.watch(loadingProvider(LoadingTag.profiles));
        final state = ref.watch(profilesStateProvider);
        final spacing = 14.mAp;
        return CommonScaffold(
          isLoading: isLoading,
          title: appLocalizations.profiles,
          floatingActionButton: _buildFAB(),
          actions: _buildActions(state.profiles),
          body: state.profiles.isEmpty
              ? NullStatus(
                  label: appLocalizations.nullProfileDesc,
                  illustration: const ProfileEmptyIllustration(),
                )
              : Align(
                  alignment: Alignment.topCenter,
                  child: SingleChildScrollView(
                    key: profilesStoreKey,
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: 88,
                    ),
                    child: Grid(
                      mainAxisSpacing: spacing,
                      crossAxisSpacing: spacing,
                      crossAxisCount: state.columns,
                      children: [
                        for (int i = 0; i < state.profiles.length; i++)
                          GridItem(
                            child: ProfileItem(
                              profile: state.profiles[i],
                              groupValue: state.currentProfileId,
                              onChanged: (profileId) {
                                ref
                                        .read(currentProfileIdProvider.notifier)
                                        .value =
                                    profileId;
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class ProfileItem extends StatelessWidget {
  final Profile profile;
  final int? groupValue;
  final void Function(int? value) onChanged;

  const ProfileItem({
    super.key,
    required this.profile,
    required this.groupValue,
    required this.onChanged,
  });

  Future<void> _handleDeleteProfile(BuildContext context) async {
    final appLocalizations = context.appLocalizations;
    final res = await globalState.showMessage(
      title: appLocalizations.tip,
      message: TextSpan(
        text: appLocalizations.deleteTip(appLocalizations.profile),
      ),
    );
    if (res != true) {
      return;
    }
    await globalState.container
        .read(profilesActionProvider.notifier)
        .deleteProfile(profile.id);
  }

  Future<void> _handlePreview(BuildContext context) async {
    BaseNavigator.push<String>(context, PreviewProfileView(profile: profile));
  }

  Future updateProfile() async {
    if (profile.type == ProfileType.file) return;
    await globalState.loadingRun(() async {
      await globalState.container
          .read(profilesActionProvider.notifier)
          .updateProfile(profile, showLoading: true);
    }, tag: LoadingTag.profiles);
  }

  void _handleShowEditExtendPage(BuildContext context) {
    showExtend(
      context,
      builder: (_) {
        return AdaptiveSheetScaffold(
          body: EditProfileView(profile: profile, context: context),
          title: context.appLocalizations.edit,
        );
      },
    );
  }

  Future<void> _handleCopyLink(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: profile.url));
    if (context.mounted) {
      context.showNotifier(context.appLocalizations.copySuccess);
    }
  }

  Future<void> _handleExportFile(BuildContext context) async {
    final appLocalizations = context.appLocalizations;
    final res = await globalState.safeRun<bool>(() async {
      final mFile = await profile.file;
      final value = await picker.saveFile(
        profile.realLabel,
        mFile.readAsBytesSync(),
      );
      if (value == null) return false;
      return true;
    }, title: appLocalizations.tip);
    if (res == true && context.mounted) {
      context.showNotifier(appLocalizations.exportSuccess);
    }
  }

  void _handlePushGenProfilePage(BuildContext context, int id) {
    BaseNavigator.push(context, OverwriteView(profileId: id));
  }

  Future<void> _handleDuplicate(BuildContext context) async {
    await globalState.safeRun(() async {
      await globalState.container
          .read(profilesActionProvider.notifier)
          .duplicateProfile(profile);
    }, title: context.appLocalizations.tip);
  }

  /// Brief §74: Update, Edit, Duplicate, Export, Delete; the rest under
  /// More. The same menu opens from the ⋯ button, a right click, or a long
  /// press on the card.
  List<PopupMenuItemData> _menuItems(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final isUrl = profile.type == ProfileType.url;
    return [
      if (isUrl)
        PopupMenuItemData(
          icon: PanoramaIcons.actions.sync,
          label: appLocalizations.update,
          onPressed: updateProfile,
        ),
      PopupMenuItemData(
        icon: PanoramaIcons.actions.edit,
        label: appLocalizations.edit,
        onPressed: () => _handleShowEditExtendPage(context),
      ),
      PopupMenuItemData(
        icon: PanoramaIcons.actions.duplicate,
        label: appLocalizations.duplicate,
        onPressed: () => _handleDuplicate(context),
      ),
      PopupMenuItemData(
        icon: PanoramaIcons.actions.exportFile,
        label: appLocalizations.exportFile,
        onPressed: () => _handleExportFile(context),
      ),
      PopupMenuItemData(
        icon: PanoramaIcons.actions.moreActions,
        label: appLocalizations.more,
        subItems: [
          PopupMenuItemData(
            icon: PanoramaIcons.actions.view,
            label: appLocalizations.preview,
            onPressed: () => _handlePreview(context),
          ),
          PopupMenuItemData(
            icon: PanoramaIcons.routing.override,
            label: appLocalizations.override,
            onPressed: () => _handlePushGenProfilePage(context, profile.id),
          ),
          if (isUrl)
            PopupMenuItemData(
              icon: PanoramaIcons.actions.copy,
              label: appLocalizations.copyLink,
              onPressed: () => _handleCopyLink(context),
            ),
        ],
      ),
      PopupMenuItemData(
        danger: true,
        icon: PanoramaIcons.actions.delete,
        label: appLocalizations.delete,
        onPressed: () => _handleDeleteProfile(context),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final isUpdating = ref.watch(isUpdatingProvider(profile.updatingKey));
        final summary = ProfileSummary.of(
          profile,
          isCurrent: profile.id == groupValue,
          isUpdating: isUpdating,
        );
        final popup = CommonPopupMenu(items: _menuItems(context));
        return LayoutBuilder(
          builder: (context, constraints) => CommonPopupBox(
            popup: popup,
            targetBuilder: (openMenu) => GestureDetector(
              // Right click only; the card itself is the screen-reader target.
              excludeFromSemantics: true,
              onSecondaryTapUp: (details) {
                openMenu(offset: details.localPosition);
              },
              child: CommonCard(
                key: Key(profile.id.toString()),
                isSelected: profile.id == groupValue,
                semanticLabel: profile.realLabel,
                onPressed: () => onChanged(profile.id),
                onLongPress: () {
                  openMenu(offset: Offset(constraints.maxWidth, 0));
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 0, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _ProfileDetails(
                          profile: profile,
                          summary: summary,
                        ),
                      ),
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: FadeThroughBox(
                          child: isUpdating
                              ? const Padding(
                                  key: ValueKey('loading'),
                                  padding: EdgeInsets.all(14),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : CommonPopupBox(
                                  key: const ValueKey('menu'),
                                  popup: popup,
                                  targetBuilder: (open) => IconButton(
                                    tooltip: context.appLocalizations.more,
                                    onPressed: () => open(),
                                    icon: Icon(PanoramaIcons.actions.more),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Name and state, then source and last update, then traffic and expiry
/// (brief §74).
class _ProfileDetails extends StatelessWidget {
  final Profile profile;
  final ProfileSummary summary;

  const _ProfileDetails({required this.profile, required this.summary});

  String _stateLabel(AppLocalizations l, ProfileState state) => switch (state) {
    ProfileState.inUse => l.profileInUse,
    ProfileState.updating => l.profileUpdating,
    ProfileState.expired => l.profileExpired,
    ProfileState.dataUsedUp => l.profileDataUsedUp,
  };

  @override
  Widget build(BuildContext context) {
    final l = context.appLocalizations;
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final secondary = textTheme.bodySmall?.copyWith(
      color: colorScheme.labelSecondary,
    );
    final source = summary.isLocal
        ? l.localFile
        : (summary.sourceHost ?? l.url);
    final usage = summary.usage;
    final quota = [
      if (summary.totalBytes != null)
        '${summary.usedBytes!.traffic.show} / '
            '${summary.totalBytes!.traffic.show}',
      if (summary.expiresAt != null)
        l.expiresOn(summary.expiresAt!.show)
      else if (summary.hasNoExpiry)
        l.noExpiry,
    ].join('  ·  ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                profile.realLabel,
                style: textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              for (final state in summary.states)
                _StateBadge(label: _stateLabel(l, state), state: state),
            ],
          ),
        ),
        const SizedBox(height: 4),
        TickBuilder(
          duration: const Duration(minutes: 1),
          builder: (context, _) {
            final updated = profile.lastUpdateDate;
            return Text(
              [
                source,
                if (updated != null)
                  l.updatedAgo(updated.getLastUpdateTimeDesc(context)),
              ].join('  ·  '),
              style: secondary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          },
        ),
        if (usage != null) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              minHeight: 4,
              value: usage,
              color: summary.states.contains(ProfileState.dataUsedUp)
                  ? colorScheme.danger
                  : null,
              backgroundColor: colorScheme.primary.opacity15,
            ),
          ),
        ],
        if (quota.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            quota,
            style: secondary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

class _StateBadge extends StatelessWidget {
  final String label;
  final ProfileState state;

  const _StateBadge({required this.label, required this.state});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final (background, foreground) = switch (state) {
      ProfileState.inUse => (
        colorScheme.primaryContainer,
        colorScheme.onPrimaryContainer,
      ),
      ProfileState.updating => (
        colorScheme.surfaceContainerHighest,
        colorScheme.onSurfaceVariant,
      ),
      ProfileState.expired || ProfileState.dataUsedUp => (
        colorScheme.errorContainer,
        colorScheme.onErrorContainer,
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(color: foreground),
        ),
      ),
    );
  }
}

class ReorderableProfilesSheet extends StatefulWidget {
  final List<Profile> profiles;

  const ReorderableProfilesSheet({super.key, required this.profiles});

  @override
  State<ReorderableProfilesSheet> createState() =>
      _ReorderableProfilesSheetState();
}

class _ReorderableProfilesSheetState extends State<ReorderableProfilesSheet> {
  late List<Profile> profiles;

  @override
  void initState() {
    super.initState();
    profiles = List.from(widget.profiles);
  }

  Widget _buildItem(int index) {
    final position = ItemPosition.get(index, profiles.length);
    final profile = profiles[index];
    return ItemPositionProvider(
      key: Key(profile.id.toString()),
      position: position,
      child: DecorationListItem(
        trailing: ReorderableDelayedDragStartListener(
          index: index,
          child: Icon(PanoramaIcons.actions.dragHandle),
        ),
        title: Text(profile.realLabel),
      ),
    );
  }

  void _handleSave() {
    Navigator.of(context).pop();
    globalState.container.read(profilesProvider.notifier).reorder(profiles);
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return AdaptiveSheetScaffold(
      sheetTransparentToolBar: true,
      actions: [
        IconButtonData(
          icon: PanoramaIcons.actions.confirm,
          onPressed: _handleSave,
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.only(bottom: 32),
        child: ReorderableListView.builder(
          buildDefaultDragHandles: false,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ).copyWith(top: context.sheetTopPadding),
          proxyDecorator: (child, index, animation) {
            return commonProxyDecorator(_buildItem(index), index, animation);
          },
          onReorderItem: (oldIndex, newIndex) {
            setState(() {
              profiles = profiles.copyAndReorder(oldIndex, newIndex);
            });
          },
          itemBuilder: (_, index) {
            return _buildItem(index);
          },
          itemCount: profiles.length,
        ),
      ),
      title: appLocalizations.profilesSort,
    );
  }
}
