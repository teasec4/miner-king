import 'package:crypto_king/data/game_state.dart';
import 'package:crypto_king/domain/catalogs/loan_catalog.dart';
import 'package:crypto_king/domain/models/loan.dart';
import 'package:crypto_king/presentation/viewmodels/game_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BankPage extends StatefulWidget {
  const BankPage({super.key});
  @override
  State<BankPage> createState() => _BankPageState();
}

class _BankPageState extends State<BankPage> {
  final Map<String, TextEditingController> _repayCtrls = {};

  @override
  void dispose() {
    for (final c in _repayCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final vm = GameViewModel(game);

    return Scaffold(
      appBar: AppBar(title: const Text('Bank'), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Money + debt summary ──
            Card(
              color: vm.totalDebt > 0
                  ? Colors.red.shade50
                  : Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_balance, size: 28),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cash: \$${vm.money.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (vm.totalDebt > 0)
                              Text(
                                'Debt: \$${vm.totalDebt.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                        const Spacer(),
                        if (vm.totalDebt > 0)
                          Text(
                            '${(vm.totalDebt / (vm.money + vm.totalHoldingsValue + vm.totalDebt) * 100).toStringAsFixed(0)}% of assets',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.red.shade400,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Available loans ──
            Text(
              'Available Loans',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            ...LoanCatalog.all.map((l) => _loanOfferCard(l, vm)),

            // ── Active loans ──
            if (vm.activeLoans.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Your Loans',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              ...vm.activeLoans.map((l) => _activeLoanCard(l, vm)),
            ],

            // ── Info ──
            const SizedBox(height: 16),
            Text(
              '⚠ If debt exceeds 2× your net worth, the bank may seize GPUs.',
              style: TextStyle(fontSize: 11, color: Colors.red.shade300),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loanOfferCard(Loan template, GameViewModel vm) {
    final alreadyTaken = vm.activeLoans.any((l) => l.id == template.id);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: alreadyTaken ? Colors.grey.shade100 : null,
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
              child: const Icon(
                Icons.monetization_on,
                color: Colors.blue,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    '${(template.interestPerMinute * 100).toStringAsFixed(1)}%/min interest',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            if (alreadyTaken)
              Text(
                'Taken',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              )
            else
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => vm.takeLoan(template.id),
                child: Text('\$${template.principal.toStringAsFixed(0)}'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _activeLoanCard(Loan loan, GameViewModel vm) {
    if (!_repayCtrls.containsKey(loan.id)) {
      _repayCtrls[loan.id] = TextEditingController(text: '0');
    }
    final ctrl = _repayCtrls[loan.id]!;
    final interestPerSec = loan.remaining * loan.interestPerMinute / 60;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loan.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Owe: \$${loan.remaining.toStringAsFixed(2)}  •  +\$${interestPerSec.toStringAsFixed(4)}/s',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: ctrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      hintText: '0',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final amt = double.tryParse(ctrl.text) ?? 0;
                    if (amt > 0) {
                      vm.repayLoan(loan.id, amt);
                      ctrl.text = '0';
                    }
                  },
                  child: const Text('Repay'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
