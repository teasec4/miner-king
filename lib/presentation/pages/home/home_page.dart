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
            // ── Resources bar ──
            _resourcesBar(vm),
            const Divider(height: 1),
            // ── GPU list ──
            Expanded(child: _gpuList(vm)),
            // ── Bottom actions ──
            _bottomBar(vm),
          ],
        ),
      ),
    );
  }

  Widget _resourcesBar(GameViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Money
          _resourceChip(
            Icons.attach_money,
            '${vm.money.toStringAsFixed(0)}\$',
            Colors.green,
          ),
          const SizedBox(width: 12),
          // Coins
          _resourceChip(
            Icons.currency_bitcoin,
            vm.coins.toStringAsFixed(4),
            Colors.amber,
          ),
          const Spacer(),
          // Hashrate
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${vm.totalHashrate.toStringAsFixed(1)} MH/s',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                '${vm.coinsPerSecond.toStringAsFixed(4)} coins/s',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resourceChip(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _gpuList(GameViewModel vm) {
    final gpus = vm.gpus;
    if (gpus.isEmpty) {
      return const Center(child: Text('No GPUs installed'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: gpus.length,
      itemBuilder: (context, index) {
        final gpu = gpus[index];
        final canUpgrade = vm.canUpgrade(gpu.instanceId);
        final cost = vm.upgradeCost(gpu.instanceId);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.memory, size: 40, color: Colors.deepPurple),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gpu.modelName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Temp: ${gpu.temperature.toStringAsFixed(0)}°C  •  '
                        'Cond: ${(gpu.condition * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (cost > 0)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canUpgrade
                          ? Colors.amber
                          : Colors.grey.shade300,
                      foregroundColor: canUpgrade
                          ? Colors.black
                          : Colors.grey.shade500,
                    ),
                    onPressed: canUpgrade
                        ? () => vm.upgradeGpu(gpu.instanceId)
                        : null,
                    child: Text('Upgrade \$$cost'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _bottomBar(GameViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          // Slots info
          Text(
            'Slots: ${vm.usedSlots}/${vm.totalSlots}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          // Sell coins button
          ElevatedButton.icon(
            icon: const Icon(Icons.sell, size: 18),
            label: Text('Sell ${vm.coins.toStringAsFixed(4)} coins'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: vm.canSellCoins ? () => vm.sellAllCoins() : null,
          ),
        ],
      ),
    );
  }
}
