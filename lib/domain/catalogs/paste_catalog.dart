class PasteUpgrade {
  final String id;
  final String name;
  final int price;
  final double tempReduction;

  const PasteUpgrade({
    required this.id,
    required this.name,
    required this.price,
    required this.tempReduction,
  });
}

class PasteCatalog {
  PasteCatalog._();

  static const none = PasteUpgrade(
    id: 'paste_none',
    name: 'No Paste',
    price: 50,
    tempReduction: -1,
  );
  static const basic = PasteUpgrade(
    id: 'paste_basic',
    name: 'Basic Paste',
    price: 100,
    tempReduction: -2,
  );
  static const silver = PasteUpgrade(
    id: 'paste_silver',
    name: 'Silver Paste',
    price: 500,
    tempReduction: -5,
  );
  static const ceramic = PasteUpgrade(
    id: 'paste_ceramic',
    name: 'Ceramic Paste',
    price: 2000,
    tempReduction: -10,
  );
  static const liquid = PasteUpgrade(
    id: 'paste_liquid',
    name: 'Liquid Metal',
    price: 8000,
    tempReduction: -18,
  );

  // All buyable/upgradable tiers (excluding 'none' which is the default null state)
  static final all = [basic, silver, ceramic, liquid];

  static PasteUpgrade? byId(String id) {
    if (id == 'paste_none') return none;
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  static int indexOf(String id) {
    if (id == 'paste_none') return -1;
    final idx = all.indexWhere((p) => p.id == id);
    return idx >= 0 ? idx : 0;
  }

  static int upgradeCost(int fromIdx, int toIdx) {
    if (fromIdx < 0) fromIdx = 0;
    if (toIdx <= fromIdx || toIdx >= all.length) return 0;
    int cost = 0;
    for (int i = fromIdx + 1; i <= toIdx; i++) {
      cost += all[i].price;
    }
    return cost;
  }
}
