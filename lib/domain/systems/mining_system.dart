import '../catalogs/coin_catalog.dart';
import '../catalogs/gpu_catalog.dart';
import '../models/game.dart';
import '../models/gpu_instance.dart';
import '../models/gpu_model.dart';
import '../models/modifier.dart';
import '../models/player_profile.dart';

double _effectiveHashrate(
  GpuInstance gpu,
  GpuModel model,
  List<Modifier> modifiers,
  List<Perk> perks,
) {
  if (gpu.condition <= 0) return 0;
  if (!gpu.isPowered) return 0;

  double base = model.baseHashrate;

  if (gpu.effectiveOverclock > 0) {
    base *= 1 + 0.2 * gpu.effectiveOverclock;
  }

  // Perk: Silicon Lottery +10%
  if (perks.any((p) => p.effect == PerkEffect.siliconLottery)) {
    base *= 1.1;
  }
  // Perk: Risk Lover +50%
  if (perks.any((p) => p.effect == PerkEffect.riskLover)) {
    base *= 1.5;
  }

  for (final m in modifiers.where((m) => m.stat == AffectedStat.hashrate)) {
    base *= 1 + m.value;
  }

  base *= gpu.condition;
  return base;
}

/// Stateless system – calculates coin production per tick for each coin.
class MiningSystem {
  MiningSystem._();

  /// Returns a map of coinId → coins mined this tick.
  static Map<String, double> mine(Game game) {
    final produced = <String, double>{};

    for (final gpu in game.farm.gpuList) {
      final model = GpuCatalog.byId(gpu.modelId);
      if (model == null) continue;

      final hashrate = _effectiveHashrate(
        gpu,
        model,
        game.activeModifiers,
        game.perks,
      );
      if (hashrate <= 0) continue;

      final coin = CoinCatalog.byId(gpu.miningCoinId);
      final reward = coin?.baseReward ?? 1.0;

      // Coins per tick: hashrate * baseRate * coinReward
      final amount = hashrate * 0.0002 * reward;

      produced[gpu.miningCoinId] = (produced[gpu.miningCoinId] ?? 0) + amount;
    }

    return produced;
  }

  /// Returns total effective hashrate (for display).
  static double totalHashrate(Game game) {
    double total = 0;
    for (final gpu in game.farm.gpuList) {
      final model = GpuCatalog.byId(gpu.modelId);
      if (model == null) continue;
      total += _effectiveHashrate(gpu, model, game.activeModifiers, game.perks);
    }
    return total;
  }
}
