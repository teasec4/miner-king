/// Player character type with unique starting bonuses.
enum CharacterType {
  enthusiast('Enthusiast', 'GPU efficiency +20%'),
  engineer('Engineer', 'GPU wear -30%'),
  businessman('Businessman', 'Equipment -15% discount'),
  speculator('Speculator', 'Swap fee 0.5% (was 1%)');

  final String name;
  final String description;

  const CharacterType(this.name, this.description);
}

/// Permanent perk that modifies game rules.
class Perk {
  final String id;
  final String name;
  final String description;
  final PerkEffect effect;

  const Perk({
    required this.id,
    required this.name,
    required this.description,
    required this.effect,
  });
}

enum PerkEffect {
  efficientFans, // -15°C to all GPUs
  siliconLottery, // +10% hashrate
  betterMobo, // +2 free slots
  cheapElectricity, // -20% electricity cost
  luckyTrader, // +25% sell profit
  riskLover, // +50% hashrate, +50% wear
  undervoltGuru, // -20% power consumption
  repairMaster, // repair cost -50%
}

/// Static catalog of all perks.
class PerkCatalog {
  PerkCatalog._();

  static const all = [
    Perk(
      id: 'efficient_fans',
      name: 'Efficient Fans',
      description: 'All GPUs run 15°C cooler',
      effect: PerkEffect.efficientFans,
    ),
    Perk(
      id: 'silicon_lottery',
      name: 'Silicon Lottery',
      description: 'Permanent +10% hashrate boost',
      effect: PerkEffect.siliconLottery,
    ),
    Perk(
      id: 'better_mobo',
      name: 'Better Motherboard',
      description: '+2 free GPU slots',
      effect: PerkEffect.betterMobo,
    ),
    Perk(
      id: 'cheap_electricity',
      name: 'Cheap Electricity',
      description: 'Electricity cost -20%',
      effect: PerkEffect.cheapElectricity,
    ),
    Perk(
      id: 'lucky_trader',
      name: 'Lucky Trader',
      description: '+25% profit when selling coins',
      effect: PerkEffect.luckyTrader,
    ),
    Perk(
      id: 'risk_lover',
      name: 'Risk Lover',
      description: '+50% hashrate, but +50% wear speed',
      effect: PerkEffect.riskLover,
    ),
    Perk(
      id: 'undervolt_guru',
      name: 'Undervolt Guru',
      description: 'All GPUs use 20% less power',
      effect: PerkEffect.undervoltGuru,
    ),
    Perk(
      id: 'repair_master',
      name: 'Repair Master',
      description: 'Repair costs reduced by 50%',
      effect: PerkEffect.repairMaster,
    ),
  ];

  static List<Perk> randomPicks(int count, List<String> excludeIds) {
    final available = all.where((p) => !excludeIds.contains(p.id)).toList();
    available.shuffle();
    return available.take(count).toList();
  }
}
