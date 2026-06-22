/// Simple slot pricing — each additional slot costs more.
class SlotCatalog {
  SlotCatalog._();

  static final _prices = [300, 600, 1200, 2400, 4800];

  /// Cost to buy the next slot (returns 0 if maxed at 6 slots).
  static int nextSlotCost(int currentSlots) {
    final idx = currentSlots - 1;
    if (idx < 0) return _prices[0];
    if (idx >= _prices.length) return 0;
    return idx < _prices.length ? _prices[idx] : 0;
  }

  /// Max slots.
  static const int maxSlots = 6;

  /// Whether more slots can be bought.
  static bool canBuyMore(int currentSlots) => currentSlots < maxSlots;
}
