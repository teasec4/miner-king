import 'package:crypto_king/data/game_state.dart';
import 'package:crypto_king/domain/catalogs/coin_catalog.dart';
import 'package:crypto_king/domain/catalogs/gpu_catalog.dart';
import 'package:crypto_king/domain/catalogs/slot_catalog.dart';
import 'package:crypto_king/domain/systems/economy_system.dart';
import 'package:crypto_king/domain/systems/electricity_system.dart';
import 'package:crypto_king/domain/systems/market_system.dart';
import 'package:crypto_king/domain/systems/mining_system.dart';
import 'package:crypto_king/domain/systems/systems.dart';
import 'package:crypto_king/domain/systems/thermal_system.dart';
import 'package:crypto_king/domain/systems/tick_system.dart';
import 'package:crypto_king/domain/systems/wear_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameState', () {
    test('initial state has correct values', () {
      final state = GameState();
      final game = state.game;
      expect(game.money, 500);
      expect(game.holdings['btc'], 0);
      expect(game.holdings['eth'], 0);
      expect(game.holdings['sol'], 0);
      expect(game.holdings['doge'], 0);
      expect(game.holdings['pepe'], 0);
      expect(game.holdings['usdt'], 0);
      expect(game.coins.length, 6);
      expect(game.primaryCoin.price, 10.0);
      expect(game.electricityRate, 0.25);
      expect(game.farm.gpuList.length, 1);
      expect(game.farm.gpuList.first.condition, 0.5);
      expect(game.activeJobId, 'food_l1');
      expect(game.farm.totalSlots, 1);
    });
  });

  group('TickSystem', () {
    test('tick increases holdings and tick counter after cycles', () {
      final state = GameState();
      var game = state.game;
      game = game.copyWith(activeJobId: null);
      final ticker = TickSystem(Systems());
      for (int i = 0; i < 20; i++) {
        (game, _) = ticker.tick(game);
      }
      expect(game.holdings['btc']!, greaterThan(0));
      expect(game.tick, 20);
    });
  });

  group('ThermalSystem', () {
    test('temperatures use model base temp + worn bonus', () {
      final state = GameState();
      final game = ThermalSystem.update(state.game);
      expect(game.farm.gpuList.first.temperature, 55.0);
    });
    test('worn card runs hotter', () {
      final state = GameState();
      var game = state.game;
      final gpu = game.farm.gpuList.first.copyWith(condition: 0.5);
      game = game.copyWith(farm: game.farm.copyWith(gpuList: [gpu]));
      game = ThermalSystem.update(game);
      expect(game.farm.gpuList.first.temperature, 55.0);
    });
    test('status returns correct values', () {
      expect(ThermalSystem.status(50), 'normal');
      expect(ThermalSystem.status(70), 'warning');
      expect(ThermalSystem.status(95), 'critical');
    });
  });

  group('WearSystem', () {
    test('no wear below 50°C', () {
      final state = GameState();
      var game = state.game;
      final gpu = game.farm.gpuList.first.copyWith(
        temperature: 45,
        condition: 1.0,
      );
      game = game.copyWith(farm: game.farm.copyWith(gpuList: [gpu]));
      final wear = DefaultWearSystem();
      game = wear.update(game);
      expect(game.farm.gpuList.first.condition, 1.0);
    });
    test('wear at 70°C', () {
      final state = GameState();
      var game = state.game;
      final gpu = game.farm.gpuList.first.copyWith(
        condition: 1.0,
        temperature: 70,
      );
      game = game.copyWith(farm: game.farm.copyWith(gpuList: [gpu]));
      final wear = DefaultWearSystem();
      for (var i = 0; i < 100; i++) {
        game = wear.update(game);
      }
      expect(game.farm.gpuList.first.condition, closeTo(0.95, 0.005));
    });
  });

  group('ElectricitySystem', () {
    test('totalPowerDraw is correct', () {
      final state = GameState();
      expect(ElectricitySystem.totalPowerDraw(state.game), 120.0);
    });
    test('costPerHour uses game formula', () {
      final state = GameState();
      expect(ElectricitySystem.costPerHour(state.game), closeTo(30.0, 0.01));
    });
  });

  group('EconomySystem', () {
    test('sellCoin converts coins to money', () {
      final state = GameState();
      var game = state.game;
      game = game.copyWith(activeJobId: null);
      final ticker = TickSystem(Systems());
      for (var i = 0; i < 50; i++) {
        (game, _) = ticker.tick(game);
      }
      final btcBefore = game.holdings['btc']!;
      expect(btcBefore, greaterThan(0));
      final btcPrice = game.coin('btc')!.price;
      final result = EconomySystem.sellCoin(game, 'btc');
      expect(result.holdings['btc'], 0);
      expect(result.money, closeTo(game.money + btcBefore * btcPrice, 0.01));
    });
  });

  group('MiningSystem', () {
    test('totalHashrate scales with condition', () {
      final state = GameState();
      var game = state.game;
      var gpu = game.farm.gpuList.first.copyWith(condition: 1.0);
      game = game.copyWith(farm: game.farm.copyWith(gpuList: [gpu]));
      final full = MiningSystem.totalHashrate(game);
      gpu = gpu.copyWith(condition: 0.5);
      game = game.copyWith(farm: game.farm.copyWith(gpuList: [gpu]));
      expect(MiningSystem.totalHashrate(game), closeTo(full * 0.5, 0.1));
    });
    test('mine returns per-coin map after enough ticks', () {
      final state = GameState();
      var game = state.game;
      for (int i = 0; i < 14; i++) {
        final (gpus, mined) = MiningSystem.mine(game);
        if (mined.isNotEmpty) {
          expect(mined.containsKey('btc'), true);
          expect(mined['btc']!, greaterThan(0));
          return;
        }
        game = game.copyWith(farm: game.farm.copyWith(gpuList: gpus));
      }
    });
  });

  group('GpuCatalog', () {
    test('catalog has GPUs', () => expect(GpuCatalog.all.length, 4));
    test('byId returns correct GPU', () {
      final gpu = GpuCatalog.byId('gtx_1060');
      expect(gpu!.name, 'GTX 1060');
    });
  });

  group('SlotCatalog', () {
    test('nextTier returns correct tier', () {
      expect(SlotCatalog.nextTier(1)?.slots, 2);
      expect(SlotCatalog.nextTier(2)?.slots, 4);
      expect(SlotCatalog.nextTier(12), null);
    });
  });

  group('MarketSystem', () {
    test('price stays within bounds', () {
      final state = GameState();
      var game = state.game;
      final market = DefaultMarketSystem();
      for (var i = 0; i < 1000; i++) {
        game = market.update(game);
      }
      for (final c in game.coins) {
        expect(c.price, greaterThanOrEqualTo(0.01));
        expect(c.price, lessThanOrEqualTo(10000.0));
      }
    });
    test('tick includes market update', () {
      final state = GameState();
      var game = state.game;
      game = game.copyWith(activeJobId: null);
      final ticker = TickSystem(Systems());
      for (var i = 0; i < 500; i++) {
        (game, _) = ticker.tick(game);
      }
      expect(game.primaryCoin.price, isNot(10.0));
    });
  });

  group('CoinCatalog', () {
    test('has 6 coins', () => expect(CoinCatalog.all.length, 6));
    test('BTC has standard reward', () {
      expect(CoinCatalog.btc.baseReward, 1.0);
    });
    test('DOGE has high volatility', () {
      expect(CoinCatalog.doge.volatility, greaterThan(2.0));
    });
    test('ETH is easier to mine', () {
      expect(CoinCatalog.eth.baseReward, greaterThan(1.0));
    });
  });
}
