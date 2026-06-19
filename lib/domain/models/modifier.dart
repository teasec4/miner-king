/// A source of stat modifications.
/// Applied by perks, events, overclock, upgrades, etc.
enum ModifierSource { overclock, event, perk, upgrade }

enum AffectedStat {
  hashrate,
  temperature,
  powerConsumption,
  repairCost,
  coinPrice,
}

class Modifier {
  final AffectedStat stat;
  final double value; // multiplier, e.g. 0.2 = +20%, -0.3 = -30%
  final ModifierSource source;
  final String sourceId; // which perk/event/etc. applied this

  const Modifier({
    required this.stat,
    required this.value,
    required this.source,
    required this.sourceId,
  });
}
