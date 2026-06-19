/// Static template for a GPU type.
/// Lives in catalogs, never changes during gameplay.
class GpuModel {
  final String id;
  final String name;
  final double baseHashrate; // MH/s
  final double basePowerConsumption; // Watts
  final double baseTemperature; // Celsius
  final int price; // $

  const GpuModel({
    required this.id,
    required this.name,
    required this.baseHashrate,
    required this.basePowerConsumption,
    required this.baseTemperature,
    required this.price,
  });
}
