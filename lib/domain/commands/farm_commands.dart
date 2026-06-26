import '../catalogs/cooling_catalog.dart';
import '../catalogs/psu_catalog.dart';
import '../catalogs/slot_catalog.dart';
import '../config/game_config.dart';
import '../models/game.dart';

/// Pure functions for farm operations: slots, cooling, PSU.
class FarmCommands {
  FarmCommands._();

  // ── Motherboard (+1 slot) ──

  static Game? buySlot(Game game) {
    if (!SlotCatalog.canBuyMore(game.farm.totalSlots)) return null;
    final price = GameConfig.applyShopDiscount(
      SlotCatalog.nextSlotCost(game.farm.totalSlots),
      game.shopMultiplier,
    );
    if (game.money < price) return null;
    return game.copyWith(
      money: game.money - price,
      farm: game.farm.copyWith(totalSlots: game.farm.totalSlots + 1),
    );
  }

  // ── Farm Cooling ──

  static Game? buyCooling(Game game, CoolingUpgrade upgrade) {
    final price = GameConfig.applyShopDiscount(
      upgrade.price,
      game.shopMultiplier,
    );
    if (game.money < price) return null;
    return game.copyWith(
      money: game.money - price,
      farm: game.farm.copyWith(coolingSystem: upgrade.id),
    );
  }

  // ── Farm PSU ──

  static Game? buyPsu(Game game, PsuUpgrade upgrade) {
    final price = GameConfig.applyShopDiscount(
      upgrade.price,
      game.shopMultiplier,
    );
    if (game.money < price) return null;
    return game.copyWith(
      money: game.money - price,
      farm: game.farm.copyWith(psuTier: upgrade.id),
    );
  }

  // ── Upgrade helpers (for UI) ──

  static int coolingUpgradeCost(Game game) {
    final idx = CoolingCatalog.indexOf(game.farm.coolingSystem);
    return GameConfig.applyShopDiscount(
      CoolingCatalog.upgradeCost(idx, idx + 1),
      game.shopMultiplier,
    );
  }

  static String? nextCoolingName(Game game) {
    final idx = CoolingCatalog.indexOf(game.farm.coolingSystem);
    return CoolingCatalog.all.length > idx + 1
        ? CoolingCatalog.all[idx + 1].name
        : null;
  }

  static int psuUpgradeCost(Game game) {
    final idx = PsuCatalog.indexOf(game.farm.psuTier);
    return GameConfig.applyShopDiscount(
      PsuCatalog.upgradeCost(idx, idx + 1),
      game.shopMultiplier,
    );
  }

  static String? nextPsuName(Game game) {
    final idx = PsuCatalog.indexOf(game.farm.psuTier);
    return PsuCatalog.all.length > idx + 1
        ? PsuCatalog.all[idx + 1].name
        : null;
  }
}
