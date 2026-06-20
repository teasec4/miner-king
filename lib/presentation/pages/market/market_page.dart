import 'dart:math';
import 'package:crypto_king/data/game_state.dart';
import 'package:crypto_king/domain/models/coin_state.dart';
import 'package:crypto_king/domain/models/game_event.dart';
import 'package:crypto_king/domain/models/market_phase.dart';
import 'package:crypto_king/domain/systems/market_system.dart';
import 'package:crypto_king/presentation/viewmodels/game_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class MarketPage extends StatefulWidget {
  const MarketPage({super.key});
  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  GameEvent? _expandedEvent;

  @override
  Widget build(BuildContext context) {
    final vm = GameViewModel(context.watch<GameState>());
    final marketEvents = vm.activeEvents
        .where((e) => e.category == 'market')
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Market'), centerTitle: true),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _moodGauge(vm.marketMood),
                const SizedBox(height: 12),
                ...vm.coins.asMap().entries.map(
                  (e) => _coinCard(e.key, e.value, vm),
                ),
                const SizedBox(height: 12),
                _swapCard(context),
                const SizedBox(height: 12),
                _newsSection(vm),
              ],
            ),
            if (marketEvents.isNotEmpty) _eventOverlay(marketEvents),
          ],
        ),
      ),
    );
  }

  Widget _eventOverlay(List<GameEvent> events) => Positioned(
    bottom: 8,
    right: 8,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: events.map((e) {
        final open = _expandedEvent?.id == e.id;
        final isCrash = e.id == 'market_crash';
        final color = isCrash ? Colors.red.shade600 : Colors.green.shade600;
        final icon = isCrash ? Icons.trending_down : Icons.trending_up;
        return GestureDetector(
          onTap: () => setState(() => _expandedEvent = open ? null : e),
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.all(10),
            width: 190,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        e.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      e.durationTicks > 0 ? '${e.remainingTicks}s' : 'Now',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.topCenter,
                  child: open
                      ? Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.description,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                e.durationTicks > 0
                                    ? '\u23F1 ${e.remainingTicks}s remaining'
                                    : 'Instant effect',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    ),
  );

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

  Widget _coinCard(int idx, CoinState coin, GameViewModel vm) {
    final c = switch (coin.phase) {
      MarketPhase.bull => Colors.green,
      MarketPhase.bear => Colors.red,
      _ => Colors.grey,
    };
    final event = coin.eventImmune ? null : vm.eventForCoin(idx);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Stack(
        children: [
          Padding(
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
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${coin.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (event != null)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: event.id == 'market_crash'
                      ? Colors.red.shade600
                      : Colors.green.shade600,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  event.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _swapCard(BuildContext context) => Card(
    child: InkWell(
      onTap: () async {
        final r = await context.push('/home/swap');
        if (r != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$r'), duration: const Duration(seconds: 2)),
          );
        }
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
