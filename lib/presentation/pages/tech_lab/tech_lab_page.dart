import 'package:crypto_king/data/game_state.dart';
import 'package:crypto_king/domain/catalogs/debuff_catalog.dart';
import 'package:crypto_king/domain/config/game_config.dart';
import 'package:crypto_king/presentation/viewmodels/game_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TechLabPage extends StatelessWidget {
  const TechLabPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = GameViewModel.fromState(context.watch<GameState>());
    final gpus = vm.gpus.where((g) => !g.isDead).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Tech Lab'), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Repair debuffs and tune your GPUs.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 4),
            Text(
              '\$${vm.money.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (gpus.isEmpty) ...[
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'No GPUs installed.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            ] else
              ...gpus.map((gpu) => _gpuCard(gpu, vm)),
          ],
        ),
      ),
    );
  }

  Widget _gpuCard(GpuDisplayInfo gpu, GameViewModel vm) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.memory, color: Colors.deepPurple, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gpu.modelName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '${gpu.revenuePerMin.toStringAsFixed(2)} \$/min  \u2022  ${(gpu.condition * 100).toInt()}% cond',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: gpu.siliconLotteryLevel > 0
                        ? Colors.purple.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'SL ${gpu.siliconLotteryLevel}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: gpu.siliconLotteryLevel > 0
                          ? Colors.purple
                          : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            if (gpu.debuffs.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 4),
              Text(
                'Debuffs',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              ...gpu.debuffs.map((d) {
                final debuff = DebuffCatalog.byId(d);
                final cost = vm.debuffRepairCost(d);
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              debuff?.name ?? d,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              debuff?.description ?? '',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: vm.money >= cost
                              ? Colors.red.shade600
                              : Colors.grey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          textStyle: const TextStyle(fontSize: 11),
                        ),
                        onPressed: vm.money >= cost
                            ? () => vm.repairDebuff(gpu.instanceId, d)
                            : null,
                        child: Text('\$$cost'),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Silicon Lottery Reroll',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Randomize bonus (0-10%). Current: ${gpu.siliconLotteryLevel}%',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        vm.money >= GameConfig.siliconLotteryRerollCost
                        ? Colors.purple
                        : Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: vm.money >= GameConfig.siliconLotteryRerollCost
                      ? () => vm.rerollSiliconLottery(gpu.instanceId)
                      : null,
                  child: Text(
                    '\$${GameConfig.siliconLotteryRerollCost} — Reroll',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
