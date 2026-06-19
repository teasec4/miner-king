/// Buyable upgrade: cooling system.
class CoolingUpgrade {
  final String id;
  final String name;
  final int price;
  final double tempReduction; // °C

  const CoolingUpgrade({
    required this.id,
    required this.name,
    required this.price,
    required this.tempReduction,
  });
}

class CoolingCatalog {
  CoolingCatalog._();

  static const fans = CoolingUpgrade(
    id: 'fans',
    name: 'Fan Cooling',
    price: 300,
    tempReduction: -10,
  );
  static const water = CoolingUpgrade(
    id: 'water',
    name: 'Water Cooling',
    price: 1000,
    tempReduction: -20,
  );
  static const immersion = CoolingUpgrade(
    id: 'immersion',
    name: 'Immersion Cooling',
    price: 5000,
    tempReduction: -30,
  );

  static final all = [fans, water, immersion];
}
