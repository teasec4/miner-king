class CoolingUpgrade {
  final String id;
  final String name;
  final int price;
  final double tempReduction;

  const CoolingUpgrade({
    required this.id,
    required this.name,
    required this.price,
    required this.tempReduction,
  });
}

class CoolingCatalog {
  CoolingCatalog._();

  static const basic = CoolingUpgrade(
    id: 'basic',
    name: 'Stock Fan',
    price: 100,
    tempReduction: -2,
  );
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
    name: 'Immersion',
    price: 5000,
    tempReduction: -30,
  );

  static final all = [basic, fans, water, immersion];

  static CoolingUpgrade? byId(String id) {
    try {
      return all.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  static int indexOf(String id) {
    final idx = all.indexWhere((c) => c.id == id);
    return idx >= 0 ? idx : 0;
  }

  static int upgradeCost(int fromIdx, int toIdx) {
    if (toIdx <= fromIdx || toIdx >= all.length) return 0;
    int cost = 0;
    for (int i = fromIdx + 1; i <= toIdx; i++) {
      cost += all[i].price;
    }
    return cost;
  }
}
