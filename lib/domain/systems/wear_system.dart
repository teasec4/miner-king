import '../models/game.dart';

/// Gradual GPU degradation system.
///
/// Instead of binary broken/not, GPUs accumulate wear over time.
/// Wear reduces hashrate (via condition multiplier), increases temperature,
/// and accelerates further damage — creating a snowball effect.
class WearSystem {
  WearSystem._();

  /// Apply wear to all GPUs based on their temperature.
  /// Returns updated Game.
  static Game update(Game game) {
    final updatedGpus = game.farm.gpuList.map((gpu) {
      final temp = gpu.temperature;
      if (temp <= 70) return gpu; // safe zone, no wear
      if (gpu.condition <= 0) return gpu; // already dead
      if (!gpu.isPowered) return gpu; // turned off – no wear

      // Base wear rate per tick based on temperature
      final wearRate = temp <= 90
          ? (temp - 70) /
                20 *
                0.0015 // 0 → 0.0015
          : 0.0015 + (temp - 90) * 0.0005; // 0.0015+ per °C above 90

      // Acceleration: worn cards degrade faster (up to 3x)
      final accelerator = 1 + (1 - gpu.condition) * 2;

      final newCondition = (gpu.condition - wearRate * accelerator).clamp(
        0.0,
        1.0,
      );

      return gpu.copyWith(condition: newCondition);
    }).toList();

    return game.copyWith(farm: game.farm.copyWith(gpuList: updatedGpus));
  }

  /// Estimated time (in ticks) until condition drops to 50%.
  static double ticksToHalfCondition(double temp, double currentCondition) {
    if (temp <= 70) return double.infinity;
    final wearRate = temp <= 90
        ? (temp - 70) / 20 * 0.0015
        : 0.0015 + (temp - 90) * 0.0005;
    // Average accelerator between current and 50%
    final avgAccel = 1 + (1 - (currentCondition + 0.5) / 2) * 2;
    return (currentCondition - 0.5) / (wearRate * avgAccel);
  }
}
