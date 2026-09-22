import 'package:flutter/foundation.dart';

enum ServiceCategory { ai, streaming, social, regional, connectivity }

/// Every state a service check can be in. UI code maps these to text and
/// icons; it never shows raw upstream strings.
enum ServiceCheckStatus {
  pending,
  checking,

  available,

  /// Reachable but with reduced content, e.g. Netflix originals only or a
  /// launch that hasn't happened yet in this region.
  limited,

  /// Available, but the content catalogue is specific to this region.
  regional,

  blocked,
  unsupportedRegion,
  ipRestricted,

  timeout,
  networkError,
  parseError,

  unknown;

  bool get isDone => this != pending && this != checking;

  bool get isUsable => this == available || this == limited || this == regional;

  bool get isFailure =>
      this == timeout ||
      this == networkError ||
      this == parseError ||
      this == unknown;
}

enum ServiceCheckErrorType { timeout, network, tls, parse, cancelled }

@immutable
class ServiceCheckResult {
  final String serviceId;
  final String serviceName;
  final ServiceCategory category;
  final ServiceCheckStatus status;

  /// ISO 3166-1 alpha-2, upper case, when the service reported one.
  final String? regionCode;

  /// Short technical detail, e.g. "Originals only" or an HTTP status.
  final String? message;
  final DateTime? checkedAt;
  final Duration? latency;
  final ServiceCheckErrorType? errorType;

  const ServiceCheckResult({
    required this.serviceId,
    required this.serviceName,
    required this.category,
    required this.status,
    this.regionCode,
    this.message,
    this.checkedAt,
    this.latency,
    this.errorType,
  });

  ServiceCheckResult copyWith({
    ServiceCheckStatus? status,
    String? regionCode,
    String? message,
    DateTime? checkedAt,
    Duration? latency,
    ServiceCheckErrorType? errorType,
  }) {
    return ServiceCheckResult(
      serviceId: serviceId,
      serviceName: serviceName,
      category: category,
      status: status ?? this.status,
      regionCode: regionCode ?? this.regionCode,
      message: message ?? this.message,
      checkedAt: checkedAt ?? this.checkedAt,
      latency: latency ?? this.latency,
      errorType: errorType ?? this.errorType,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ServiceCheckResult &&
        other.serviceId == serviceId &&
        other.serviceName == serviceName &&
        other.category == category &&
        other.status == status &&
        other.regionCode == regionCode &&
        other.message == message &&
        other.checkedAt == checkedAt &&
        other.latency == latency &&
        other.errorType == errorType;
  }

  @override
  int get hashCode => Object.hash(
    serviceId,
    serviceName,
    category,
    status,
    regionCode,
    message,
    checkedAt,
    latency,
    errorType,
  );

  @override
  String toString() =>
      'ServiceCheckResult($serviceId, $status, $regionCode, $message)';
}

/// What a single checker decided, before the runner stamps time/latency.
@immutable
class ServiceCheckOutcome {
  final ServiceCheckStatus status;
  final String? regionCode;
  final String? message;
  final ServiceCheckErrorType? errorType;

  const ServiceCheckOutcome(
    this.status, {
    this.regionCode,
    this.message,
    this.errorType,
  });

  const ServiceCheckOutcome.networkError([this.message])
    : status = ServiceCheckStatus.networkError,
      regionCode = null,
      errorType = ServiceCheckErrorType.network;

  const ServiceCheckOutcome.parseError([this.message])
    : status = ServiceCheckStatus.parseError,
      regionCode = null,
      errorType = ServiceCheckErrorType.parse;
}
