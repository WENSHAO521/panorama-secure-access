// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../network_insight.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(networkInsightSources)
final networkInsightSourcesProvider = NetworkInsightSourcesProvider._();

final class NetworkInsightSourcesProvider
    extends
        $FunctionalProvider<
          NetworkInsightSources,
          NetworkInsightSources,
          NetworkInsightSources
        >
    with $Provider<NetworkInsightSources> {
  NetworkInsightSourcesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'networkInsightSourcesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$networkInsightSourcesHash();

  @$internal
  @override
  $ProviderElement<NetworkInsightSources> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NetworkInsightSources create(Ref ref) {
    return networkInsightSources(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NetworkInsightSources value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NetworkInsightSources>(value),
    );
  }
}

String _$networkInsightSourcesHash() =>
    r'45eedf9e3e8cfddaa0b12d4fb841d7e5b1dcd301';

/// The route service results belong to: profile, outbound mode and every
/// group selection. Any change means cached results no longer apply.

@ProviderFor(serviceRouteKey)
final serviceRouteKeyProvider = ServiceRouteKeyProvider._();

/// The route service results belong to: profile, outbound mode and every
/// group selection. Any change means cached results no longer apply.

final class ServiceRouteKeyProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// The route service results belong to: profile, outbound mode and every
  /// group selection. Any change means cached results no longer apply.
  ServiceRouteKeyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serviceRouteKeyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serviceRouteKeyHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return serviceRouteKey(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$serviceRouteKeyHash() => r'1da70226bb04cbae5d6b014f78d953f5569d68df';

@ProviderFor(NetworkInsightIdentity)
final networkInsightIdentityProvider = NetworkInsightIdentityProvider._();

final class NetworkInsightIdentityProvider
    extends $NotifierProvider<NetworkInsightIdentity, NetworkIdentityState> {
  NetworkInsightIdentityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'networkInsightIdentityProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$networkInsightIdentityHash();

  @$internal
  @override
  NetworkInsightIdentity create() => NetworkInsightIdentity();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NetworkIdentityState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NetworkIdentityState>(value),
    );
  }
}

String _$networkInsightIdentityHash() =>
    r'a95865456b547307821bda3853b2e8113eab08cd';

abstract class _$NetworkInsightIdentity
    extends $Notifier<NetworkIdentityState> {
  NetworkIdentityState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<NetworkIdentityState, NetworkIdentityState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NetworkIdentityState, NetworkIdentityState>,
              NetworkIdentityState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(ServiceAvailability)
final serviceAvailabilityProvider = ServiceAvailabilityProvider._();

final class ServiceAvailabilityProvider
    extends $NotifierProvider<ServiceAvailability, ServiceAvailabilityState> {
  ServiceAvailabilityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serviceAvailabilityProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serviceAvailabilityHash();

  @$internal
  @override
  ServiceAvailability create() => ServiceAvailability();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ServiceAvailabilityState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ServiceAvailabilityState>(value),
    );
  }
}

String _$serviceAvailabilityHash() =>
    r'ea58cc061c0129228040a70e343d1289639c4b2f';

abstract class _$ServiceAvailability
    extends $Notifier<ServiceAvailabilityState> {
  ServiceAvailabilityState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<ServiceAvailabilityState, ServiceAvailabilityState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ServiceAvailabilityState, ServiceAvailabilityState>,
              ServiceAvailabilityState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
