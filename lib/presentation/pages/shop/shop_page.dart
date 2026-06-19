import 'package:crypto_king/data/game_state.dart';
import 'package:crypto_king/presentation/viewmodels/game_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ShopPage extends StatelessWidget {
  const ShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final vm = GameViewModel(game);

    return Scaffold(
      appBar: AppBar(title: const Text('Shop'), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Money ──
            Row(
              children: [
                const Icon(Icons.attach_money, color: Colors.green, size: 20),
                const SizedBox(width: 4),
                Text(
                  '\$${vm.money.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  'Slots: ${vm.usedSlots}/${vm.totalSlots}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Slot upgrade ──
            if (vm.nextSlotTier != null) _slotUpgradeCard(vm),

            const SizedBox(height: 8),
            Text(
              'GPUs',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),

            // ── GPU list ──
            ...vm.shopGpus.map((entry) => _gpuShopCard(entry, vm)),
          ],
        ),
      ),
    );
  }

  Widget _slotUpgradeCard(GameViewModel vm) {
    return Card(
      color: vm.canBuySlot ? Colors.green.shade50 : Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.dashboard,
              size: 36,
              color: vm.canBuySlot ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Motherboard → ${vm.nextSlotTier} slots',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Currently ${vm.totalSlots} slots',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: vm.canBuySlot
                    ? Colors.green
                    : Colors.grey.shade300,
                foregroundColor: Colors.white,
              ),
              onPressed: vm.canBuySlot ? () => vm.buySlot() : null,
              child: Text('\$${vm.nextSlotCost}'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gpuShopCard(ShopGpuEntry entry, GameViewModel vm) {
    final model = entry.model;

    String? hint;
    if (!entry.hasSlots) {
      hint = 'No free slots';
    } else if (!entry.canAfford) {
      hint = 'Need \$${model.price - vm.money.toInt()} more';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
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
                    model.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${model.baseHashrate.toStringAsFixed(0)} MH/s  •  '
                    '${model.basePowerConsumption.toStringAsFixed(0)}W  •  '
                    '${model.baseTemperature.toStringAsFixed(0)}°C',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            if (entry.canBuy)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                ),
                onPressed: () => vm.buyGpu(model),
                child: Text('\$${model.price}'),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${model.price}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  if (hint != null)
                    Text(
                      hint,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.red.shade400,
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
