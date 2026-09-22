import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';

/// Profile states worth a label on the card (brief §74). Each one is shown
/// as text, never by colour alone (§100).
enum ProfileState { inUse, updating, expired, dataUsedUp }

/// What the profile card shows, derived only from data the app already
/// keeps. No "update failed" state: failures are shown when they happen and
/// are not stored, so the card doesn't claim one.
class ProfileSummary {
  /// Host of the subscription URL; null for a profile from a local file.
  ///
  /// Only the host: subscription URLs usually carry the access token in the
  /// path or query, and the card is often visible in screenshots.
  final String? sourceHost;
  final bool isLocal;
  final int? usedBytes;
  final int? totalBytes;
  final DateTime? expiresAt;

  /// The subscription reports traffic but no expiry.
  final bool hasNoExpiry;
  final List<ProfileState> states;

  const ProfileSummary._({
    required this.sourceHost,
    required this.isLocal,
    required this.usedBytes,
    required this.totalBytes,
    required this.expiresAt,
    required this.hasNoExpiry,
    required this.states,
  });

  factory ProfileSummary.of(
    Profile profile, {
    required bool isCurrent,
    required bool isUpdating,
    DateTime? now,
  }) {
    final isLocal = profile.type == ProfileType.file;
    final host = isLocal ? null : Uri.tryParse(profile.url)?.host;
    final info = isLocal ? null : profile.subscriptionInfo;
    final hasTraffic = info != null && info.total > 0;
    final used = hasTraffic ? info.upload + info.download : null;
    final expiresAt = info != null && info.expire > 0
        ? DateTime.fromMillisecondsSinceEpoch(info.expire * 1000)
        : null;
    final at = now ?? DateTime.now();
    return ProfileSummary._(
      sourceHost: host == null || host.isEmpty ? null : host,
      isLocal: isLocal,
      usedBytes: used,
      totalBytes: hasTraffic ? info.total : null,
      expiresAt: expiresAt,
      hasNoExpiry: hasTraffic && expiresAt == null,
      states: [
        if (isCurrent) ProfileState.inUse,
        if (isUpdating) ProfileState.updating,
        if (expiresAt != null && !expiresAt.isAfter(at)) ProfileState.expired,
        if (used != null && used >= info!.total) ProfileState.dataUsedUp,
      ],
    );
  }

  /// Share of the traffic quota used, 0–1; null without a quota.
  double? get usage {
    if (usedBytes == null || totalBytes == null) return null;
    return (usedBytes! / totalBytes!).clamp(0, 1).toDouble();
  }
}
