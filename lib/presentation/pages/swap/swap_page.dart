import 'package:crypto_king/data/game_state.dart';
import 'package:crypto_king/domain/models/coin_state.dart';
import 'package:crypto_king/presentation/viewmodels/game_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SwapPage extends StatefulWidget {
  const SwapPage({super.key});
  @override
  State<SwapPage> createState() => _SwapPageState();
}

class _SwapPageState extends State<SwapPage> {
  String? _fromId, _toId;
  final _amountCtrl = TextEditingController(text: '0');
  String? _result;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final vm = GameViewModel.fromState(game);
    final coins = vm.coins;
    final from = _fromId != null ? vm.coinState(_fromId!) : null;
    final to = _toId != null ? vm.coinState(_toId!) : null;
    final fromBalance = _fromId != null ? vm.holding(_fromId!) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Swap Coins'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(_result),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // From
            _section('From'),
            _coinDropdown(
              coins,
              _fromId,
              (v) => setState(() {
                _fromId = v;
                _toId = null;
                _result = null;
              }),
              vm,
            ),
            if (_fromId != null) ...[
              const SizedBox(height: 12),
              _section('Amount'),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '0.0',
                      ),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _fromId!.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () =>
                        _amountCtrl.text = fromBalance.toStringAsFixed(4),
                    child: const Text('MAX'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            // Swap icon
            const Center(
              child: Icon(Icons.swap_vert, size: 36, color: Colors.blue),
            ),
            const SizedBox(height: 16),
            // To
            _section('To'),
            _coinDropdown(
              coins.where((c) => c.id != _fromId).toList(),
              _toId,
              (v) => setState(() => _toId = v),
              vm,
            ),
            // Preview + Swap button
            if (from != null && to != null) ...[
              const SizedBox(height: 20),
              _preview(from, to, vm),
              const SizedBox(height: 16),
              if (_result != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _result!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey.shade600,
        fontWeight: FontWeight.w500,
        letterSpacing: 1,
      ),
    ),
  );

  Widget _coinDropdown(
    List<CoinState> coins,
    String? value,
    ValueChanged<String?> onChange,
    GameViewModel vm,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(border: OutlineInputBorder()),
      hint: const Text('Select coin'),
      items: coins
          .map(
            (c) => DropdownMenuItem(
              value: c.id,
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        c.name[0],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    c.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Text(
                    '\$${c.price.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '(${vm.holding(c.id).toStringAsFixed(4)})',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          )
          .toList(),
      onChanged: onChange,
    );
  }

  Widget _preview(CoinState from, CoinState to, GameViewModel vm) {
    final amt = double.tryParse(_amountCtrl.text) ?? 0;
    if (amt <= 0) return const SizedBox.shrink();
    final received = amt * from.price * 0.99 / to.price;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '${amt.toStringAsFixed(4)} ${from.name}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '→ ${received.toStringAsFixed(6)} ${to.name}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Rate: 1 ${from.name} = ${(from.price * 0.99 / to.price).toStringAsFixed(4)} ${to.name}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const Spacer(),
              Text(
                'Fee: 1%',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.swap_horiz),
              label: Text('Swap ${from.name} → ${to.name}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                if (vm.swapCoins(from.id, to.id, amt)) {
                  setState(
                    () => _result =
                        'Swapped ${amt.toStringAsFixed(4)} ${from.name} → ${received.toStringAsFixed(6)} ${to.name}',
                  );
                  _amountCtrl.text = '0';
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
