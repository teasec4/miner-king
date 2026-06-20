/// An item sitting in the player's inventory (bought, not yet equipped).
class InventoryItem {
  final String id;
  final String itemId;
  final String type; // 'cooling', 'psu', 'paste', 'bios', 'motherboard'
  final String name;
  final String detail;
  final String? equippedToGpu;
  final Map<String, dynamic>? data; // extra: debuffs for black market GPUs

  const InventoryItem({
    required this.id,
    required this.itemId,
    required this.type,
    required this.name,
    required this.detail,
    this.equippedToGpu,
    this.data,
  });

  bool get isEquipped => equippedToGpu != null;

  InventoryItem copyWith({
    String? id,
    String? itemId,
    String? type,
    String? name,
    String? detail,
    String? equippedToGpu,
    Map<String, dynamic>? data,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      type: type ?? this.type,
      name: name ?? this.name,
      detail: detail ?? this.detail,
      equippedToGpu: equippedToGpu ?? this.equippedToGpu,
      data: data ?? this.data,
    );
  }
}
