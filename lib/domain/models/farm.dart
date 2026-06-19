import 'gpu_instance.dart';

/// Describes the player's current mining farm.
class Farm {
  final List<GpuInstance> gpuList;
  final int totalSlots;
  final String coolingSystem; // e.g. 'basic', 'fans', 'water', 'immersion'

  const Farm({
    required this.gpuList,
    required this.totalSlots,
    this.coolingSystem = 'basic',
  });

  int get usedSlots => gpuList.length;
  bool get hasFreeSlots => usedSlots < totalSlots;

  Farm copyWith({
    List<GpuInstance>? gpuList,
    int? totalSlots,
    String? coolingSystem,
  }) {
    return Farm(
      gpuList: gpuList ?? this.gpuList,
      totalSlots: totalSlots ?? this.totalSlots,
      coolingSystem: coolingSystem ?? this.coolingSystem,
    );
  }
}
