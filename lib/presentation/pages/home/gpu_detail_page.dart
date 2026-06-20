import 'package:crypto_king/data/game_state.dart';
import 'package:crypto_king/domain/catalogs/debuff_catalog.dart';
import 'package:crypto_king/domain/catalogs/gpu_catalog.dart';
import 'package:crypto_king/presentation/viewmodels/game_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GpuDetailPage extends StatelessWidget {
  final String instanceId;
  const GpuDetailPage({super.key, required this.instanceId});

  @override
  Widget build(BuildContext context) {
    final vm = GameViewModel(context.watch<GameState>());
    final gpu = vm.gpus.where((g) => g.instanceId == instanceId).firstOrNull;
    if (gpu == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('GPU Detail')),
        body: const Center(child: Text('GPU not found')),
      );
    }

    final dead = gpu.isDead;
    final model = GpuCatalog.byId(gpu.modelId);
    final cp = (gpu.condition * 100).toInt();

    return Scaffold(
      appBar: AppBar(title: Text(gpu.modelName), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Header ──
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: dead
                        ? Colors.grey.shade200
                        : Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.memory,
                    size: 32,
                    color: dead ? Colors.grey : Colors.deepPurple,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gpu.modelName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          _badge(
                            gpu.miningCoinName,
                            Colors.blue.shade700,
                            Colors.blue.shade50,
                          ),
                          if (gpu.overclockLevel > 0)
                            _badge(
                              'OC',
                              Colors.deepOrange,
                              Colors.orange.shade100,
                            ),
                          if (gpu.siliconLotteryLevel > 0)
                            _badge('SL', Colors.purple, Colors.purple.shade50),
                          if (!gpu.isPowered)
                            _badge('OFF', Colors.white, Colors.grey.shade600),
                          if (dead) _badge('DEAD', Colors.white, Colors.grey),
                          for (final d in gpu.debuffs)
                            _badge(
                              DebuffCatalog.byId(d)?.name ?? d,
                              Colors.red.shade700,
                              Colors.red.shade50,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Stats ──
            _section('Performance'),
            _statRow(
              'Hashrate',
              '${vm.totalHashrate.toStringAsFixed(1)} MH/s',
              Icons.speed,
              Colors.deepPurple,
            ),
            _statRow(
              'Revenue',
              '\$${gpu.revenuePerMin.toStringAsFixed(2)}/min',
              Icons.attach_money,
              Colors.green,
            ),
            _statRow(
              'Temperature',
              '${gpu.temperature.toStringAsFixed(0)}°C',
              Icons.thermostat,
              gpu.tempStatus == 'critical' ? Colors.red : Colors.orange,
            ),
            _statRow(
              'Condition',
              '$cp%',
              Icons.favorite,
              cp > 70
                  ? Colors.green
                  : cp > 30
                  ? Colors.orange
                  : Colors.red,
            ),
            if (model != null)
              _statRow(
                'Power Draw',
                '${model.basePowerConsumption.toStringAsFixed(0)}W',
                Icons.bolt,
                Colors.orange,
              ),

            const SizedBox(height: 16),

            // ── Equipment (RPG-style around GPU) ──
            _section('Equipment'),
            const SizedBox(height: 12),
            _equipmentLayout(vm),

            const SizedBox(height: 16),

            // ── Debuffs ──
            if (gpu.debuffs.isNotEmpty) ...[
              _section('Debuffs'),
              const SizedBox(height: 4),
              ...gpu.debuffs.map((d) {
                final debuff = DebuffCatalog.byId(d);
                final cost = vm.debuffRepairCost(d);
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  color: Colors.red.shade50,
                  child: ListTile(
                    leading: const Icon(Icons.warning, color: Colors.red),
                    title: Text(
                      debuff?.name ?? d,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      debuff?.description ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: vm.money >= cost
                            ? Colors.red.shade400
                            : Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: vm.money >= cost
                          ? () => vm.repairDebuff(instanceId, d)
                          : null,
                      child: Text('Fix \$$cost'),
                    ),
                  ),
                );
              }),
            ],

            const SizedBox(height: 16),

            // ── Actions ──
            _section('Actions'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!dead) ...[
                  _actionBtn(
                    icon: gpu.isPowered
                        ? Icons.power_settings_new
                        : Icons.power_off,
                    label: gpu.isPowered ? 'Power Off' : 'Power On',
                    color: gpu.isPowered ? Colors.green : Colors.grey,
                    onTap: () => vm.togglePower(instanceId),
                  ),
                  _actionBtn(
                    icon: Icons.speed,
                    label: gpu.overclockLevel > 0 ? 'OC Off' : 'Overclock',
                    color: gpu.overclockLevel > 0
                        ? Colors.deepOrange
                        : Colors.grey.shade600,
                    onTap: () => vm.toggleOverclock(instanceId),
                  ),
                  if (vm.upgradeCost(instanceId) > 0)
                    _actionBtn(
                      icon: Icons.upgrade,
                      label: 'Upgrade \$${vm.upgradeCost(instanceId)}',
                      color: vm.canUpgrade(instanceId)
                          ? Colors.amber
                          : Colors.grey,
                      onTap: vm.canUpgrade(instanceId)
                          ? () => vm.upgradeGpu(instanceId)
                          : null,
                    ),
                ],
                if (vm.repairCost(instanceId) > 0 || gpu.condition < 1.0)
                  _actionBtn(
                    icon: Icons.build,
                    label: 'Repair \$${vm.repairCost(instanceId)}',
                    color: vm.canRepair(instanceId) ? Colors.blue : Colors.grey,
                    onTap: vm.canRepair(instanceId)
                        ? () => vm.repairGpu(instanceId)
                        : null,
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Coin switch ──
            _section('Mining Coin'),
            const SizedBox(height: 8),
            Row(
              children: ['btc', 'doge'].map((coinId) {
                final coin = vm.coinState(coinId);
                final selected = gpu.miningCoinId == coinId;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: coinId == 'btc' ? 4 : 0,
                      left: coinId == 'doge' ? 4 : 0,
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selected
                            ? Colors.blue
                            : Colors.grey.shade200,
                        foregroundColor: selected
                            ? Colors.white
                            : Colors.grey.shade700,
                      ),
                      onPressed: selected
                          ? null
                          : () => vm.setMiningCoin(instanceId, coinId),
                      child: Text(coin?.name ?? coinId.toUpperCase()),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ── RPG-style equipment layout ──

  Widget _equipmentLayout(GameViewModel vm) => SizedBox(
    height: 260,
    child: Stack(
      alignment: Alignment.center,
      children: [
        // Central GPU
        Container(
          width: 140,
          height: 180,
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.deepPurple.shade200, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.memory, size: 48, color: Colors.deepPurple.shade300),
              const SizedBox(height: 8),
              Text(
                'GPU',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.deepPurple.shade400,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${vm.psuMaxWatt}W max',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        // Top: Cooling
        Positioned(
          top: 0,
          child: _gearSlot(
            Icons.ac_unit,
            'Cooling',
            vm.coolingSystem != 'basic',
            Colors.blue,
            vm.coolingSystem == 'basic' ? 'Stock' : vm.coolingLabel,
          ),
        ),
        // Right: PSU
        Positioned(
          right: 0,
          child: _gearSlot(
            Icons.power,
            'PSU',
            vm.psuTier != 'psu_stock',
            Colors.orange,
            vm.psuLabel,
          ),
        ),
        // Bottom: Thermal Paste (future)
        Positioned(
          bottom: 0,
          child: _gearSlot(
            Icons.water_drop,
            'Paste',
            false,
            Colors.teal,
            'None',
          ),
        ),
        // Left: BIOS (future)
        Positioned(
          left: 0,
          child: _gearSlot(Icons.tune, 'BIOS', false, Colors.purple, 'Stock'),
        ),
      ],
    ),
  );

  Widget _gearSlot(
    IconData icon,
    String label,
    bool active,
    Color color,
    String detail,
  ) => Container(
    width: 80,
    height: 80,
    decoration: BoxDecoration(
      color: active ? color.withAlpha(25) : Colors.grey.shade200,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: active ? color.withAlpha(120) : Colors.grey.shade300,
        width: 2,
      ),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 24, color: active ? color : Colors.grey.shade400),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: active ? Colors.black87 : Colors.grey.shade500,
          ),
        ),
        Text(
          detail,
          style: TextStyle(
            fontSize: 8,
            color: active ? color : Colors.grey.shade400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  // ── Shared widgets ──

  Widget _section(String title) => Text(
    title,
    style: TextStyle(
      fontSize: 12,
      color: Colors.grey.shade600,
      fontWeight: FontWeight.w600,
      letterSpacing: 1,
    ),
  );

  Widget _statRow(String label, String value, IconData icon, Color color) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: color,
              ),
            ),
          ],
        ),
      );

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) => ElevatedButton.icon(
    icon: Icon(icon, size: 16),
    label: Text(label, style: const TextStyle(fontSize: 12)),
    style: ElevatedButton.styleFrom(
      backgroundColor: color.withAlpha(onTap != null ? 255 : 60),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
    onPressed: onTap,
  );

  Widget _badge(String text, Color fg, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 10, color: fg, fontWeight: FontWeight.bold),
    ),
  );
}
