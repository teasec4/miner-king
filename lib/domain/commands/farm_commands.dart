import 'package:uuid/uuid.dart';
import '../catalogs/cooling_catalog.dart';
import '../catalogs/gpu_catalog.dart';
import '../catalogs/paste_catalog.dart';
import '../catalogs/psu_catalog.dart';
import '../catalogs/slot_catalog.dart';
import '../catalogs/solar_catalog.dart';
import '../models/game.dart';
import '../models/inventory_item.dart';

final _farmUuid = const Uuid();

/// Pure functions for farm operations: slots, cooling, solar, PSU, equipment.
class FarmCommands {
  FarmCommands._();

  // ── Buy equipment (goes to inventory) ──

  static Game? buySlotTier(Game game, SlotTier tier) {
    if (game.money < tier.price) return null;
    final item = _inv(
      'motherboard',
      'mobo_${tier.slots}',
      'Motherboard ${tier.slots} slots',
      '${tier.slots} slots',
    );
    return game.copyWith(
      money: game.money - tier.price,
      inventory: [...game.inventory, item],
    );
  }

  static Game? buyCooling(Game game, CoolingUpgrade upgrade) {
    if (game.money < upgrade.price) return null;
    final item = _inv(
      'cooling',
      upgrade.id,
      upgrade.name,
      '${upgrade.tempReduction}°C',
    );
    return game.copyWith(
      money: game.money - upgrade.price,
      inventory: [...game.inventory, item],
    );
  }

  static Game? buySolar(Game game, SolarUpgrade upgrade) {
    if (game.money < upgrade.price) return null;
    return game.copyWith(
      money: game.money - upgrade.price,
      farm: game.farm.copyWith(
        solarPower: game.farm.solarPower + upgrade.powerGen,
      ),
    );
  }

  static Game? buyPsu(Game game, PsuUpgrade upgrade) {
    if (game.money < upgrade.price) return null;
    final item = _inv(
      'psu',
      upgrade.id,
      upgrade.name,
      '${upgrade.maxWattPerGpu}W',
    );
    return game.copyWith(
      money: game.money - upgrade.price,
      inventory: [...game.inventory, item],
    );
  }

  static Game? buyPaste(Game game, PasteUpgrade upgrade) {
    if (game.money < upgrade.price) return null;
    final item = _inv(
      'paste',
      upgrade.id,
      upgrade.name,
      '${upgrade.tempReduction}°C',
    );
    return game.copyWith(
      money: game.money - upgrade.price,
      inventory: [...game.inventory, item],
    );
  }

  // ── Equip / unequip ──

  static Game? equipToGpu(Game game, String inventoryItemId, String gpuId) {
    final invIdx = game.inventory.indexWhere((i) => i.id == inventoryItemId);
    if (invIdx == -1) return null;
    final item = game.inventory[invIdx];
    if (item.isEquipped) return null;

    final gpuIdx = game.farm.gpuList.indexWhere((g) => g.id == gpuId);
    if (gpuIdx == -1) return null;
    final gpu = game.farm.gpuList[gpuIdx];

    final newGpu = switch (item.type) {
      'cooling' => gpu.copyWith(equippedCooling: item.itemId),
      'psu' => gpu.copyWith(equippedPsu: item.itemId),
      'paste' => gpu.copyWith(equippedPaste: item.itemId),
      'bios' => gpu.copyWith(equippedBios: item.itemId),
      _ => null,
    };
    if (newGpu == null) return null;

    final newInventory = [...game.inventory];
    newInventory[invIdx] = item.copyWith(equippedToGpu: gpuId);
    final newGpus = [...game.farm.gpuList];
    newGpus[gpuIdx] = newGpu;

    return game.copyWith(
      inventory: newInventory,
      farm: game.farm.copyWith(gpuList: newGpus),
    );
  }

  static Game? unequipFromGpu(Game game, String gpuId, String type) {
    final gpuIdx = game.farm.gpuList.indexWhere((g) => g.id == gpuId);
    if (gpuIdx == -1) return null;
    final gpu = game.farm.gpuList[gpuIdx];

    final invIdx = game.inventory.indexWhere(
      (i) => i.equippedToGpu == gpuId && i.type == type,
    );
    if (invIdx == -1) return null;

    final newGpu = switch (type) {
      'cooling' => gpu.copyWith(equippedCooling: null),
      'psu' => gpu.copyWith(equippedPsu: null),
      'paste' => gpu.copyWith(equippedPaste: null),
      'bios' => gpu.copyWith(equippedBios: null),
      _ => null,
    };
    if (newGpu == null) return null;

    final newInventory = [...game.inventory];
    final oldItem = game.inventory[invIdx];
    newInventory[invIdx] = InventoryItem(
      id: oldItem.id,
      itemId: oldItem.itemId,
      type: oldItem.type,
      name: oldItem.name,
      detail: oldItem.detail,
      equippedToGpu: null,
      data: oldItem.data,
    );
    final newGpus = [...game.farm.gpuList];
    newGpus[gpuIdx] = newGpu;

    return game.copyWith(
      inventory: newInventory,
      farm: game.farm.copyWith(gpuList: newGpus),
    );
  }

  static Game? useMotherboard(Game game, String inventoryItemId) {
    final invIdx = game.inventory.indexWhere((i) => i.id == inventoryItemId);
    if (invIdx == -1) return null;
    final item = game.inventory[invIdx];
    if (item.type != 'motherboard') return null;

    final moboSlots = switch (item.itemId) {
      'mobo_1' => 1,
      'mobo_2' => 2,
      'mobo_4' => 4,
      'mobo_8' => 8,
      _ => 0,
    };
    if (moboSlots <= 0) return null;

    final newInventory = [...game.inventory];
    newInventory.removeAt(invIdx);

    return game.copyWith(
      inventory: newInventory,
      farm: game.farm.copyWith(totalSlots: game.farm.totalSlots + moboSlots),
    );
  }

  // ── Equipped upgrade ──

  static int upgradeCost(Game game, String gpuId, String type) {
    final gpu = game.farm.gpuList.where((g) => g.id == gpuId).firstOrNull;
    if (gpu == null) return 0;
    switch (type) {
      case 'cooling':
        final currentId = gpu.equippedCooling ?? 'basic';
        final fromIdx = CoolingCatalog.indexOf(currentId);
        return CoolingCatalog.upgradeCost(fromIdx, fromIdx + 1);
      case 'psu':
        final currentId = gpu.equippedPsu ?? 'psu_stock';
        final fromIdx = PsuCatalog.indexOf(currentId);
        return PsuCatalog.upgradeCost(fromIdx, fromIdx + 1);
      case 'paste':
        final currentId = gpu.equippedPaste ?? 'paste_none';
        final fromIdx = PasteCatalog.indexOf(currentId);
        return PasteCatalog.upgradeCost(fromIdx, fromIdx + 1);
      case 'gpu':
        final fromIdx = GpuCatalog.indexOf(gpu.modelId);
        return GpuCatalog.upgradeCost(fromIdx, fromIdx + 1);
      default:
        return 0;
    }
  }

  static String? nextTierName(Game game, String gpuId, String type) {
    final gpu = game.farm.gpuList.where((g) => g.id == gpuId).firstOrNull;
    if (gpu == null) return null;
    switch (type) {
      case 'cooling':
        final currentId = gpu.equippedCooling ?? 'basic';
        final idx = CoolingCatalog.indexOf(currentId);
        return CoolingCatalog.all.length > idx + 1
            ? CoolingCatalog.all[idx + 1].name
            : null;
      case 'psu':
        final currentId = gpu.equippedPsu ?? 'psu_stock';
        final idx = PsuCatalog.indexOf(currentId);
        return PsuCatalog.all.length > idx + 1
            ? PsuCatalog.all[idx + 1].name
            : null;
      case 'paste':
        final currentId = gpu.equippedPaste ?? 'paste_none';
        final idx = PasteCatalog.indexOf(currentId);
        return PasteCatalog.all.length > idx + 1
            ? PasteCatalog.all[idx + 1].name
            : null;
      case 'gpu':
        final idx = GpuCatalog.indexOf(gpu.modelId);
        return GpuCatalog.all.length > idx + 1
            ? GpuCatalog.all[idx + 1].name
            : null;
      default:
        return null;
    }
  }

  static Game? upgradeEquipped(Game game, String gpuId, String type) {
    final cost = upgradeCost(game, gpuId, type);
    if (cost <= 0 || game.money < cost) return null;
    final gpuIdx = game.farm.gpuList.indexWhere((g) => g.id == gpuId);
    if (gpuIdx < 0) return null;
    final gpu = game.farm.gpuList[gpuIdx];

    var g = game;
    final newGpus = [...g.farm.gpuList];

    switch (type) {
      case 'cooling':
        final currentId = gpu.equippedCooling ?? 'basic';
        final idx = CoolingCatalog.indexOf(currentId);
        final next = CoolingCatalog.all[idx + 1];
        g = _removeEquipped(g, gpuId, 'cooling');
        g = g.copyWith(
          inventory: [
            ...g.inventory,
            _equippedInv(
              'cooling',
              next.id,
              next.name,
              '${next.tempReduction}°C',
              gpuId,
            ),
          ],
        );
        newGpus[gpuIdx] = gpu.copyWith(equippedCooling: next.id);
        break;
      case 'psu':
        final currentId = gpu.equippedPsu ?? 'psu_stock';
        final idx = PsuCatalog.indexOf(currentId);
        final next = PsuCatalog.all[idx + 1];
        g = _removeEquipped(g, gpuId, 'psu');
        g = g.copyWith(
          inventory: [
            ...g.inventory,
            _equippedInv(
              'psu',
              next.id,
              next.name,
              '${next.maxWattPerGpu}W',
              gpuId,
            ),
          ],
        );
        newGpus[gpuIdx] = gpu.copyWith(equippedPsu: next.id);
        break;
      case 'paste':
        final currentId = gpu.equippedPaste ?? 'paste_none';
        final idx = PasteCatalog.indexOf(currentId);
        final next = PasteCatalog.all[idx + 1];
        g = _removeEquipped(g, gpuId, 'paste');
        g = g.copyWith(
          inventory: [
            ...g.inventory,
            _equippedInv(
              'paste',
              next.id,
              next.name,
              '${next.tempReduction}°C',
              gpuId,
            ),
          ],
        );
        newGpus[gpuIdx] = gpu.copyWith(equippedPaste: next.id);
        break;
      case 'gpu':
        final idx = GpuCatalog.indexOf(gpu.modelId);
        final next = GpuCatalog.all[idx + 1];
        newGpus[gpuIdx] = gpu.copyWith(
          modelId: next.id,
          temperature: next.baseTemperature,
        );
        break;
      default:
        return null;
    }

    return g.copyWith(
      money: g.money - cost,
      farm: g.farm.copyWith(gpuList: newGpus),
    );
  }

  // ── Helpers ──

  static Game _removeEquipped(Game game, String gpuId, String type) {
    final idx = game.inventory.indexWhere(
      (i) => i.equippedToGpu == gpuId && i.type == type,
    );
    if (idx >= 0) {
      final newInv = [...game.inventory];
      newInv.removeAt(idx);
      return game.copyWith(inventory: newInv);
    }
    return game;
  }

  static InventoryItem _equippedInv(
    String type,
    String itemId,
    String name,
    String detail,
    String gpuId,
  ) {
    return InventoryItem(
      id: _farmUuid.v4(),
      itemId: itemId,
      type: type,
      name: name,
      detail: detail,
      equippedToGpu: gpuId,
    );
  }

  static InventoryItem _inv(
    String type,
    String itemId,
    String name,
    String detail,
  ) {
    return InventoryItem(
      id: _farmUuid.v4(),
      itemId: itemId,
      type: type,
      name: name,
      detail: detail,
    );
  }
}
