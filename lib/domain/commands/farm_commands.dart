import '../catalogs/cooling_catalog.dart';
import '../catalogs/psu_catalog.dart';
import '../catalogs/slot_catalog.dart';
import '../catalogs/solar_catalog.dart';
import '../config/game_config.dart';
import '../models/game.dart';

/// Pure functions for farm operations: slots, cooling, solar, PSU.
class FarmCommands {
  FarmCommands._();

  // ── Motherboard (slots) ──

  static Game? buySlotTier(Game game, SlotTier tier) {
    final price = GameConfig.applyShopDiscount(tier.price, game.shopMultiplier);
    if (game.money < price) return null;
    return game.copyWith(
      money: game.money - price,
      farm: game.farm.copyWith(totalSlots: game.farm.totalSlots + tier.slots),
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

  // ── Solar Panels ──

  static Game? buySolar(Game game, SolarUpgrade upgrade) {
    final price = GameConfig.applyShopDiscount(
      upgrade.price,
      game.shopMultiplier,
    );
    if (game.money < price) return null;
    return game.copyWith(
      money: game.money - price,
      farm: game.farm.copyWith(
        solarPower: game.farm.solarPower + upgrade.powerGen,
      ),
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
    return CoolingCatalog.upgradeCost(idx, idx + 1);
  }

  static String? nextCoolingName(Game game) {
    final idx = CoolingCatalog.indexOf(game.farm.coolingSystem);
    return CoolingCatalog.all.length > idx + 1
        ? CoolingCatalog.all[idx + 1].name
        : null;
  }

  static int psuUpgradeCost(Game game) {
    final idx = PsuCatalog.indexOf(game.farm.psuTier);
    return PsuCatalog.upgradeCost(idx, idx + 1);
  }

  static String? nextPsuName(Game game) {
    final idx = PsuCatalog.indexOf(game.farm.psuTier);
    return PsuCatalog.all.length > idx + 1
        ? PsuCatalog.all[idx + 1].name
        : null;
  }
}
