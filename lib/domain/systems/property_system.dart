import '../catalogs/property_catalog.dart';
import '../models/game.dart';

class PropertySystem {
  PropertySystem._();

  static Game update(Game game) {
    if (game.properties.isEmpty) return game;
    var money = game.money;
    for (final pid in game.properties) {
      final p = PropertyCatalog.byId(pid);
      if (p != null) money += p.rentPerTick;
    }
    return game.copyWith(money: money);
  }
}
