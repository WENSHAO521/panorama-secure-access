// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../connection.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The state the user asked for and the core hasn't reached yet; null when
/// nothing is pending. Every entry point (Home, tray, tile, hotkey) goes
/// through [request], so all of them show the same pending state.

@ProviderFor(ConnectionRequest)
final connectionRequestProvider = ConnectionRequestProvider._();

/// The state the user asked for and the core hasn't reached yet; null when
/// nothing is pending. Every entry point (Home, tray, tile, hotkey) goes
/// through [request], so all of them show the same pending state.
final class ConnectionRequestProvider
    extends $NotifierProvider<ConnectionRequest, bool?> {
  /// The state the user asked for and the core hasn't reached yet; null when
  /// nothing is pending. Every entry point (Home, tray, tile, hotkey) goes
  /// through [request], so all of them show the same pending state.
  ConnectionRequestProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'connectionRequestProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$connectionRequestHash();

  @$internal
  @override
  ConnectionRequest create() => ConnectionRequest();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool?>(value),
    );
  }
}

String _$connectionRequestHash() => r'18c6e7bdfb97e4aceb36fcf22a832c69edc9b6d1';

/// The state the user asked for and the core hasn't reached yet; null when
/// nothing is pending. Every entry point (Home, tray, tile, hotkey) goes
/// through [request], so all of them show the same pending state.

abstract class _$ConnectionRequest extends $Notifier<bool?> {
  bool? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool?, bool?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool?, bool?>,
              bool?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(connectionPhase)
final connectionPhaseProvider = ConnectionPhaseProvider._();

final class ConnectionPhaseProvider
    extends
        $FunctionalProvider<ConnectionPhase, ConnectionPhase, ConnectionPhase>
    with $Provider<ConnectionPhase> {
  ConnectionPhaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'connectionPhaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$connectionPhaseHash();

  @$internal
  @override
  $ProviderElement<ConnectionPhase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ConnectionPhase create(Ref ref) {
    return connectionPhase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConnectionPhase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConnectionPhase>(value),
    );
  }
}

String _$connectionPhaseHash() => r'216673109258985807f3c8b064c7346cd82656e9';

/// The node traffic actually leaves through for the main group: GLOBAL in
/// global mode, the first visible group in rule mode, following nested
/// groups down to a leaf. Null in direct mode or before groups load. Shared
/// by Home and the tray (§84).

@ProviderFor(currentRoute)
final currentRouteProvider = CurrentRouteProvider._();

/// The node traffic actually leaves through for the main group: GLOBAL in
/// global mode, the first visible group in rule mode, following nested
/// groups down to a leaf. Null in direct mode or before groups load. Shared
/// by Home and the tray (§84).

final class CurrentRouteProvider
    extends
        $FunctionalProvider<
          ({String group, String node, String? testUrl})?,
          ({String group, String node, String? testUrl})?,
          ({String group, String node, String? testUrl})?
        >
    with $Provider<({String group, String node, String? testUrl})?> {
  /// The node traffic actually leaves through for the main group: GLOBAL in
  /// global mode, the first visible group in rule mode, following nested
  /// groups down to a leaf. Null in direct mode or before groups load. Shared
  /// by Home and the tray (§84).
  CurrentRouteProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentRouteProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentRouteHash();

  @$internal
  @override
  $ProviderElement<({String group, String node, String? testUrl})?>
  $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  ({String group, String node, String? testUrl})? create(Ref ref) {
    return currentRoute(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    ({String group, String node, String? testUrl})? value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<({String group, String node, String? testUrl})?>(
            value,
          ),
    );
  }
}

String _$currentRouteHash() => r'f5133c3de2a2861c531f325ab32070daf98b4eaf';
