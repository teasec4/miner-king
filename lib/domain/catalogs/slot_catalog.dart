/// Slot upgrade tier.
class SlotTier {
  final int slots;
  final int price;

  const SlotTier({required this.slots, required this.price});

  String get label => '$slots slots';
}

/// Static catalog of motherboard / slot upgrades.
class SlotCatalog {
  SlotCatalog._();

  static const tiers = [
    SlotTier(slots: 1, price: 300),
    SlotTier(slots: 2, price: 1500),
    SlotTier(slots: 4, price: 6000),
    SlotTier(slots: 6, price: 15000),
  ];

  /// Returns the next tier above current slot count, or null if maxed.
  static SlotTier? nextTier(int currentSlots) {
    for (final t in tiers) {
      if (t.slots > currentSlots) return t;
    }
    return null;
  }

  static SlotTier? bySlots(int slots) {
    try {
      return tiers.firstWhere((t) => t.slots == slots);
    } catch (_) {
      return null;
    }
  }
}
