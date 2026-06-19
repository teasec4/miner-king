class GpuInstance {
  final String id;
  final String modelId;
  final String miningCoinId;
  final bool isPowered;
  double condition;
  double temperature;
  int overclockLevel;
  int siliconLotteryLevel;

  GpuInstance({
    required this.id,
    required this.modelId,
    this.miningCoinId = 'btc',
    this.isPowered = true,
    this.condition = 1.0,
    this.temperature = 50,
    this.overclockLevel = 0,
    this.siliconLotteryLevel = 0,
  });

  int get effectiveOverclock => overclockLevel + siliconLotteryLevel;

  GpuInstance copyWith({
    String? id,
    String? modelId,
    String? miningCoinId,
    bool? isPowered,
    double? condition,
    double? temperature,
    int? overclockLevel,
    int? siliconLotteryLevel,
  }) {
    return GpuInstance(
      id: id ?? this.id,
      modelId: modelId ?? this.modelId,
      miningCoinId: miningCoinId ?? this.miningCoinId,
      isPowered: isPowered ?? this.isPowered,
      condition: condition ?? this.condition,
      temperature: temperature ?? this.temperature,
      overclockLevel: overclockLevel ?? this.overclockLevel,
      siliconLotteryLevel: siliconLotteryLevel ?? this.siliconLotteryLevel,
    );
  }
}
