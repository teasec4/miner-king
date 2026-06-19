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
    final game = context.watch<GameState>();
    final vm = GameViewModel(game);
    return Scaffold(
      appBar: AppBar(title: const Text('Market'), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ...vm.coins.map((c) => _coinPriceCard(c)),
            const SizedBox(height: 12),
            _swapCard(context),
            const SizedBox(height: 12),
            _newsSection(vm),
          ],
        ),
      ),
    );
  }

  Widget _swapCard(BuildContext context) => Card(
    child: InkWell(
      onTap: () async {
        final result = await context.push('/home/swap');
        if (result != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$result'),
              duration: const Duration(seconds: 2),
            ),
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
                  const SizedBox(height: 2),
                  Text(
                    'Exchange one coin for another at market rate. 1% fee.',
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

  Widget _coinPriceCard(CoinState coin) {
    final c = switch (coin.phase) {
      MarketPhase.bull => Colors.green,
      MarketPhase.bear => Colors.red,
      _ => Colors.grey,
    };
    final t = switch (coin.phase) {
      MarketPhase.bull => 'Rising',
      MarketPhase.bear => 'Falling',
      _ => 'Stable',
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
                        MarketSystem.phaseIcon(coin.phase),
                        style: TextStyle(fontSize: 13, color: c),
                      ),
                      const SizedBox(width: 4),
                      Text(t, style: TextStyle(fontSize: 11, color: c)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Mine: ${coin.baseReward}x  •  Vol: ${(coin.volatility * 100).toStringAsFixed(0)}%',
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

  Widget _newsSection(GameViewModel vm) {
    final msgs = _generateNews(vm);
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
            color: m.isGood
                ? Colors.green.shade50
                : m.isBad
                ? Colors.red.shade50
                : null,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(m.icon, size: 18, color: m.iconColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(m.text, style: const TextStyle(fontSize: 13)),
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
    final rng = Random(vm.tick);
    for (final coin in vm.coins) {
      if (coin.phaseTicksLeft < 30) {
        msgs.add(
          _NewsMsg(
            icon: Icons.warning_amber,
            iconColor: Colors.orange,
            text: '${coin.name} market phase may change soon',
          ),
        );
      }
      if (coin.phase == MarketPhase.bear && coin.volatility > 1.5) {
        msgs.add(
          _NewsMsg(
            icon: Icons.trending_down,
            iconColor: Colors.red,
            isBad: true,
            text: '${coin.name} high vol + bear — switch mining?',
          ),
        );
      }
      if (coin.phase == MarketPhase.bull &&
          coin.volatility > 1.5 &&
          coin.price > 3) {
        msgs.add(
          _NewsMsg(
            icon: Icons.trending_up,
            iconColor: Colors.green,
            isGood: true,
            text: '${coin.name} pumping! \$${coin.price.toStringAsFixed(2)}',
          ),
        );
      }
      if (coin.price > 50) {
        msgs.add(
          _NewsMsg(
            icon: Icons.monetization_on,
            iconColor: Colors.amber,
            isGood: true,
            text: '${coin.name} ATH — \$${coin.price.toStringAsFixed(2)}!',
          ),
        );
      }
      if (coin.price < coin.volatility * 0.5 && coin.price > 0) {
        msgs.add(
          _NewsMsg(
            icon: Icons.discount,
            iconColor: Colors.orange,
            text:
                '${coin.name} cheap — \$${coin.price.toStringAsFixed(2)}. Buy?',
          ),
        );
      }
    }
    if (rng.nextDouble() < 0.3) {
      msgs.add(
        _NewsMsg(
          icon: Icons.lightbulb,
          iconColor: Colors.amber,
          text: 'Tip: diversify GPUs across coins to reduce risk.',
        ),
      );
    }
    if (msgs.isEmpty) {
      msgs.add(
        _NewsMsg(
          icon: Icons.check_circle,
          iconColor: Colors.grey,
          text: 'Market is calm. No significant events.',
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
