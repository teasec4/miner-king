class PsuUpgrade {
  final String id;
  final String name;
  final int price;
  final int maxWattPerGpu;
  final String? nextId;

  const PsuUpgrade({
    required this.id,
    required this.name,
    required this.price,
    required this.maxWattPerGpu,
    this.nextId,
  });
}

class PsuCatalog {
  PsuCatalog._();

  static const stock = PsuUpgrade(
    id: 'psu_stock',
    name: 'Stock PSU',
    price: 0,
    maxWattPerGpu: 150,
    nextId: 'psu_bronze',
  );
  static const bronze = PsuUpgrade(
    id: 'psu_bronze',
    name: 'Bronze PSU',
    price: 800,
    maxWattPerGpu: 300,
    nextId: 'psu_gold',
  );
  static const gold = PsuUpgrade(
    id: 'psu_gold',
    name: 'Gold PSU',
    price: 5000,
    maxWattPerGpu: 800,
  );

  static final all = [stock, bronze, gold];

  static PsuUpgrade? byId(String id) {
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  static PsuUpgrade? nextTier(String currentId) {
    final current = byId(currentId) ?? stock;
    if (current.nextId == null) return null;
    return byId(current.nextId!);
  }

  /// Check if a GPU wattage is supported by the current PSU.
  static bool supports(String psuId, double gpuWatts) {
    final psu = byId(psuId);
    if (psu == null) return gpuWatts <= stock.maxWattPerGpu;
    return gpuWatts <= psu.maxWattPerGpu;
  }
}
