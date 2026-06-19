import 'package:crypto_king/data/game_state.dart';
import 'package:crypto_king/domain/models/market_phase.dart';
import 'package:crypto_king/domain/systems/market_system.dart';
import 'package:crypto_king/presentation/viewmodels/game_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
                      if (coin.id == 'usdt') ...[
                        const SizedBox(width: 4),
                        _textBtn(
                          'Buy',
                          Colors.blue,
                          () => _showUsdtSheet(context, vm, isBuy: true),
                        ),
                        if (amount > 0)
                          _textBtn(
                            'Sell',
                            Colors.green,
                            () => _showUsdtSheet(context, vm, isBuy: false),
                          ),
                      ] else if (amount > 0) ...[
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
            _swapCard(context),
            const SizedBox(height: 12),
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

  void _showUsdtSheet(
    BuildContext context,
    GameViewModel vm, {
    required bool isBuy,
  }) {
    final ctrl = TextEditingController();
    final coin = vm.coinState('usdt')!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final amt = double.tryParse(ctrl.text) ?? 0;
          String preview = '';
          bool valid = false;
          if (isBuy) {
            if (amt > 0 && amt <= vm.money) {
              final received = amt * 0.95 / coin.price;
              preview = 'You get ${received.toStringAsFixed(4)} USDT';
              valid = true;
            } else if (amt > vm.money) {
              preview =
                  'Not enough cash (max \$${vm.money.toStringAsFixed(0)})';
            }
          } else {
            final balance = vm.holding('usdt');
            if (amt > 0 && amt <= balance) {
              final cash = amt * coin.price * 0.95;
              preview = 'You get \$${cash.toStringAsFixed(1)}';
              valid = true;
            } else if (amt > balance) {
              preview = 'Not enough USDT (max ${balance.toStringAsFixed(4)})';
            }
          }
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isBuy ? 'Buy USDT' : 'Sell USDT',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fee: 5%  •  1 USDT = \$${coin.price.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: ctrl,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 18),
                    decoration: InputDecoration(
                      hintText: isBuy ? 'Cash amount (\$)' : 'USDT amount',
                      border: const OutlineInputBorder(),
                      suffixIcon: TextButton(
                        onPressed: () {
                          ctrl.text = isBuy
                              ? vm.money.toStringAsFixed(0)
                              : vm.holding('usdt').toStringAsFixed(4);
                          setSheet(() {});
                        },
                        child: const Text('All'),
                      ),
                    ),
                    onChanged: (_) => setSheet(() {}),
                  ),
                  if (preview.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      preview,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: valid
                            ? Colors.green.shade700
                            : Colors.red.shade500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: isBuy ? Colors.blue : Colors.green,
                      ),
                      onPressed: valid
                          ? () {
                              if (isBuy) {
                                vm.buyCoinWithCash('usdt', amt);
                              } else {
                                vm.sellCoinForCash('usdt', amt);
                              }
                              Navigator.pop(ctx);
                            }
                          : null,
                      child: Text(
                        isBuy ? 'Buy USDT' : 'Sell USDT',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _textBtn(String label, Color color, VoidCallback onTap) => SizedBox(
    height: 28,
    child: TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        foregroundColor: color,
        textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      ),
      onPressed: onTap,
      child: Text(label),
    ),
  );

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
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    'Exchange coins at market rate. 1% fee.',
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
}
