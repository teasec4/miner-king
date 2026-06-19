import 'package:crypto_king/data/game_state.dart';
import 'package:crypto_king/domain/catalogs/gpu_catalog.dart';
import 'package:crypto_king/domain/systems/economy_system.dart';
import 'package:crypto_king/domain/systems/mining_system.dart';
import 'package:crypto_king/domain/systems/tick_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameState', () {
    test('initial state has correct values', () {
      final state = GameState();
      final game = state.game;

      expect(game.money, 1000);
      expect(game.coins, 0);
      expect(game.coinPrice, 42500.0);
      expect(game.farm.gpuList.length, 1);
      expect(game.farm.totalSlots, 1);
      expect(game.farm.gpuList.first.modelId, GpuCatalog.gtx1060.id);
    });
  });

  group('TickSystem', () {
    test('tick increases coins and tick counter', () {
      final state = GameState();
      final game = TickSystem.tick(state.game);

      expect(game.coins, greaterThan(0));
      expect(game.tick, 1);
    });
  });

  group('EconomySystem', () {
    test('sellAllCoins converts coins to money', () {
      final state = GameState();
      // Mine some coins first
      var game = state.game;
      for (var i = 0; i < 100; i++) {
        game = TickSystem.tick(game);
      }

      expect(game.coins, greaterThan(0));
      final coinsBefore = game.coins;
      final result = EconomySystem.sellAllCoins(game);

      expect(result.coins, 0);
      expect(result.money, game.money + coinsBefore * game.coinPrice);
    });
  });

  group('MiningSystem', () {
    test('totalHashrate is positive with GPU installed', () {
      final state = GameState();
      final hashrate = MiningSystem.totalHashrate(state.game);
      expect(hashrate, greaterThan(0));
    });

    test('mine returns positive coins per tick', () {
      final state = GameState();
      final coins = MiningSystem.mine(state.game);
      expect(coins, greaterThan(0));
    });
  });

  group('GpuCatalog', () {
    test('catalog has GPUs', () {
      expect(GpuCatalog.all.length, 4);
    });

    test('byId returns correct GPU', () {
      final gpu = GpuCatalog.byId('gtx_1060');
      expect(gpu, isNotNull);
      expect(gpu!.name, 'GTX 1060');
    });
  });
}
