import 'package:crypto_king/data/game_state.dart';
import 'package:crypto_king/domain/models/market_phase.dart';
import 'package:crypto_king/domain/systems/market_system.dart';
import 'package:crypto_king/presentation/viewmodels/game_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final vm = GameViewModel(game);

    return Scaffold(
      appBar: AppBar(title: const Text('Wallet'), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // ── Total ──
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Text(
                    '\$${vm.totalHoldingsValue.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Cash',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      Text(
                        '\$${vm.money.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // ── Coin rows ──
            ...vm.coins.map((coin) {
              final amount = vm.holding(coin.id);
              final value = vm.holdingValue(coin.id);
              final pct = vm.totalHoldingsValue > 0
                  ? (value / vm.totalHoldingsValue * 100).toStringAsFixed(1)
                  : '0.0';
              final phaseColor = switch (coin.phase) {
                MarketPhase.bull => Colors.green,
                MarketPhase.bear => Colors.red,
                _ => Colors.grey,
              };

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      // Coin icon
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: phaseColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            coin.name[0],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: phaseColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Name + price
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  coin.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${MarketSystem.phaseIcon(coin.phase)}\$${coin.price.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: phaseColor,
                                  ),
                                ),
                              ],
                            ),
                            if (amount > 0)
                              Text(
                                '${amount.toStringAsFixed(4)} ${coin.name}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Value + %
                      if (amount > 0)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${value.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '$pct%',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          '\$0.00',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      // Sell button
                      if (amount > 0) ...[
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 28,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              textStyle: const TextStyle(fontSize: 11),
                            ),
                            onPressed: () => vm.sellCoin(coin.id),
                            child: const Text('Sell'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 12),

            // ── Sell All ──
            if (vm.totalHoldingsValue > 0)
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.sell, size: 16),
                  label: Text(
                    'Sell All → \$${vm.totalHoldingsValue.toStringAsFixed(2)}',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => vm.sellAllCoins(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
