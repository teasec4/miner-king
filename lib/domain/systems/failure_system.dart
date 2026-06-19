import 'dart:math';

import '../models/game.dart';
import '../models/gpu_instance.dart';

/// Checks for GPU failures based on temperature.
class FailureSystem {
  FailureSystem._();

  static final _random = Random();

  /// Check all GPUs for failures and return updated Game.
  static Game update(Game game) {
    final updatedGpus = game.farm.gpuList.map((gpu) {
      if (gpu.isBroken) return gpu; // already broken

      final chance = _failureChance(gpu.temperature);
      if (_random.nextDouble() < chance) {
        return gpu.copyWith(isBroken: true);
      }
      return gpu;
    }).toList();

    return game.copyWith(farm: game.farm.copyWith(gpuList: updatedGpus));
  }

  /// Probability of failure per tick based on temperature.
  static double _failureChance(double temp) {
    if (temp <= 70) return 0.0;
    if (temp <= 90) return (temp - 70) / 20 * 0.01; // up to 1% per tick
    return 0.01 + (temp - 90) * 0.005; // 1% + 0.5% per degree above 90
  }

  /// Repair cost based on GPU tier (approximate).
  static int repairCost(GpuInstance gpu) {
    // Base repair cost: 20% of GPU price
    // We don't have price on instance, so use a flat formula.
    // This will be refined when we have better model access.
    return 50; // placeholder, overridden in GameState
  }
}
