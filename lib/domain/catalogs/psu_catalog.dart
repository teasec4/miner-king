class PsuUpgrade {
  final String id;
  final String name;
  final int price;
  final int maxTotalWatt; // total farm wattage capacity

  const PsuUpgrade({
    required this.id,
    required this.name,
    required this.price,
    required this.maxTotalWatt,
  });
}

class PsuCatalog {
  PsuCatalog._();

  static const stock = PsuUpgrade(
    id: 'psu_stock',
    name: 'Stock PSU',
    price: 200,
    maxTotalWatt: 150,
  );
  static const bronze = PsuUpgrade(
    id: 'psu_bronze',
    name: 'Bronze PSU',
    price: 800,
    maxTotalWatt: 300,
  );
  static const gold = PsuUpgrade(
    id: 'psu_gold',
    name: 'Gold PSU',
    price: 3000,
    maxTotalWatt: 600,
  );
  static const platinum = PsuUpgrade(
    id: 'psu_platinum',
    name: 'Platinum PSU',
    price: 10000,
    maxTotalWatt: 1200,
  );

  static final all = [stock, bronze, gold, platinum];

  static PsuUpgrade? byId(String id) {
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  static int indexOf(String id) {
    final idx = all.indexWhere((p) => p.id == id);
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

  /// Total PSU capacity for the farm.
  static int capacity(String? psuId) {
    final psu = byId(psuId ?? 'psu_stock');
    return psu?.maxTotalWatt ?? stock.maxTotalWatt;
  }
}
