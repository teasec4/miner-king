import 'package:crypto_king/domain/entities/miner.dart';
import 'package:crypto_king/presentation/viewmodels/home_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MinerDetailPage extends StatelessWidget {
  final String minerId;

  const MinerDetailPage({super.key, required this.minerId});

  Miner? _miner(HomeViewModel vm) =>
      vm.miners.where((m) => m.id == minerId).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final miner = _miner(vm);

    if (miner == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Miner')),
        body: const Center(child: Text('Miner not found')),
      );
    }

    final remaining = vm.remaining[miner.id] ?? 0;
    final total = miner.cycleSeconds;
    final progress = 1 - (remaining / total);
    final upgradeCost = HomeViewModel.upgradeCosts[miner.lvl];
    final canUpgrade = upgradeCost != null && vm.balance >= upgradeCost;

    return Scaffold(
      appBar: AppBar(title: Text('Miner Lvl ${miner.lvl}')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.computer, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 16),
            Text('Level ${miner.lvl}',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            _infoRow('Income per cycle', '+${miner.incomePerCycle} coins'),
            _infoRow('Cycle time', '${miner.cycleSeconds}s'),
            const SizedBox(height: 16),
            Text('$remaining / $total s',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress),

            if (upgradeCost != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.upgrade),
                label: Text('Upgrade — $upgradeCost coins'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: canUpgrade ? Colors.amber : Colors.grey.shade300,
                  foregroundColor: canUpgrade ? Colors.black : Colors.grey.shade500,
                ),
                onPressed:
                    canUpgrade ? () => vm.upgradeMiner(miner.id) : null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
