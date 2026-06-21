import 'gpu_instance.dart';

/// Describes the player's current mining farm.
class Farm {
  final List<GpuInstance> gpuList;
  final int totalSlots;
  final String coolingSystem; // 'basic', 'fans', 'water', 'immersion'
  final String psuTier; // 'psu_stock', 'psu_bronze', 'psu_gold', 'psu_platinum'

  const Farm({
    required this.gpuList,
    required this.totalSlots,
    this.coolingSystem = 'basic',
    this.psuTier = 'psu_stock',
  });

  int get usedSlots => gpuList.length;
  bool get hasFreeSlots => usedSlots < totalSlots;

  Farm copyWith({
    List<GpuInstance>? gpuList,
    int? totalSlots,
    String? coolingSystem,
    String? psuTier,
  }) {
    return Farm(
      gpuList: gpuList ?? this.gpuList,
      totalSlots: totalSlots ?? this.totalSlots,
      coolingSystem: coolingSystem ?? this.coolingSystem,
      psuTier: psuTier ?? this.psuTier,
    );
  }
}
