import '../catalogs/gpu_catalog.dart';
import '../models/game.dart';
import '../models/gpu_instance.dart';
import '../models/gpu_model.dart';
import '../models/modifier.dart';

/// Calculates effective hashrate of a GPU considering all modifiers.
double _effectiveHashrate(
  GpuInstance gpu,
  GpuModel model,
  List<Modifier> modifiers,
) {
  if (gpu.condition <= 0) return 0; // dead card

  double base = model.baseHashrate;

  // Overclock modifier
  if (gpu.overclockLevel > 0) {
    base *= 1 + 0.2 * gpu.overclockLevel;
  }

  // Global hashrate modifiers from perks/events
  for (final m in modifiers.where((m) => m.stat == AffectedStat.hashrate)) {
    base *= 1 + m.value;
  }

  // Condition penalty
  base *= gpu.condition;

  return base;
}

/// Stateless system – calculates coin production per tick.
class MiningSystem {
  MiningSystem._();

  /// Returns how many coins are mined in one tick.
  static double mine(Game game) {
    double totalHashrate = 0;

    for (final gpu in game.farm.gpuList) {
      final model = GpuCatalog.byId(gpu.modelId);
      if (model == null) continue;
      totalHashrate += _effectiveHashrate(gpu, model, game.activeModifiers);
    }

    // Coins per tick: hashrate * rate.
    // 10 MH/s (GTX 1060) ≈ 7.2 coins/h ≈ $72/h at $10/coin
    return totalHashrate * 0.0002;
  }

  /// Returns total effective hashrate (for display).
  static double totalHashrate(Game game) {
    double total = 0;
    for (final gpu in game.farm.gpuList) {
      final model = GpuCatalog.byId(gpu.modelId);
      if (model == null) continue;
      total += _effectiveHashrate(gpu, model, game.activeModifiers);
    }
    return total;
  }
}
