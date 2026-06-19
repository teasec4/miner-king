import 'package:crypto_king/data/game_state.dart';
import 'package:crypto_king/domain/catalogs/cooling_catalog.dart';
import 'package:crypto_king/domain/catalogs/solar_catalog.dart';
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
            // Money
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

            // Motherboard
            if (vm.nextSlotTier != null)
              _upgradeCard(
                icon: Icons.dashboard,
                color: Colors.green,
                title: 'Motherboard → ${vm.nextSlotTier} slots',
                subtitle: 'Currently ${vm.totalSlots} slots',
                price: vm.nextSlotCost,
                canBuy: vm.canBuySlot,
                onBuy: () => vm.buySlot(),
              ),

            // GPUs
            _section('GPUs'),
            ...vm.shopGpus.map((e) {
              final m = e.model;
              return _upgradeCard(
                icon: Icons.memory,
                color: Colors.deepPurple,
                title: m.name,
                subtitle:
                    '${m.baseHashrate.toStringAsFixed(0)} MH/s  •  ${m.basePowerConsumption.toStringAsFixed(0)}W  •  ${m.baseTemperature.toStringAsFixed(0)}°C',
                price: m.price,
                canBuy: e.canBuy,
                onBuy: () => vm.buyGpu(m),
                hint: !e.hasSlots
                    ? 'No slots'
                    : !e.canAfford
                    ? 'Need \$${m.price - vm.money.toInt()}'
                    : null,
              );
            }),

            // Cooling
            _section('Cooling'),
            ...CoolingCatalog.all.map((c) {
              final current = game.game.farm.coolingSystem;
              final owned = current == c.id;
              final betterThanCurrent =
                  ['basic', 'fans', 'water', 'immersion'].indexOf(c.id) >
                  ['basic', 'fans', 'water', 'immersion'].indexOf(current);
              return _upgradeCard(
                icon: Icons.ac_unit,
                color: Colors.blue,
                title: c.name,
                subtitle:
                    '${c.tempReduction}°C  ${owned
                        ? "(installed)"
                        : betterThanCurrent
                        ? ""
                        : "(downgrade)"}',
                price: c.price,
                canBuy: !owned && vm.money >= c.price,
                onBuy: () => vm.buyCooling(c),
              );
            }),

            // Solar
            _section('Solar Panels'),
            Text(
              'Generated: ${vm.solarPower.toStringAsFixed(0)}W',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 4),
            ...SolarCatalog.all.map(
              (s) => _upgradeCard(
                icon: Icons.solar_power,
                color: Colors.amber,
                title: s.name,
                subtitle: '+${s.powerGen.toStringAsFixed(0)}W generation',
                price: s.price,
                canBuy: vm.money >= s.price,
                onBuy: () => vm.buySolar(s),
              ),
            ),

            // Solar
            _section('Solar Panels'),
            Text(
              'Generated: ${vm.solarPower.toStringAsFixed(0)}W',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 4),
            ...SolarCatalog.all.map(
              (s) => _upgradeCard(
                icon: Icons.solar_power,
                color: Colors.amber,
                title: s.name,
                subtitle: '+${s.powerGen.toStringAsFixed(0)}W generation',
                price: s.price,
                canBuy: vm.money >= s.price,
                onBuy: () => vm.buySolar(s),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 4),
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

  Widget _upgradeCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required int price,
    required bool canBuy,
    required VoidCallback onBuy,
    String? hint,
  }) => Card(
    margin: const EdgeInsets.symmetric(vertical: 4),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, size: 36, color: canBuy ? color : Colors.grey.shade400),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (canBuy)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
              onPressed: onBuy,
              child: Text('\$$price'),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$$price',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                  ),
                ),
                if (hint != null)
                  Text(
                    hint,
                    style: TextStyle(fontSize: 10, color: Colors.red.shade400),
                  ),
              ],
            ),
        ],
      ),
    ),
  );
}
