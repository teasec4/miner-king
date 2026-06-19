import 'dart:math';
import 'package:crypto_king/data/game_state.dart';
import 'package:crypto_king/domain/models/coin_state.dart';
import 'package:crypto_king/domain/models/market_phase.dart';
import 'package:crypto_king/domain/systems/market_system.dart';
import 'package:crypto_king/presentation/viewmodels/game_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class MarketPage extends StatelessWidget {
  const MarketPage({super.key});
  @override
  Widget build(BuildContext context) {
    final vm = GameViewModel(context.watch<GameState>());
    return Scaffold(
      appBar: AppBar(title: const Text('Market'), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _moodGauge(vm.marketMood),
            const SizedBox(height: 12),
            ...vm.coins.map((c) => _coinCard(c)),
            const SizedBox(height: 12),
            _swapCard(context),
            const SizedBox(height: 12),
            _newsSection(vm),
          ],
        ),
      ),
    );
  }

  Widget _moodGauge(double mood) {
    final label = MarketSystem.moodLabel(mood);
    final c = mood > 0.2
        ? Colors.green
        : mood < -0.2
        ? Colors.red
        : Colors.blueGrey;
    final bg = mood > 0.2
        ? Colors.green.shade50
        : mood < -0.2
        ? Colors.red.shade50
        : Colors.blueGrey.shade50;
    return Card(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Market Mood',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: c,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (mood + 1) / 2,
                minHeight: 10,
                backgroundColor: Colors.white38,
                valueColor: AlwaysStoppedAnimation(c),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Fear',
                  style: TextStyle(fontSize: 10, color: Colors.red.shade400),
                ),
                const Spacer(),
                Text(
                  '${((mood + 1) / 2 * 100).toInt()}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const Spacer(),
                Text(
                  'Greed',
                  style: TextStyle(fontSize: 10, color: Colors.green.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _coinCard(CoinState coin) {
    final c = switch (coin.phase) {
      MarketPhase.bull => Colors.green,
      MarketPhase.bear => Colors.red,
      _ => Colors.grey,
    };
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: c.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  coin.name[0],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: c,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        coin.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${MarketSystem.phaseIcon(coin.phase)} ${MarketSystem.phaseLabel(coin.phase)}',
                        style: TextStyle(fontSize: 13, color: c),
                      ),
                    ],
                  ),
                  Text(
                    'Mine: ${coin.baseReward}x  Vol: ${(coin.volatility * 100).toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Text(
              '\$${coin.price.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _swapCard(BuildContext context) => Card(
    child: InkWell(
      onTap: () async {
        final r = await context.push('/home/swap');
        if (r != null && context.mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$r'), duration: const Duration(seconds: 2)),
          );
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.swap_horiz, color: Colors.blue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Swap Coins',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    'Exchange at market rate. 1% fee.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    ),
  );

  Widget _newsSection(GameViewModel vm) {
    final msgs = _news(vm);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Market News',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        ...msgs.map(
          (m) => Card(
            margin: const EdgeInsets.symmetric(vertical: 3),
            color: m.g
                ? Colors.green.shade50
                : m.b
                ? Colors.red.shade50
                : null,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(m.icon, size: 18, color: m.c),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(m.t, style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<_N> _news(GameViewModel vm) {
    final msgs = <_N>[];
    final rng = Random(vm.tick);
    for (final coin in vm.coins) {
      if (coin.phaseTicksLeft < 30) {
        msgs.add(
          _N(
            Icons.warning_amber,
            Colors.orange,
            '${coin.name} phase may change soon',
          ),
        );
      }
      if (coin.phase == MarketPhase.bear && coin.volatility > 1.5) {
        msgs.add(
          _N(
            Icons.trending_down,
            Colors.red,
            '${coin.name} high vol + bear',
            b: true,
          ),
        );
      }
      if (coin.phase == MarketPhase.bull &&
          coin.volatility > 1.5 &&
          coin.price > 3) {
        msgs.add(
          _N(
            Icons.trending_up,
            Colors.green,
            '${coin.name} pumping! \$${coin.price.toStringAsFixed(2)}',
            g: true,
          ),
        );
      }
      if (coin.price > 50) {
        msgs.add(
          _N(
            Icons.monetization_on,
            Colors.amber,
            '${coin.name} ATH \$${coin.price.toStringAsFixed(2)}',
            g: true,
          ),
        );
      }
      if (coin.price < coin.volatility * 0.5 && coin.price > 0) {
        msgs.add(
          _N(
            Icons.discount,
            Colors.orange,
            '${coin.name} cheap \$${coin.price.toStringAsFixed(2)}',
          ),
        );
      }
    }
    if (rng.nextDouble() < 0.3) {
      msgs.add(
        _N(Icons.lightbulb, Colors.amber, 'Tip: diversify GPUs across coins'),
      );
    }
    if (msgs.isEmpty) {
      msgs.add(_N(Icons.check_circle, Colors.grey, 'Market is calm'));
    }
    return msgs.take(5).toList();
  }
}

class _N {
  final IconData icon;
  final Color c;
  final String t;
  final bool g;
  final bool b;
  _N(this.icon, this.c, this.t, {this.g = false, this.b = false});
}
