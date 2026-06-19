/// Permanent negative traits for black-market GPUs.
class Debuff {
  final String id;
  final String name;
  final String description;
  final double hashrateMul; // multiplier on hashrate (1.0 = normal)
  final double tempAdd; // added °C
  final double wearMul; // multiplier on wear rate
  final int repairCost; // cost to remove this debuff

  const Debuff({
    required this.id,
    required this.name,
    required this.description,
    this.hashrateMul = 1.0,
    this.tempAdd = 0,
    this.wearMul = 1.0,
    this.repairCost = 0,
  });
}

class DebuffCatalog {
  DebuffCatalog._();

  static const scratched = Debuff(
    id: 'scratched',
    name: 'Scratched',
    description: '-15% hashrate',
    hashrateMul: 0.85,
    repairCost: 200,
  );
  static const noisy = Debuff(
    id: 'noisy',
    name: 'Noisy Fan',
    description: '+10°C',
    tempAdd: 10,
    repairCost: 150,
  );
  static const unstable = Debuff(
    id: 'unstable',
    name: 'Unstable',
    description: '+50% wear',
    wearMul: 1.5,
    repairCost: 300,
  );
  static const cracked = Debuff(
    id: 'cracked',
    name: 'Cracked PCB',
    description: '-20% hashrate, +10°C',
    hashrateMul: 0.8,
    tempAdd: 10,
    repairCost: 500,
  );
  static const fake = Debuff(
    id: 'fake',
    name: 'Fake Chip',
    description: '-40% hashrate',
    hashrateMul: 0.6,
    repairCost: 800,
  );

  static final all = [scratched, noisy, unstable, cracked, fake];

  static Debuff? byId(String id) {
    try {
      return all.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }
}
