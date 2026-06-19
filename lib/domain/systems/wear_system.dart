import 'dart:math';
import '../catalogs/debuff_catalog.dart';
import '../models/game.dart';
import '../models/player_profile.dart';
import 'employee_system.dart';

/// Gradual GPU degradation + random failures.
///
/// Wear starts at 50°C+. Worn cards degrade faster.
/// Above 90°C: chance of sudden damage.
class WearSystem {
  WearSystem._();
  static final _r = Random();

  static Game update(Game game) {
    final updatedGpus = game.farm.gpuList.map((gpu) {
      final temp = gpu.temperature;
      if (temp < 50) return gpu; // safe zone
      if (gpu.condition <= 0) return gpu;
      if (!gpu.isPowered) return gpu;

      // Wear rate: 0 at 50°C → 0.001/tick at 90°C → more above
      final wearRate = temp <= 90
          ? (temp - 50) / 40 * 0.001
          : 0.001 + (temp - 90) * 0.001;

      // Worn cards degrade up to 3x faster
      var accelerator = 1 + (1 - gpu.condition) * 2;
      for (final d in gpu.debuffs) {
        final debuff = DebuffCatalog.byId(d);
        if (debuff != null) accelerator *= debuff.wearMul;
      }
      if (game.perks.any((p) => p.effect == PerkEffect.riskLover)) {
        accelerator *= 1.5;
      }
      // Repair techs reduce wear
      accelerator *= (1 - EmployeeSystem.wearReduction(game));
      // Character: Engineer -50% wear
      if (game.character == CharacterType.engineer) accelerator *= 0.5;

      var newCondition = (gpu.condition - wearRate * accelerator).clamp(
        0.0,
        1.0,
      );

      // Random critical failure: above 90°C, chance of sudden damage
      if (temp > 90 && newCondition > 0 && _r.nextDouble() < 0.002) {
        newCondition = (newCondition - 0.05).clamp(0.0, 1.0);
      }

      return gpu.copyWith(condition: newCondition);
    }).toList();

    return game.copyWith(farm: game.farm.copyWith(gpuList: updatedGpus));
  }
}
