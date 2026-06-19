import 'package:crypto_king/data/game_state.dart';
import 'package:crypto_king/presentation/viewmodels/game_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameViewModel>().startTicks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final vm = GameViewModel(game);

    return Scaffold(
      appBar: AppBar(title: const Text('Mining Rig'), centerTitle: true),
      body: SafeArea(
        child: Column(
          children: [
            _resourcesBar(vm),
            const Divider(height: 1),
            Expanded(child: _gpuList(vm)),
            _bottomBar(vm),
          ],
        ),
      ),
    );
  }

  // ── Top bar: money, coins, hashrate, power ──

  Widget _resourcesBar(GameViewModel vm) {
    final profit = vm.netProfitPerHour;
    final profitColor = profit >= 0 ? Colors.green : Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              _chip(
                Icons.attach_money,
                '${vm.money.toStringAsFixed(0)}\$',
                Colors.green,
              ),
              const SizedBox(width: 8),
              _chip(
                Icons.currency_bitcoin,
                vm.coins.toStringAsFixed(6),
                Colors.amber,
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${vm.totalHashrate.toStringAsFixed(1)} MH/s',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${profit >= 0 ? "+" : ""}${profit.toStringAsFixed(2)}\$/h',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: profitColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.bolt, size: 14, color: Colors.orange.shade700),
              const SizedBox(width: 2),
              Text(
                '${vm.totalPowerDraw.toStringAsFixed(0)}W',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const SizedBox(width: 8),
              Text(
                '−${vm.electricityCostPerHour.toStringAsFixed(3)}\$/h',
                style: TextStyle(fontSize: 11, color: Colors.red.shade400),
              ),
              const Spacer(),
              Text(
                '${vm.electricityRate.toStringAsFixed(2)}\$/kWh',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color,
          ),
        ),
      ],
    );
  }

  // ── GPU list ──

  Widget _gpuList(GameViewModel vm) {
    final gpus = vm.gpus;
    if (gpus.isEmpty) {
      return const Center(child: Text('No GPUs installed'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: gpus.length,
      itemBuilder: (context, index) => _gpuCard(gpus[index], vm),
    );
  }

  Widget _gpuCard(GpuDisplayInfo gpu, GameViewModel vm) {
    final isBroken = gpu.isBroken;
    final isOverclocked = gpu.overclockLevel > 0;

    // Temperature color
    final tempColor = switch (gpu.tempStatus) {
      'critical' => Colors.red,
      'warning' => Colors.orange,
      _ => Colors.green,
    };

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: isBroken ? Colors.red.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: name, status, temp ──
            Row(
              children: [
                Icon(
                  isBroken ? Icons.memory : Icons.memory,
                  size: 36,
                  color: isBroken ? Colors.red.shade300 : Colors.deepPurple,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            gpu.modelName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          if (isOverclocked) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'OC',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.deepOrange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                          if (isBroken) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'BROKEN',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.thermostat, size: 14, color: tempColor),
                          const SizedBox(width: 2),
                          Text(
                            '${gpu.temperature.toStringAsFixed(0)}°C',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: tempColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Cond: ${(gpu.condition * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Action buttons ──
            if (!isBroken) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Overclock toggle
                  _actionButton(
                    label: isOverclocked ? 'Stock' : 'Overclock',
                    icon: Icons.speed,
                    color: isOverclocked ? Colors.grey : Colors.deepOrange,
                    onTap: () => vm.toggleOverclock(gpu.instanceId),
                  ),
                  const SizedBox(width: 8),
                  // Upgrade
                  if (vm.upgradeCost(gpu.instanceId) > 0)
                    _actionButton(
                      label: 'Upgrade \$${vm.upgradeCost(gpu.instanceId)}',
                      icon: Icons.upgrade,
                      color: vm.canUpgrade(gpu.instanceId)
                          ? Colors.amber
                          : Colors.grey,
                      onTap: vm.canUpgrade(gpu.instanceId)
                          ? () => vm.upgradeGpu(gpu.instanceId)
                          : null,
                    ),
                ],
              ),
            ] else ...[
              // Repair button for broken GPU
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _actionButton(
                    label: 'Repair \$${vm.repairCost(gpu.instanceId)}',
                    icon: Icons.build,
                    color: vm.canRepair(gpu.instanceId)
                        ? Colors.blue
                        : Colors.grey,
                    onTap: vm.canRepair(gpu.instanceId)
                        ? () => vm.repairGpu(gpu.instanceId)
                        : null,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      height: 32,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 14),
        label: Text(label, style: const TextStyle(fontSize: 11)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          backgroundColor: color.withAlpha(onTap != null ? 255 : 80),
          foregroundColor: Colors.white,
        ),
        onPressed: onTap,
      ),
    );
  }

  // ── Bottom bar ──

  Widget _bottomBar(GameViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Text(
            'Slots: ${vm.usedSlots}/${vm.totalSlots}',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
          const Spacer(),
          ElevatedButton.icon(
            icon: const Icon(Icons.sell, size: 16),
            label: Text(
              'Sell \$${(vm.coins * vm.coinPrice).toStringAsFixed(2)}',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontSize: 12),
            ),
            onPressed: vm.canSellCoins ? () => vm.sellAllCoins() : null,
          ),
        ],
      ),
    );
  }
}
