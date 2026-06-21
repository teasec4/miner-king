import '../catalogs/coin_catalog.dart';
import '../catalogs/debuff_catalog.dart';
import '../catalogs/gpu_catalog.dart';
import '../config/game_config.dart';
import '../models/game.dart';
import '../models/gpu_instance.dart';
import '../models/gpu_model.dart';
import '../models/player_profile.dart';
import 'employee_system.dart';

/// Cycle-based mining: each GPU fills a progress bar, reward on completion.
class MiningSystem {
  MiningSystem._();

  // ────────────────────────────────────────────────────────────
  // Public API — single source of truth for hashrate & revenue
  // ────────────────────────────────────────────────────────────

  /// Effective hashrate of a single GPU including employee bonuses.
  /// Returns 0 for dead or powered-off cards.
  static double effectiveHashrate(GpuInstance gpu, Game game) {
    final model = GpuCatalog.byId(gpu.modelId);
    if (model == null) return 0;
    var base = _computeHashrate(gpu, model, game.perks, game.character);
    if (base <= 0) return 0;
    base *= (1 + EmployeeSystem.hashrateBonus(game));
    return base;
  }

  /// Total effective hashrate of the entire farm (for display).
  static double totalHashrate(Game game) {
    double total = 0;
    for (final gpu in game.farm.gpuList) {
      total += effectiveHashrate(gpu, game);
    }
    return total;
  }

  /// Revenue this GPU generates per tick (theoretical, not actual cycle).
  static double revenuePerTick(GpuInstance gpu, Game game) {
    final hashrate = effectiveHashrate(gpu, game);
    if (hashrate <= 0) return 0;
    final coin = game.coin(gpu.miningCoinId);
    if (coin == null) return 0;
    return hashrate *
        GameConfig.cycleProgressPerHashrate *
        GameConfig.rewardPerCycle *
        coin.baseReward *
        coin.price;
  }

  /// Revenue per real-time minute (60 ticks).
  static double revenuePerMin(GpuInstance gpu, Game game) {
    return revenuePerTick(gpu, game) * 60;
  }

  /// Revenue per real-time hour (3600 ticks).
  static double revenuePerHour(GpuInstance gpu, Game game) {
    return revenuePerTick(gpu, game) * 3600;
  }

  // ─────────────────────────── Simulation ───────────────────────

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

      // Base hashrate (without employee bonus — that applies to progress)
      var hashrate = _computeHashrate(gpu, model, game.perks, game.character);
      if (hashrate <= 0) {
        updatedGpus.add(gpu.copyWith(cycleProgress: gpu.cycleProgress));
        continue;
      }

      final empBonus = EmployeeSystem.hashrateBonus(game);
      var progress =
          gpu.cycleProgress +
          hashrate * GameConfig.cycleProgressPerHashrate * (1 + empBonus);
      if (progress >= 1.0) {
        final completions = progress.floor();
        progress -= completions;
        final coin = CoinCatalog.byId(gpu.miningCoinId);
        final reward = coin?.baseReward ?? 1.0;
        final amount = GameConfig.rewardPerCycle * reward * completions;
        produced[gpu.miningCoinId] = (produced[gpu.miningCoinId] ?? 0) + amount;
      }
      updatedGpus.add(gpu.copyWith(cycleProgress: progress));
    }

    return (updatedGpus, produced);
  }

  // ─────────────────────────── Internals ─────────────────────────

  /// Core hashrate calculation (no employee bonuses — those are applied later).
  static double _computeHashrate(
    GpuInstance gpu,
    GpuModel model,
    List<Perk> perks,
    CharacterType? character,
  ) {
    if (gpu.condition <= 0) return 0;
    if (!gpu.isPowered) return 0;

    double base = model.baseHashrate;

    if (gpu.effectiveOverclock > 0) {
      base *= 1 + GameConfig.overclockHashratePerLevel * gpu.effectiveOverclock;
    }

    if (perks.any((p) => p.effect == PerkEffect.siliconLottery)) {
      base *= 1 + GameConfig.siliconLotteryHashrateBonus;
    }
    if (perks.any((p) => p.effect == PerkEffect.riskLover)) {
      base *= 1 + GameConfig.riskLoverHashrateBonus;
    }

    base *= gpu.condition;
    for (final d in gpu.debuffs) {
      final debuff = DebuffCatalog.byId(d);
      if (debuff != null) base *= debuff.hashrateMul;
    }
    if (character == CharacterType.miner) {
      base *= 1 + GameConfig.minerHashrateBonus;
    }
    return base;
  }
}
