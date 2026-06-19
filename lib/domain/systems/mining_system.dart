import '../catalogs/coin_catalog.dart';
import '../catalogs/debuff_catalog.dart';
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

  if (perks.any((p) => p.effect == PerkEffect.siliconLottery)) {
    base *= 1.1;
  }
  if (perks.any((p) => p.effect == PerkEffect.riskLover)) {
    base *= 1.5;
  }

  for (final m in modifiers.where((m) => m.stat == AffectedStat.hashrate)) {
    base *= 1 + m.value;
  }

  base *= gpu.condition;
  // Debuffs
  for (final d in gpu.debuffs) {
    final debuff = DebuffCatalog.byId(d);
    if (debuff != null) base *= debuff.hashrateMul;
  }
  return base;
}

/// Cycle-based mining: each GPU fills a progress bar, reward on completion.
class MiningSystem {
  MiningSystem._();

  /// Advance cycles. Returns (updated GPUs, coins produced this tick).
  static (List<GpuInstance>, Map<String, double>) mine(Game game) {
    final produced = <String, double>{};
    final updatedGpus = <GpuInstance>[];

    for (final gpu in game.farm.gpuList) {
      final model = GpuCatalog.byId(gpu.modelId);
      if (model == null) {
        updatedGpus.add(gpu);
        continue;
      }

      final hashrate = _effectiveHashrate(
        gpu,
        model,
        game.activeModifiers,
        game.perks,
      );
      if (hashrate <= 0) {
        updatedGpus.add(gpu.copyWith(cycleProgress: gpu.cycleProgress));
        continue;
      }

      // Progress per tick: hashrate * 0.02 (10 MH/s → 0.2/tick → 5s cycle)
      var progress = gpu.cycleProgress + hashrate * 0.02;
      if (progress >= 1.0) {
        // Cycle complete — grant reward
        final completions = progress.floor();
        progress -= completions;
        final coin = CoinCatalog.byId(gpu.miningCoinId);
        final reward = coin?.baseReward ?? 1.0;
        final amount = 0.01 * reward * completions;
        produced[gpu.miningCoinId] = (produced[gpu.miningCoinId] ?? 0) + amount;
      }
      updatedGpus.add(gpu.copyWith(cycleProgress: progress));
    }

    return (updatedGpus, produced);
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
