import 'package:crypto_king/data/game_state.dart';
import 'package:crypto_king/domain/catalogs/cooling_catalog.dart';
import 'package:crypto_king/domain/catalogs/psu_catalog.dart';
import 'package:crypto_king/presentation/viewmodels/game_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ShopPage extends StatelessWidget {
  const ShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final vm = GameViewModel.fromState(game);

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

            // GPUs
            _section('GPUs'),
            Text(
              'Installed directly to first free slot',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 4),
            ...vm.shopGpus.map((e) {
              final m = e.model;
              final noSlots = !vm.farmHasFreeSlots;
              return _card(
                icon: Icons.memory,
                color: Colors.deepPurple,
                title: m.name,
                subtitle: noSlots
                    ? 'No free slots — buy +1 slot below'
                    : '${m.baseHashrate.toStringAsFixed(0)} MH/s  •  ${m.basePowerConsumption.toStringAsFixed(0)}W  •  ${m.baseTemperature.toStringAsFixed(0)}°C',
                price: e.effectivePrice,
                canBuy: e.canBuy && !noSlots,
                onBuy: () => vm.buyGpu(m),
                salePercent: vm.hasGpuSale ? 30 : null,
              );
            }),

            // Motherboard
            _section('Motherboard'),
            Text(
              'Current: ${vm.totalSlots} slots (max 6)',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 4),
            _card(
              icon: Icons.dashboard,
              color: Colors.green,
              title: '+1 Slot (→ ${vm.totalSlots + 1} total)',
              subtitle: vm.canBuySlot ? null : 'Max slots reached',
              price: vm.nextSlotCost,
              canBuy: vm.canBuySlot,
              onBuy: () => vm.buySlot(),
            ),

            // PSU
            _section('Power Supply'),
            Text(
              'Current: ${vm.psuLabel} — ${vm.psuCapacity}W',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 4),
            if (vm.nextPsuName != null)
              _card(
                icon: Icons.power,
                color: Colors.orange,
                title: 'Upgrade to ${vm.nextPsuName}',
                subtitle: '${vm.psuMaxWatt}W → ${_nextPsuWatt(vm)}W capacity',
                price: vm.psuUpgradeCost,
                canBuy: vm.psuUpgradeCost > 0 && vm.money >= vm.psuUpgradeCost,
                onBuy: () => vm.buyPsu(_nextPsu(vm)!),
              )
            else
              _infoCard(Icons.check_circle, Colors.green, 'PSU maxed out'),

            // Cooling
            _section('Cooling'),
            Text(
              'Current: ${vm.coolingLabel.isEmpty ? 'Stock Fan' : vm.coolingLabel}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 4),
            if (vm.nextCoolingName != null)
              _card(
                icon: Icons.ac_unit,
                color: Colors.blue,
                title: 'Upgrade to ${vm.nextCoolingName}',
                subtitle:
                    '${_currentCoolingTemp(vm)}°C → ${_nextCoolingTemp(vm)}°C',
                price: vm.coolingUpgradeCost,
                canBuy:
                    vm.coolingUpgradeCost > 0 &&
                    vm.money >= vm.coolingUpgradeCost,
                onBuy: () => vm.buyCooling(_nextCooling(vm)!),
              )
            else
              _infoCard(Icons.check_circle, Colors.blue, 'Cooling maxed out'),
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

  Widget _card({
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    required int price,
    required bool canBuy,
    required VoidCallback onBuy,
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
                if (subtitle != null)
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
              ],
            ),
        ],
      ),
    ),
  );

  Widget _infoCard(IconData icon, Color color, String text) => Card(
    margin: const EdgeInsets.symmetric(vertical: 4),
    color: color.withAlpha(20),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );

  PsuUpgrade? _nextPsu(GameViewModel vm) {
    final idx = PsuCatalog.indexOf(vm.game.farm.psuTier);
    return idx + 1 < PsuCatalog.all.length ? PsuCatalog.all[idx + 1] : null;
  }

  int _nextPsuWatt(GameViewModel vm) => _nextPsu(vm)?.maxTotalWatt ?? 0;

  CoolingUpgrade? _nextCooling(GameViewModel vm) {
    final idx = CoolingCatalog.indexOf(vm.game.farm.coolingSystem);
    return idx + 1 < CoolingCatalog.all.length
        ? CoolingCatalog.all[idx + 1]
        : null;
  }

  String _currentCoolingTemp(GameViewModel vm) {
    final idx = CoolingCatalog.indexOf(vm.game.farm.coolingSystem);
    return CoolingCatalog.all[idx].tempReduction.toStringAsFixed(0);
  }

  String _nextCoolingTemp(GameViewModel vm) {
    final next = _nextCooling(vm);
    return next?.tempReduction.toStringAsFixed(0) ?? '-';
  }
}
