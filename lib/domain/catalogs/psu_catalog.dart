class PsuUpgrade {
  final String id;
  final String name;
  final int price;
  final int maxWattPerGpu;

  const PsuUpgrade({
    required this.id,
    required this.name,
    required this.price,
    required this.maxWattPerGpu,
  });
}

class PsuCatalog {
  PsuCatalog._();

  static const stock = PsuUpgrade(
    id: 'psu_stock',
    name: 'Stock PSU',
    price: 200,
    maxWattPerGpu: 150,
  );
  static const bronze = PsuUpgrade(
    id: 'psu_bronze',
    name: 'Bronze PSU',
    price: 800,
    maxWattPerGpu: 300,
  );
  static const gold = PsuUpgrade(
    id: 'psu_gold',
    name: 'Gold PSU',
    price: 5000,
    maxWattPerGpu: 500,
  );
  static const platinum = PsuUpgrade(
    id: 'psu_platinum',
    name: 'Platinum PSU',
    price: 20000,
    maxWattPerGpu: 800,
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

  static bool supports(String psuId, double gpuWatts) {
    final psu = byId(psuId);
    if (psu == null) return gpuWatts <= stock.maxWattPerGpu;
    return gpuWatts <= psu.maxWattPerGpu;
  }
}
