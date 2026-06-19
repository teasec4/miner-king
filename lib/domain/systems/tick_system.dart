import '../models/game.dart';
import 'mining_system.dart';

/// Main game loop – advances the simulation by one tick.
/// Stateless: takes Game, returns new Game.
class TickSystem {
  TickSystem._();

  static Game tick(Game game) {
    final coinsMined = MiningSystem.mine(game);

    return game.copyWith(coins: game.coins + coinsMined, tick: game.tick + 1);
  }
}
