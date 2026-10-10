import 'package:fl_clash/common/update.dart';
import 'package:flutter/foundation.dart';

enum UpdateStage { available, downloading, verifying, ready, failed }

@immutable
class UpdateState {
  const UpdateState({
    required this.tag,
    required this.asset,
    this.body,
    this.stage = UpdateStage.available,
    this.received = 0,
    this.total = 0,
    this.speed = 0,
    this.filePath,
    this.cardVisible = true,
  });

  final String tag;
  final UpdateAsset asset;
  final String? body;
  final UpdateStage stage;
  final int received;
  final int total;
  final double speed;
  final String? filePath;
  final bool cardVisible;

  String get version => tag.replaceFirst(RegExp('^v'), '');

  bool get isBusy =>
      stage == UpdateStage.downloading || stage == UpdateStage.verifying;

  double? get progress {
    if (stage == UpdateStage.ready) return 1;
    if (stage == UpdateStage.verifying) return null;
    final size = total > 0 ? total : asset.size;
    if (size <= 0) return stage == UpdateStage.available ? 0 : null;
    return (received / size).clamp(0.0, 1.0);
  }

  UpdateState copyWith({
    UpdateStage? stage,
    int? received,
    int? total,
    double? speed,
    String? filePath,
    bool? cardVisible,
  }) {
    return UpdateState(
      tag: tag,
      asset: asset,
      body: body,
      stage: stage ?? this.stage,
      received: received ?? this.received,
      total: total ?? this.total,
      speed: speed ?? this.speed,
      filePath: filePath ?? this.filePath,
      cardVisible: cardVisible ?? this.cardVisible,
    );
  }
}
