import 'package:crypto_king/data/game_state.dart';
import 'package:crypto_king/domain/catalogs/cooling_catalog.dart';
import 'package:crypto_king/domain/catalogs/psu_catalog.dart';
import 'package:crypto_king/domain/catalogs/slot_catalog.dart';
import 'package:crypto_king/domain/catalogs/solar_catalog.dart';
import 'package:crypto_king/presentation/viewmodels/game_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FarmDetailPage extends StatelessWidget {
  const FarmDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = GameViewModel.fromState(context.watch<GameState>());

    return Scaffold(
      appBar: AppBar(title: const Text('Farm Overview'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Stats bar
              _statsRow(vm),
              const SizedBox(height: 20),

              // Equipment grid: 2x2 around motherboard
              _equipmentGrid(vm),
              const SizedBox(height: 20),

              // GPU slots section
              _section('GPU Slots (${vm.usedSlots}/${vm.totalSlots})'),
              const SizedBox(height: 8),
              _gpuSlotList(vm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statsRow(GameViewModel vm) {
    final totalWatt = vm.totalPowerDraw;
    final capacity = vm.psuCapacity;
    final overloaded = totalWatt > capacity;
    final solarGen = vm.solarPower;

    return Card(
      color: overloaded ? Colors.red.shade50 : Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat(
                  'Hashrate',
                  '${vm.totalHashrate.toStringAsFixed(1)} MH/s',
                  Icons.speed,
                ),
                _stat('Power', '${totalWatt.toStringAsFixed(0)}W', Icons.bolt),
                _stat(
                  'Solar',
                  '${solarGen.toStringAsFixed(0)}W',
                  Icons.solar_power,
                ),
                _stat('Cooling', vm.coolingLabel, Icons.ac_unit),
              ],
            ),
            if (overloaded) ...[
              const SizedBox(height: 8),
              Text(
                '⚠ PSU overloaded! ${totalWatt.toStringAsFixed(0)}W / ${capacity}W — hashrate reduced',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon) => Column(
    children: [
      Icon(icon, size: 20, color: Colors.green.shade700),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
      Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
    ],
  );

  Widget _equipmentGrid(GameViewModel vm) {
    return Column(
      children: [
        // Top: Cooling
        _gearSlot(
          icon: Icons.ac_unit,
          color: Colors.blue,
          label: 'Cooling',
          current: vm.coolingLabel.isEmpty ? 'Stock' : vm.coolingLabel,
          detail: 'All GPUs temp',
          upgradeName: vm.nextCoolingName,
          upgradeCost: vm.coolingUpgradeCost,
          canUpgrade:
              vm.coolingUpgradeCost > 0 && vm.money >= vm.coolingUpgradeCost,
          onUpgrade: () {
            final next = _nextCooling(vm);
            if (next != null) vm.buyCooling(next);
          },
        ),
        const SizedBox(height: 6),
        // Middle row: PSU + Motherboard + Solar
        Row(
          children: [
            Expanded(
              child: _gearSlot(
                icon: Icons.power,
                color: Colors.orange,
                label: 'PSU',
                current: vm.psuLabel,
                detail: '${vm.psuCapacity}W capacity',
                upgradeName: vm.nextPsuName,
                upgradeCost: vm.psuUpgradeCost,
                canUpgrade:
                    vm.psuUpgradeCost > 0 && vm.money >= vm.psuUpgradeCost,
                onUpgrade: () {
                  final next = _nextPsu(vm);
                  if (next != null) vm.buyPsu(next);
                },
                compact: true,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(flex: 2, child: _motherboardCenter(vm)),
            const SizedBox(width: 6),
            Expanded(
              child: _gearSlot(
                icon: Icons.solar_power,
                color: Colors.yellow.shade700,
                label: 'Solar',
                current: '${vm.solarPower.toStringAsFixed(0)}W',
                detail: 'Free power',
                upgradeName: _nextSolarName(vm),
                upgradeCost: _nextSolarCost(vm),
                canUpgrade:
                    _nextSolarCost(vm) > 0 && vm.money >= _nextSolarCost(vm),
                onUpgrade: () {
                  final s = _nextSolar(vm);
                  if (s != null) vm.buySolar(s);
                },
                compact: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _motherboardCenter(GameViewModel vm) {
    final next = SlotCatalog.nextTier(vm.totalSlots);
    final canUpgrade = next != null && vm.money >= next.price;
    return GestureDetector(
      onTap: canUpgrade ? () => vm.buySlotTier(next) : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.green.shade600, Colors.green.shade800],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.green.shade900, width: 2),
        ),
        child: Column(
          children: [
            const Icon(Icons.dashboard, color: Colors.white, size: 32),
            const SizedBox(height: 6),
            Text(
              '${vm.totalSlots} slots',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              '${vm.usedSlots}/${vm.totalSlots} used',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
            if (canUpgrade) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Upgrade → ${next!.slots} slots  \$${next.price}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _gearSlot({
    required IconData icon,
    required Color color,
    required String label,
    required String current,
    required String detail,
    String? upgradeName,
    int? upgradeCost,
    required bool canUpgrade,
    required VoidCallback onUpgrade,
    bool compact = false,
  }) {
    return GestureDetector(
      onTap: canUpgrade ? onUpgrade : null,
      child: Container(
        padding: EdgeInsets.all(compact ? 10 : 14),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: canUpgrade ? color.withAlpha(120) : Colors.grey.shade300,
            width: canUpgrade ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: compact ? 18 : 22, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: compact ? 10 : 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              current,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: compact ? 14 : 16,
                color: Colors.green.shade800,
              ),
            ),
            Text(
              detail,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
            if (canUpgrade && upgradeName != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withAlpha(40),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '→ $upgradeName  \$$upgradeCost',
                  style: TextStyle(
                    fontSize: 9,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _gpuSlotList(GameViewModel vm) {
    final gpus = vm.gpus;
    return Column(
      children: List.generate(vm.totalSlots, (i) {
        final gpu = i < gpus.length ? gpus[i] : null;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: gpu != null
                ? Colors.deepPurple.shade50
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: gpu != null
                  ? Colors.deepPurple.shade200
                  : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.memory,
                size: 28,
                color: gpu != null ? Colors.deepPurple : Colors.grey.shade400,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gpu?.modelName ?? 'Slot ${i + 1} — Empty',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: gpu != null
                            ? Colors.black87
                            : Colors.grey.shade500,
                      ),
                    ),
                    if (gpu != null)
                      Text(
                        '${gpu.revenuePerMin.toStringAsFixed(2)} \$/min  •  ${(gpu.condition * 100).toInt()}% cond  •  ${gpu.temperature.toStringAsFixed(0)}°C',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      )
                    else
                      Text(
                        'Install GPU from inventory',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                        ),
                      ),
                  ],
                ),
              ),
              if (gpu != null)
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                  size: 18,
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _section(String title) => Align(
    alignment: Alignment.centerLeft,
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

  // ── Upgrade helpers ──

  CoolingUpgrade? _nextCooling(GameViewModel vm) {
    final idx = CoolingCatalog.indexOf(vm.game.farm.coolingSystem);
    return idx + 1 < CoolingCatalog.all.length
        ? CoolingCatalog.all[idx + 1]
        : null;
  }

  PsuUpgrade? _nextPsu(GameViewModel vm) {
    final idx = PsuCatalog.indexOf(vm.game.farm.psuTier);
    return idx + 1 < PsuCatalog.all.length ? PsuCatalog.all[idx + 1] : null;
  }

  SolarUpgrade? _nextSolar(GameViewModel vm) {
    // Solar stacks, always offer basic if none, else next in list
    if (vm.solarPower <= 0) return SolarCatalog.basic;
    if (vm.solarPower < 400) return SolarCatalog.advanced;
    if (vm.solarPower < 1400) return SolarCatalog.farm;
    return null;
  }

  String? _nextSolarName(GameViewModel vm) => _nextSolar(vm)?.name;
  int _nextSolarCost(GameViewModel vm) => _nextSolar(vm)?.price ?? 0;
}
