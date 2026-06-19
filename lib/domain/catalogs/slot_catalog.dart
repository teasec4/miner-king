/// Slot upgrade tier.
class SlotTier {
  final int slots;
  final int price;

  const SlotTier({required this.slots, required this.price});
}

/// Static catalog of motherboard / slot upgrades.
class SlotCatalog {
  SlotCatalog._();

  static const tiers = [
    SlotTier(slots: 1, price: 0), // starting
    SlotTier(slots: 2, price: 400),
    SlotTier(slots: 4, price: 1500),
    SlotTier(slots: 8, price: 5000),
    SlotTier(slots: 12, price: 15000),
  ];

  /// Returns the next tier above current slot count, or null if maxed.
  static SlotTier? nextTier(int currentSlots) {
    for (final t in tiers) {
      if (t.slots > currentSlots) return t;
    }
    return null;
  }
}
