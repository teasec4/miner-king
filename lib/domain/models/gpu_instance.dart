class GpuInstance {
  final String id;
  final String modelId;
  final String miningCoinId;
  final bool isPowered;
  final double condition;
  final double temperature;
  final int overclockLevel;
  final int siliconLotteryLevel;
  final double cycleProgress; // 0.0 → 1.0, reward at 1.0
  final List<String> debuffs;
  final String? equippedCooling; // itemId or null (stock)
  final String? equippedPsu; // itemId or null (stock)
  final String? equippedPaste; // itemId or null
  final String? equippedBios; // itemId or null

  GpuInstance({
    required this.id,
    required this.modelId,
    this.miningCoinId = 'btc',
    this.isPowered = true,
    this.condition = 1.0,
    this.temperature = 50,
    this.overclockLevel = 0,
    this.siliconLotteryLevel = 0,
    this.cycleProgress = 0,
    this.debuffs = const [],
    this.equippedCooling,
    this.equippedPsu,
    this.equippedPaste,
    this.equippedBios,
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
    double? cycleProgress,
    List<String>? debuffs,
    String? equippedCooling,
    String? equippedPsu,
    String? equippedPaste,
    String? equippedBios,
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
      cycleProgress: cycleProgress ?? this.cycleProgress,
      debuffs: debuffs ?? this.debuffs,
      equippedCooling: equippedCooling ?? this.equippedCooling,
      equippedPsu: equippedPsu ?? this.equippedPsu,
      equippedPaste: equippedPaste ?? this.equippedPaste,
      equippedBios: equippedBios ?? this.equippedBios,
    );
  }
}
