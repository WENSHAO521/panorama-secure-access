import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';

/// [none] keeps the total the subscription reports.
enum QuotaUnit {
  none(0),
  mb(1 << 20),
  gb(1 << 30),
  tb(1 << 40);

  const QuotaUnit(this.bytes);

  final int bytes;

  String get symbol => switch (this) {
    none => '',
    mb => 'MB',
    gb => 'GB',
    tb => 'TB',
  };

  static QuotaUnit of(int bytes) =>
      [mb, gb, tb].lastWhere((unit) => bytes >= unit.bytes, orElse: () => mb);

  String format(int bytes) => this == none
      ? ''
      : (bytes / this.bytes)
            .toStringAsFixed(3)
            .replaceFirst(RegExp(r'\.?0+$'), '');
}

enum TrafficQuotaInputError { invalid, tooLarge }

/// 1024 TB: far above any plan, and well inside a double's exact integers.
const maxTrafficQuotaBytes = 1 << 50;

final _amountPattern = RegExp(r'^\d{1,10}(\.\d{1,3})?$');

class TrafficQuotaInput {
  final int? bytes;
  final TrafficQuotaInputError? error;

  const TrafficQuotaInput._({this.bytes, this.error});

  /// The pattern turns away signs, exponents, `NaN` and `Infinity` unparsed.
  factory TrafficQuotaInput.parse(String text, QuotaUnit unit) {
    final trimmed = text.trim();
    if (unit == QuotaUnit.none || trimmed.isEmpty) {
      return const TrafficQuotaInput._();
    }
    if (!_amountPattern.hasMatch(trimmed)) {
      return const TrafficQuotaInput._(error: TrafficQuotaInputError.invalid);
    }
    final amount = double.parse(trimmed);
    final bytes = (amount * unit.bytes).round();
    if (bytes <= 0) {
      return const TrafficQuotaInput._(error: TrafficQuotaInputError.invalid);
    }
    if (bytes > maxTrafficQuotaBytes) {
      return const TrafficQuotaInput._(error: TrafficQuotaInputError.tooLarge);
    }
    return TrafficQuotaInput._(bytes: bytes);
  }

  bool get isValid => error == null;

  TrafficQuota? quota(TrafficQuotaPeriod period) =>
      bytes == null ? null : TrafficQuota(total: bytes!, period: period);
}
