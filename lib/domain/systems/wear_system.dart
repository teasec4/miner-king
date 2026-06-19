import '../models/game.dart';

/// Gradual GPU degradation system.
///
/// Wear starts at 65°C+. Each °C above increases wear rate.
/// Worn cards degrade faster (snowball) and run hotter.
class WearSystem {
  WearSystem._();

  static Game update(Game game) {
    final updatedGpus = game.farm.gpuList.map((gpu) {
      final temp = gpu.temperature;
      if (temp < 65) return gpu; // safe zone
      if (gpu.condition <= 0) return gpu;
      if (!gpu.isPowered) return gpu;

      // Wear rate: 0 at 65°C → 0.005/tick at 90°C → more above
      final wearRate = temp <= 90
          ? (temp - 65) / 25 * 0.005
          : 0.005 + (temp - 90) * 0.002;

      // Worn cards degrade up to 3x faster
      final accelerator = 1 + (1 - gpu.condition) * 2;

      final newCondition = (gpu.condition - wearRate * accelerator).clamp(
        0.0,
        1.0,
      );

      return gpu.copyWith(condition: newCondition);
    }).toList();

    return game.copyWith(farm: game.farm.copyWith(gpuList: updatedGpus));
  }
}
