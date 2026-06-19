/// A concrete GPU installed in the farm.
/// References a [GpuModel] template and holds runtime state.
class GpuInstance {
  final String id;
  final String modelId;
  final String miningCoinId; // which coin this GPU mines
  double condition; // 0.0 – 1.0
  double temperature; // current temp in Celsius
  int overclockLevel; // 0 = stock, 1, 2, 3...
  bool isBroken;

  GpuInstance({
    required this.id,
    required this.modelId,
    this.miningCoinId = 'btc',
    this.condition = 1.0,
    this.temperature = 50,
    this.overclockLevel = 0,
    this.isBroken = false,
  });

  GpuInstance copyWith({
    String? id,
    String? modelId,
    String? miningCoinId,
    double? condition,
    double? temperature,
    int? overclockLevel,
  }) {
    return GpuInstance(
      id: id ?? this.id,
      modelId: modelId ?? this.modelId,
      miningCoinId: miningCoinId ?? this.miningCoinId,
      condition: condition ?? this.condition,
      temperature: temperature ?? this.temperature,
      overclockLevel: overclockLevel ?? this.overclockLevel,
    );
  }
}
