import 'package:crypto_king/data/game_state.dart';
import 'package:crypto_king/domain/catalogs/cooling_catalog.dart';
import 'package:crypto_king/domain/catalogs/psu_catalog.dart';
import 'package:crypto_king/domain/catalogs/slot_catalog.dart';
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
            _section('Motherboard'),
            Text(
              'Buy to install from inventory',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 4),
            ...SlotCatalog.tiers
                .where((t) => t.slots > vm.totalSlots)
                .map(
                  (t) => _upgradeCard(
                    icon: Icons.dashboard,
                    color: Colors.green,
                    title: 'Motherboard ${t.slots} slots',
                    subtitle: _moboGpuLimit(t),
                    price: t.price,
                    canBuy: vm.money >= t.price,
                    onBuy: () => vm.buySlotTier(t),
                  ),
                ),

            // PSU
            _section('Power Supply'),
            Text(
              'Buy to equip on GPU later',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 4),
            ...PsuCatalog.all
                .where((p) => p.id != 'psu_stock')
                .map(
                  (p) => _upgradeCard(
                    icon: Icons.power,
                    color: Colors.orange,
                    title: p.name,
                    subtitle: 'Up to ${p.maxWattPerGpu}W per GPU',
                    price: p.price,
                    canBuy: vm.money >= p.price,
                    onBuy: () => vm.buyPsu(p),
                  ),
                ),

            // GPUs
            _section('GPUs'),
            ...vm.shopGpus.map((e) {
              final m = e.model;
              final hasSale = vm.hasGpuSale;
              return _upgradeCard(
                icon: Icons.memory,
                color: Colors.deepPurple,
                title: m.name,
                subtitle:
                    '${m.baseHashrate.toStringAsFixed(0)} MH/s  •  ${m.basePowerConsumption.toStringAsFixed(0)}W  •  ${m.baseTemperature.toStringAsFixed(0)}°C',
                price: e.effectivePrice,
                canBuy: e.canBuy,
                onBuy: () => vm.buyGpu(m),
                hint: !e.psuOk
                    ? 'Need ${e.psuRequired}'
                    : !e.canAfford
                    ? 'Need \$${(e.effectivePrice - vm.money.toInt()).clamp(0, 999999)}'
                    : null,
                salePercent: hasSale ? 30 : null,
              );
            }),

            // Cooling
            _section('Cooling'),
            Text(
              'Buy to equip on GPU later',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 4),
            ...CoolingCatalog.all
                .where((c) => c.id != 'basic')
                .map(
                  (c) => _upgradeCard(
                    icon: Icons.ac_unit,
                    color: Colors.blue,
                    title: c.name,
                    subtitle: '${c.tempReduction}°C',
                    price: c.price,
                    canBuy: vm.money >= c.price,
                    onBuy: () => vm.buyCooling(c),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  String _moboGpuLimit(SlotTier t) {
    final maxGpu = switch (t.maxGpuTier) {
      0 => 'GTX 1060',
      1 => 'RTX 2060',
      2 => 'RTX 3070',
      3 => 'RTX 5090',
      _ => 'Any',
    };
    return '${t.slots} slots, max GPU: $maxGpu';
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
    int? salePercent,
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (salePercent != null)
                      Text(
                        '-$salePercent% ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    Text(
                      '\$$price',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
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
