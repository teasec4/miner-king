import 'dart:math';
import '../catalogs/debuff_catalog.dart';
import '../config/game_config.dart';
import '../models/game.dart';
import '../models/player_profile.dart';
import 'employee_system.dart';

/// Gradual GPU degradation + random failures.
class WearSystem {
  WearSystem._();
  static final _r = Random();

  static Game update(Game game) {
    final updatedGpus = game.farm.gpuList.map((gpu) {
      final temp = gpu.temperature;
      if (temp < GameConfig.safeTemp) return gpu;
      if (gpu.condition <= 0) return gpu;
      if (!gpu.isPowered) return gpu;

      // Wear rate: 0 at safeTemp → wearRateAtDangerous at dangerousTemp → more above
      final wearRate = temp <= GameConfig.dangerousTemp
          ? (temp - GameConfig.safeTemp) /
                (GameConfig.dangerousTemp - GameConfig.safeTemp) *
                GameConfig.wearRateAtDangerous
          : GameConfig.wearRateAtDangerous +
                (temp - GameConfig.dangerousTemp) *
                    GameConfig.wearRateAboveDangerousPerDegree;

      var accelerator =
          1 + (1 - gpu.condition) * GameConfig.wearConditionAccelerator;
      for (final d in gpu.debuffs) {
        final debuff = DebuffCatalog.byId(d);
        if (debuff != null) accelerator *= debuff.wearMul;
      }
      if (game.perks.any((p) => p.effect == PerkEffect.riskLover)) {
        accelerator *= GameConfig.riskLoverWearMultiplier;
      }
      accelerator *= (1 - EmployeeSystem.wearReduction(game));
      if (game.character == CharacterType.engineer) {
        accelerator *= GameConfig.engineerWearReduction;
      }

      var newCondition = (gpu.condition - wearRate * accelerator).clamp(
        0.0,
        1.0,
      );

      // Random critical failure above dangerousTemp
      if (temp > GameConfig.dangerousTemp &&
          newCondition > 0 &&
          _r.nextDouble() < GameConfig.critFailureChance) {
        newCondition = (newCondition - GameConfig.critFailureDamage).clamp(
          0.0,
          1.0,
        );
      }

      return gpu.copyWith(condition: newCondition);
    }).toList();

    return game.copyWith(farm: game.farm.copyWith(gpuList: updatedGpus));
  }
}
