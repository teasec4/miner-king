import 'gpu_catalog.dart';

/// Slot upgrade tier.
class SlotTier {
  final int slots;
  final int price;
  final int maxGpuTier; // 0=1060, 1=2060, 2=3070, 3=5090. -1 = any

  const SlotTier({
    required this.slots,
    required this.price,
    this.maxGpuTier = -1,
  });

  String get label => '$slots slots';
}

/// Static catalog of motherboard / slot upgrades.
class SlotCatalog {
  SlotCatalog._();

  static const tiers = [
    SlotTier(slots: 1, price: 500, maxGpuTier: 0),
    SlotTier(slots: 2, price: 3000, maxGpuTier: 1), // Dual: up to RTX 2060
    SlotTier(slots: 4, price: 12000, maxGpuTier: 2), // Quad: up to RTX 3070
    SlotTier(slots: 8, price: 50000, maxGpuTier: 3), // Octa: up to RTX 5090
  ];

  static final gpuTierOrder = ['gtx_1060', 'rtx_2060', 'rtx_3070', 'rtx_5090'];

  /// Returns the next tier above current slot count, or null if maxed.
  static SlotTier? nextTier(int currentSlots) {
    for (final t in tiers) {
      if (t.slots > currentSlots) return t;
    }
    return null;
  }

  /// Check if a GPU model can be installed on the current motherboard.
  static bool canInstallGpu(int totalSlots, String gpuModelId) {
    final tier = tiers.where((t) => t.slots == totalSlots).firstOrNull;
    if (tier == null) return false;
    if (tier.maxGpuTier < 0) return true;
    final gpuIdx = GpuCatalog.indexOf(gpuModelId);
    return gpuIdx >= 0 && gpuIdx <= tier.maxGpuTier;
  }

  static SlotTier? bySlots(int slots) {
    try {
      return tiers.firstWhere((t) => t.slots == slots);
    } catch (_) {
      return null;
    }
  }
}
