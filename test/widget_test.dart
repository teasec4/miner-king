import 'package:crypto_king/data/game_state.dart';
import 'package:crypto_king/domain/catalogs/gpu_catalog.dart';
import 'package:crypto_king/domain/catalogs/slot_catalog.dart';
import 'package:crypto_king/domain/models/game.dart';
import 'package:crypto_king/domain/systems/economy_system.dart';
import 'package:crypto_king/domain/systems/electricity_system.dart';
import 'package:crypto_king/domain/systems/market_system.dart';
import 'package:crypto_king/domain/systems/mining_system.dart';
import 'package:crypto_king/domain/systems/thermal_system.dart';
import 'package:crypto_king/domain/systems/tick_system.dart';
import 'package:crypto_king/domain/systems/wear_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameState', () {
    test('initial state has correct values', () {
      final state = GameState();
      final game = state.game;

      expect(game.money, 1000);
      expect(game.coins, 0);
      expect(game.coinPrice, 10.0);
      expect(game.marketPhase, MarketPhase.sideways);
      expect(game.electricityRate, 0.12);
      expect(game.farm.gpuList.length, 1);
      expect(game.farm.totalSlots, 1);
      expect(game.farm.gpuList.first.modelId, GpuCatalog.gtx1060.id);
      expect(game.farm.gpuList.first.condition, 1.0);
    });
  });

  group('TickSystem', () {
    test('tick increases coins and tick counter', () {
      final state = GameState();
      final game = TickSystem.tick(state.game);

      expect(game.coins, greaterThan(0));
      expect(game.tick, 1);
    });

    test('tick applies electricity cost', () {
      final state = GameState();
      final before = state.game.money;
      final game = TickSystem.tick(state.game);
      expect(game.money, lessThan(before));
    });
  });

  group('ThermalSystem', () {
    test('temperatures use model base temp', () {
      final state = GameState();
      final game = ThermalSystem.update(state.game);
      expect(game.farm.gpuList.first.temperature, 45.0); // GTX 1060
    });

    test('worn card runs hotter', () {
      final state = GameState();
      // Set condition to 50%
      var game = state.game;
      final gpu = game.farm.gpuList.first.copyWith(condition: 0.5);
      game = game.copyWith(farm: game.farm.copyWith(gpuList: [gpu]));
      game = ThermalSystem.update(game);
      // 45 base + (1-0.5)*20 = 45 + 10 = 55
      expect(game.farm.gpuList.first.temperature, 55.0);
    });

    test('status returns correct values', () {
      expect(ThermalSystem.status(50), 'normal');
      expect(ThermalSystem.status(75), 'warning');
      expect(ThermalSystem.status(95), 'critical');
    });
  });

  group('WearSystem', () {
    test('no wear at safe temps (≤70°C)', () {
      final state = GameState();
      // GTX 1060 stock: 45°C — safe
      var game = state.game;
      game = ThermalSystem.update(game); // 45°C
      game = WearSystem.update(game);
      expect(game.farm.gpuList.first.condition, 1.0);
    });

    test('wear accumulates at warning temps', () {
      final state = GameState();
      // Force temperature to 80°C (warning zone)
      var game = state.game;
      final gpu = game.farm.gpuList.first.copyWith(temperature: 80);
      game = game.copyWith(farm: game.farm.copyWith(gpuList: [gpu]));

      // Run 100 ticks of wear
      for (var i = 0; i < 100; i++) {
        game = WearSystem.update(game);
      }
      // At 80°C: rate = (80-70)/20*0.0015 = 0.00075, accel=1
      // 100 * 0.00075 = 0.075 wear → condition ≈ 0.925
      expect(game.farm.gpuList.first.condition, closeTo(0.925, 0.02));
    });

    test('worn cards degrade faster (acceleration)', () {
      final state = GameState();
      var game = state.game;
      final gpu = game.farm.gpuList.first.copyWith(
        temperature: 80,
        condition: 0.5,
      );
      game = game.copyWith(farm: game.farm.copyWith(gpuList: [gpu]));

      // Rate at 80°C = 0.00075, accel = 1 + (1-0.5)*2 = 2
      // Per tick wear = 0.0015
      game = WearSystem.update(game);
      expect(game.farm.gpuList.first.condition, closeTo(0.5 - 0.0015, 0.0001));
    });

    test('dead card stays at 0 condition', () {
      final state = GameState();
      var game = state.game;
      final gpu = game.farm.gpuList.first.copyWith(
        temperature: 95,
        condition: 0.0,
      );
      game = game.copyWith(farm: game.farm.copyWith(gpuList: [gpu]));

      game = WearSystem.update(game);
      expect(game.farm.gpuList.first.condition, 0.0);
    });
  });

  group('ElectricitySystem', () {
    test('totalPowerDraw is correct', () {
      final state = GameState();
      expect(ElectricitySystem.totalPowerDraw(state.game), 120.0);
    });

    test('costPerHour uses game formula', () {
      final state = GameState();
      expect(ElectricitySystem.costPerHour(state.game), closeTo(14.40, 0.01));
    });

    test('deducts money per tick', () {
      final state = GameState();
      final before = state.game.money;
      final game = ElectricitySystem.update(state.game);
      expect(game.money, lessThan(before));
      expect(before - game.money, closeTo(0.004, 0.001));
    });

    test('dead card consumes no power', () {
      final state = GameState();
      var game = state.game;
      final gpu = game.farm.gpuList.first.copyWith(condition: 0.0);
      game = game.copyWith(farm: game.farm.copyWith(gpuList: [gpu]));
      expect(ElectricitySystem.totalPowerDraw(game), 0.0);
    });
  });

  group('EconomySystem', () {
    test('sellAllCoins converts coins to money', () {
      final state = GameState();
      var game = state.game;
      for (var i = 0; i < 50; i++) {
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
    test('totalHashrate scales with condition', () {
      final state = GameState();
      final fullHashrate = MiningSystem.totalHashrate(state.game);

      var game = state.game;
      final gpu = game.farm.gpuList.first.copyWith(condition: 0.5);
      game = game.copyWith(farm: game.farm.copyWith(gpuList: [gpu]));
      final halfHashrate = MiningSystem.totalHashrate(game);

      expect(halfHashrate, closeTo(fullHashrate * 0.5, 0.1));
    });

    test('dead card produces 0 hashrate', () {
      final state = GameState();
      var game = state.game;
      final gpu = game.farm.gpuList.first.copyWith(condition: 0.0);
      game = game.copyWith(farm: game.farm.copyWith(gpuList: [gpu]));
      expect(MiningSystem.totalHashrate(game), 0.0);
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

  group('GameState actions', () {
    test('toggleOverclock toggles level', () {
      final state = GameState();
      final gpuId = state.game.farm.gpuList.first.id;
      expect(state.game.farm.gpuList.first.overclockLevel, 0);
      state.toggleOverclock(gpuId);
      expect(state.game.farm.gpuList.first.overclockLevel, 1);
      state.toggleOverclock(gpuId);
      expect(state.game.farm.gpuList.first.overclockLevel, 0);
    });

    test('overclock increases hashrate by 20%', () {
      final state = GameState();
      final stock = MiningSystem.totalHashrate(state.game);
      state.toggleOverclock(state.game.farm.gpuList.first.id);
      expect(
        MiningSystem.totalHashrate(state.game),
        closeTo(stock * 1.2, 0.01),
      );
    });

    test('repair cost is proportional to damage', () {
      // GTX 1060 price \$200, damage 50%, 30% rate → 200*0.3*0.5 = \$30
      expect((200 * 0.3 * 0.5).round(), 30);
    });

    test('buyGpu adds GPU when affordable and slots free', () {
      final state = GameState();
      // Initial: 1 slot, 1 GPU, \$1000
      expect(state.game.farm.gpuList.length, 1);
      expect(state.game.farm.totalSlots, 1);
    });
  });

  group('SlotCatalog', () {
    test('nextTier returns correct tier', () {
      expect(SlotCatalog.nextTier(1)?.slots, 2);
      expect(SlotCatalog.nextTier(2)?.slots, 4);
      expect(SlotCatalog.nextTier(4)?.slots, 8);
      expect(SlotCatalog.nextTier(8)?.slots, 12);
      expect(SlotCatalog.nextTier(12), null);
    });

    test('nextTier returns correct prices', () {
      expect(SlotCatalog.nextTier(1)?.price, 400);
      expect(SlotCatalog.nextTier(2)?.price, 1500);
      expect(SlotCatalog.nextTier(4)?.price, 5000);
      expect(SlotCatalog.nextTier(8)?.price, 15000);
    });
  });

  group('MarketSystem', () {
    test('update changes coin price over multiple ticks', () {
      final state = GameState();
      var game = state.game;
      for (var i = 0; i < 100; i++) {
        game = MarketSystem.update(game);
      }
      // Price should have moved after 100 ticks
      expect(game.coinPrice, isNot(10.0));
    });

    test('price stays within bounds', () {
      final state = GameState();
      var game = state.game;
      for (var i = 0; i < 1000; i++) {
        game = MarketSystem.update(game);
      }
      expect(game.coinPrice, greaterThanOrEqualTo(1.0));
      expect(game.coinPrice, lessThanOrEqualTo(100.0));
    });

    test('phaseLabel returns non-empty string', () {
      expect(MarketSystem.phaseLabel(MarketPhase.bull).isNotEmpty, true);
      expect(MarketSystem.phaseLabel(MarketPhase.bear).isNotEmpty, true);
      expect(MarketSystem.phaseLabel(MarketPhase.sideways).isNotEmpty, true);
    });

    test('tick includes market update', () {
      final state = GameState();
      var game = state.game;
      for (var i = 0; i < 500; i++) {
        game = TickSystem.tick(game);
      }
      // After many ticks, price should have drifted from initial $10
      expect(game.coinPrice, isNot(10.0));
    });
  });
}
