import 'package:crypto_king/data/game_state.dart';
import 'package:crypto_king/domain/catalogs/loan_catalog.dart';
import 'package:crypto_king/domain/models/loan.dart';
import 'package:crypto_king/presentation/viewmodels/game_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BankPage extends StatelessWidget {
  const BankPage({super.key});

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
              'Interest compounds every second. Repay early to minimize cost.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loanOfferCard(Loan template, GameViewModel vm) {
    final alreadyTaken = vm.activeLoans.any((l) => l.id == template.id);
    final unlocked = vm.isLoanUnlocked(template.id);
    final prevTier = template.id == 'medium'
        ? 'small'
        : template.id == 'large'
        ? 'medium'
        : null;
    final repsNeeded = prevTier != null
        ? 2 - (vm.loanRepayments[prevTier] ?? 0)
        : 0;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: alreadyTaken
          ? Colors.grey.shade100
          : unlocked
          ? null
          : Colors.grey.shade100,
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
                    '${(template.interestPerMinute * 60 * 100).toStringAsFixed(0)}%/h interest',
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
            else if (!unlocked)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Locked',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.red.shade400,
                    ),
                  ),
                  Text(
                    'Repay ${prevTier!.toUpperCase()} $repsNeeded more times',
                    style: TextStyle(fontSize: 10, color: Colors.red.shade300),
                  ),
                ],
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
    final interestPerSec = loan.remaining * loan.interestPerMinute / 60;
    final canPay = vm.money >= loan.remaining;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
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
                    'Owe: \$${loan.remaining.toStringAsFixed(2)}  \u2022  +\$${interestPerSec.toStringAsFixed(4)}/s',
                    style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canPay ? Colors.green : Colors.grey,
                foregroundColor: Colors.white,
              ),
              onPressed: canPay
                  ? () => vm.repayLoan(loan.id, loan.remaining)
                  : null,
              child: Text('Pay \$${loan.remaining.toStringAsFixed(0)}'),
            ),
          ],
        ),
      ),
    );
  }
}
