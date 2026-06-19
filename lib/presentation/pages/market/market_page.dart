import 'package:crypto_king/data/game_state.dart';
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
            // ── Coin price card ──
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.currency_bitcoin,
                      size: 48,
                      color: Colors.amber,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'BTC / USD',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${vm.coinPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _trendBadge(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Your holdings card ──
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Holdings',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _holdingRow('Coins', vm.coins.toStringAsFixed(4), 'BTC'),
                    const SizedBox(height: 8),
                    _holdingRow(
                      'Value',
                      '\$${(vm.coins * vm.coinPrice).toStringAsFixed(2)}',
                      'USD',
                    ),
                    const Divider(height: 24),
                    _holdingRow(
                      'Cash',
                      '\$${vm.money.toStringAsFixed(0)}',
                      'USD',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Sell button ──
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.sell),
                label: Text(
                  'Sell All Coins → \$${(vm.coins * vm.coinPrice).toStringAsFixed(2)}',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: vm.canSellCoins ? () => vm.sellAllCoins() : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _trendBadge() {
    // Placeholder – will be dynamic in v0.4
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Sideways',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
      ),
    );
  }

  Widget _holdingRow(String label, String value, String currency) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Row(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            Text(
              currency,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ],
    );
  }
}
