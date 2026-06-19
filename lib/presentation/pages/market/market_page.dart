import 'dart:math';

import 'package:crypto_king/data/game_state.dart';
import 'package:crypto_king/domain/models/coin_state.dart';
import 'package:crypto_king/domain/models/market_phase.dart';
import 'package:crypto_king/domain/systems/market_system.dart';
import 'package:crypto_king/presentation/viewmodels/game_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MarketPage extends StatelessWidget {
  const MarketPage({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final vm = GameViewModel(game);

    return Scaffold(
      appBar: AppBar(title: const Text('Market'), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Coin price cards ──
            ...vm.coins.map((coin) => _coinPriceCard(coin, vm)),
            const SizedBox(height: 12),
            // ── News section ──
            _newsSection(vm),
          ],
        ),
      ),
    );
  }

  Widget _coinPriceCard(CoinState coin, GameViewModel vm) {
    final phaseColor = switch (coin.phase) {
      MarketPhase.bull => Colors.green,
      MarketPhase.bear => Colors.red,
      MarketPhase.sideways => Colors.grey,
    };
    final trend = switch (coin.phase) {
      MarketPhase.bull => 'Rising',
      MarketPhase.bear => 'Falling',
      MarketPhase.sideways => 'Stable',
    };

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: phaseColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      coin.name.substring(0, 1),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: phaseColor,
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
                            MarketSystem.phaseIcon(coin.phase),
                            style: TextStyle(fontSize: 13, color: phaseColor),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            trend,
                            style: TextStyle(fontSize: 11, color: phaseColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Mine: ${coin.baseReward}x  •  Vol: ${(coin.volatility * 100).toStringAsFixed(0)}%',
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
          ],
        ),
      ),
    );
  }

  Widget _newsSection(GameViewModel vm) {
    final messages = _generateNews(vm);

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
        ...messages.map(
          (msg) => Card(
            margin: const EdgeInsets.symmetric(vertical: 3),
            color: msg.isGood
                ? Colors.green.shade50
                : msg.isBad
                ? Colors.red.shade50
                : null,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(msg.icon, size: 18, color: msg.iconColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(msg.text, style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<_NewsMsg> _generateNews(GameViewModel vm) {
    final msgs = <_NewsMsg>[];
    final rng = Random(vm.tick); // seeded by tick for consistency

    for (final coin in vm.coins) {
      // Phase change alerts
      if (coin.phaseTicksLeft < 30) {
        msgs.add(
          _NewsMsg(
            icon: Icons.warning_amber,
            iconColor: Colors.orange,
            text: '${coin.name} market phase may change soon',
          ),
        );
      }

      // Volatility warnings
      if (coin.phase == MarketPhase.bear && coin.volatility > 1.5) {
        msgs.add(
          _NewsMsg(
            icon: Icons.trending_down,
            iconColor: Colors.red,
            isBad: true,
            text:
                '${coin.name} high volatility + bear market — consider switching mining',
          ),
        );
      }
      if (coin.phase == MarketPhase.bull &&
          coin.volatility > 1.5 &&
          coin.price > 3.0) {
        msgs.add(
          _NewsMsg(
            icon: Icons.trending_up,
            iconColor: Colors.green,
            isGood: true,
            text:
                '${coin.name} pumping! Price: \$${coin.price.toStringAsFixed(2)}',
          ),
        );
      }

      // Price extremes
      if (coin.price > 50) {
        msgs.add(
          _NewsMsg(
            icon: Icons.monetization_on,
            iconColor: Colors.amber,
            isGood: true,
            text:
                '${coin.name} at all-time high — \$${coin.price.toStringAsFixed(2)}!',
          ),
        );
      }
      if (coin.price < coin.volatility * 0.5 && coin.price > 0) {
        msgs.add(
          _NewsMsg(
            icon: Icons.discount,
            iconColor: Colors.orange,
            text:
                '${coin.name} is cheap — \$${coin.price.toStringAsFixed(2)}. Buying opportunity?',
          ),
        );
      }
    }

    // General tips
    if (rng.nextDouble() < 0.3) {
      msgs.add(
        _NewsMsg(
          icon: Icons.lightbulb,
          iconColor: Colors.amber,
          text:
              'Tip: diversify your GPUs across different coins to reduce risk.',
        ),
      );
    }
    if (rng.nextDouble() < 0.2) {
      msgs.add(
        _NewsMsg(
          icon: Icons.build,
          iconColor: Colors.blue,
          text: 'Tip: repair GPUs early — waiting makes it more expensive.',
        ),
      );
    }

    if (msgs.isEmpty) {
      msgs.add(
        _NewsMsg(
          icon: Icons.check_circle,
          iconColor: Colors.grey,
          text: 'Market is calm. No significant events at the moment.',
        ),
      );
    }

    return msgs.take(5).toList();
  }
}

class _NewsMsg {
  final IconData icon;
  final Color iconColor;
  final String text;
  final bool isGood;
  final bool isBad;

  _NewsMsg({
    required this.icon,
    required this.iconColor,
    required this.text,
    this.isGood = false,
    this.isBad = false,
  });
}
