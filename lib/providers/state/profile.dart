part of '../state.dart';

@riverpod
ProfilesState profilesState(Ref ref) {
  final currentProfileId = ref.watch(currentProfileIdProvider);
  final profiles = ref.watch(profilesProvider);
  return ProfilesState(profiles: profiles, currentProfileId: currentProfileId);
}

@riverpod
Profile? currentProfile(Ref ref) {
  final profileId = ref.watch(currentProfileIdProvider);
  return ref.watch(
    profilesProvider.select((state) => state.getProfile(profileId)),
  );
}

@riverpod
Profile? profile(Ref ref, int? profileId) {
  return ref.watch(
    profilesProvider.select((state) => state.getProfile(profileId)),
  );
}

@riverpod
Future<ClashConfig> clashConfig(Ref ref, int profileId) async {
  final type = ref.read(profileProvider(profileId))?.type;
  if (type == ProfileType.custom) {
    return const ClashConfig();
  }
  final outbounds = await ref
      .read(coreHandlerProvider)
      .getProfileOutbounds(profileId);
  return clashConfigTask(outbounds);
}

@riverpod
Future<SetupState> setupState(Ref ref, int? profileId) async {
  final profile = ref.watch(profileProvider(profileId));
  final scriptId = profile?.scriptId;
  final profileLastUpdateDate = profile?.lastUpdateDate?.millisecondsSinceEpoch;
  final profileType = profile?.type ?? ProfileType.file;
  final overrides = profileType == ProfileType.custom
      ? ref.watch(
          patchClashConfigProvider.select(
            (state) => (profile?.overrides ?? const ProfileOverrides())
                .overAppTun(state.tunOverride, state.tunOverrideKeys),
          ),
        )
      : ref.watch(
          patchClashConfigProvider.select(
            (state) => ProfileOverrides(
              dns: state.dns,
              dnsOverrideKeys: state.dnsOverrideKeys.intersection(
                DnsOverrideKey.normalProfileKeys,
              ),
              tun: state.tunOverride,
              tunOverrideKeys: state.tunOverrideKeys,
            ),
          ),
        );
  final allProfileProviders = ref.watch(profileProvidersProvider);
  final mitmModules =
      mitmFeature &&
          ref.watch(
            patchClashConfigProvider.select((state) => state.mitm.enable),
          )
      ? ref.watch(mitmModulesProvider.future)
      : null;
  List<ProxyGroup> proxyGroups = [];
  List<Rule> rules = [];
  List<Rule> addedRules = [];
  List<ClashProvider> clashProviders = [];
  Map<String, int> profileProviders = const {};
  List<CustomProxy> appProxies = [];
  Map<int, String> proxyDialers = const {};
  Script? script;
  if (profileId != null) {
    if (profileType == ProfileType.custom) {
      final custom = await database.readApart(_customSetupReader(profileId));
      rules = custom.rules;
      proxyGroups = custom.proxyGroups;
      clashProviders = custom.clashProviders;
      profileProviders = allProfileProviders;
      appProxies = custom.appProxies;
      proxyDialers = custom.proxyDialers;
    } else {
      final normal = await database.readApart(
        _normalSetupReader(profileId, scriptId),
      );
      addedRules = normal.addedRules;
      script = normal.script;
    }
  }
  return SetupState(
    mitmModules: mitmModules == null
        ? const []
        : await mitmModuleSources(await mitmModules),
    clashProviders: clashProviders,
    profileProviders: profileProviders,
    appProxies: appProxies,
    proxyDialers: proxyDialers,
    rules: rules,
    proxyGroups: proxyGroups,
    profileId: profileId,
    profileLastUpdateDate: profileLastUpdateDate,
    profileType: profileType,
    addedRules: addedRules,
    script: script,
    overrides: overrides,
    matchTarget: profileType != ProfileType.custom
        ? profile?.matchTarget
        : null,
  );
}

/// A module whose content is not on disk yet adds nothing until it downloads.
Future<List<MitmModuleSource>> mitmModuleSources(
  Iterable<MitmModule> modules,
) async {
  final directory = await appPath.mitmModulesDirPath;
  final sources = <MitmModuleSource>[];
  for (final module in modules) {
    if (!module.enabled) {
      continue;
    }
    final file = File(join(directory, module.fileName));
    if (!await file.exists()) {
      continue;
    }
    sources.add(
      MitmModuleSource(
        content: await file.readAsString(),
        arguments: module.arguments,
        resources: module.resources,
      ),
    );
  }
  return sources;
}

typedef _CustomSetupRead = ({
  List<Rule> rules,
  List<ProxyGroup> proxyGroups,
  List<ClashProvider> clashProviders,
  List<CustomProxy> appProxies,
  Map<int, String> proxyDialers,
});

Future<_CustomSetupRead> Function(Database) _customSetupReader(int profileId) =>
    (db) async => (
      rules: await db.rulesDao.queryProfileRules(profileId).get(),
      proxyGroups: await db.proxyGroupsDao.query(profileId).get(),
      clashProviders: await db.clashProvidersDao.query().get(),
      appProxies: await db.customProxiesDao.query().get(),
      proxyDialers: {
        for (final dialer in await db.proxyDialersDao.query(profileId).get())
          dialer.proxyId: dialer.target,
      },
    );

Future<({List<Rule> addedRules, Script? script})> Function(Database)
_normalSetupReader(int profileId, int? scriptId) =>
    (db) async => (
      addedRules: await db.rulesDao.queryAddedRules(profileId).get(),
      script: scriptId == null
          ? null
          : await db.scriptsDao.get(scriptId).getSingleOrNull(),
    );

/// Subscription profiles double as proxy providers for custom profiles.
@riverpod
Map<String, int> profileProviders(Ref ref) {
  final profiles = ref.watch(profilesProvider);
  return {
    for (final profile in profiles)
      if (profile.type != ProfileType.custom) profile.realLabel: profile.id,
  };
}
