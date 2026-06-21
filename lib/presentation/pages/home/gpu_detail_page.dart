import 'package:crypto_king/data/game_state.dart';
import 'package:crypto_king/domain/catalogs/debuff_catalog.dart';
import 'package:crypto_king/domain/catalogs/gpu_catalog.dart';
import 'package:crypto_king/domain/models/inventory_item.dart';
import 'package:crypto_king/presentation/viewmodels/game_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GpuDetailPage extends StatefulWidget {
  final String instanceId;
  const GpuDetailPage({super.key, required this.instanceId});
  @override
  State<GpuDetailPage> createState() => _GpuDetailPageState();
}

class _GpuDetailPageState extends State<GpuDetailPage> {
  bool _showInventory = false;

  @override
  Widget build(BuildContext context) {
    final vm = GameViewModel.fromState(context.watch<GameState>());
    final gpu = vm.gpus
        .where((g) => g.instanceId == widget.instanceId)
        .firstOrNull;
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
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header
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
                                _badge(
                                  'SL',
                                  Colors.purple,
                                  Colors.purple.shade50,
                                ),
                              if (!gpu.isPowered)
                                _badge(
                                  'OFF',
                                  Colors.white,
                                  Colors.grey.shade600,
                                ),
                              if (dead)
                                _badge('DEAD', Colors.white, Colors.grey),
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

                // GPU upgrade
                _section('GPU Upgrade'),
                const SizedBox(height: 8),
                Builder(
                  builder: (_) {
                    final upgradeCost = vm.upgradeCost(gpu.instanceId);
                    final canUpgrade =
                        upgradeCost > 0 && vm.money >= upgradeCost;
                    return GestureDetector(
                      onTap: canUpgrade
                          ? () => vm.upgradeGpu(gpu.instanceId)
                          : null,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.deepPurple.shade200,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.memory,
                              size: 32,
                              color: Colors.deepPurple.shade300,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'GPU',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.deepPurple.shade400,
                                    ),
                                  ),
                                  Text(
                                    'Upgrade to next tier',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (canUpgrade) _upArrow(upgradeCost),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Inventory
                _section('Inventory'),
                const SizedBox(height: 4),
                _inventorySection(vm, widget.instanceId),

                const SizedBox(height: 16),

                // Debuffs
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
                              ? () => vm.repairDebuff(widget.instanceId, d)
                              : null,
                          child: Text('Fix \$$cost'),
                        ),
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 16),

                // Actions
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
                        onTap: () => vm.togglePower(widget.instanceId),
                      ),
                      _actionBtn(
                        icon: Icons.speed,
                        label: gpu.overclockLevel > 0 ? 'OC Off' : 'Overclock',
                        color: gpu.overclockLevel > 0
                            ? Colors.deepOrange
                            : Colors.grey.shade600,
                        onTap: () => vm.toggleOverclock(widget.instanceId),
                      ),
                    ],
                    if (vm.repairCost(widget.instanceId) > 0 ||
                        gpu.condition < 1.0)
                      _actionBtn(
                        icon: Icons.build,
                        label: 'Repair \$${vm.repairCost(widget.instanceId)}',
                        color: vm.canRepair(widget.instanceId)
                            ? Colors.blue
                            : Colors.grey,
                        onTap: vm.canRepair(widget.instanceId)
                            ? () => vm.repairGpu(widget.instanceId)
                            : null,
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Coin switch
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
                              : () =>
                                    vm.setMiningCoin(widget.instanceId, coinId),
                          child: Text(coin?.name ?? coinId.toUpperCase()),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // Performance
                _section('Performance'),
                const SizedBox(height: 4),
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
              ],
            ),
            if (_showInventory) _inventoryPanel(vm),
          ],
        ),
      ),
      floatingActionButton: Badge(
        label: Text('${vm.gpuInventoryCount}'),
        isLabelVisible: vm.gpuInventoryCount > 0,
        child: FloatingActionButton.small(
          onPressed: () => setState(() => _showInventory = !_showInventory),
          child: const Icon(Icons.inventory),
        ),
      ),
    );
  }

  Widget _upArrow(int cost) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
    decoration: BoxDecoration(
      color: Colors.amber.shade100,
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: Colors.amber.shade300),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.arrow_upward, size: 8, color: Colors.amber.shade800),
        const SizedBox(width: 1),
        Text(
          '$cost',
          style: TextStyle(
            fontSize: 7,
            fontWeight: FontWeight.bold,
            color: Colors.amber.shade800,
          ),
        ),
      ],
    ),
  );

  // ── Inventory section ──

  Widget _inventorySection(GameViewModel vm, String gpuId) {
    final items = vm.unequippedInventory.where((i) => i.type == 'gpu').toList();
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          'No items. Visit Shop.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
        ),
      );
    }
    final isGpu = (InventoryItem i) => i.type == 'gpu';
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        return GestureDetector(
          onTap: isGpu(item) ? () => vm.installGpu(item.id) : null,
          child: Container(
            width: 100,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isGpu(item)
                    ? Colors.blue.shade200
                    : Colors.grey.shade300,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _iconForType(item.type),
                  size: 22,
                  color: isGpu(item) ? Colors.blue : Colors.grey.shade400,
                ),
                const SizedBox(height: 4),
                Text(
                  item.name,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                Text(
                  item.detail,
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                ),
                if (isGpu(item))
                  Text(
                    'Tap to install',
                    style: TextStyle(fontSize: 8, color: Colors.blue.shade400),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _iconForType(String type) => switch (type) {
    'gpu' => Icons.memory,
    _ => Icons.inventory,
  };

  Widget _inventoryPanel(GameViewModel vm) => Positioned(
    top: 0,
    left: 0,
    bottom: 0,
    width: 220,
    child: Material(
      elevation: 8,
      color: Colors.white,
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(16),
        bottomRight: Radius.circular(16),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.inventory, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Inventory (${vm.inventory.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _showInventory = false),
                    child: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (vm.inventory.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Empty. Buy items in Shop.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              )
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(8),
                  children: vm.unequippedInventory
                      .where((item) => item.type == 'gpu')
                      .map((item) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          color: Colors.grey.shade50,
                          child: ListTile(
                            dense: true,
                            leading: Icon(
                              _iconForType(item.type),
                              size: 20,
                              color: Colors.grey.shade600,
                            ),
                            title: Text(
                              item.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              item.detail,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            trailing: item.type == 'gpu'
                                ? _invActionBtn(
                                    'INSTALL',
                                    Colors.deepPurple,
                                    () => vm.installGpu(item.id),
                                  )
                                : null,
                          ),
                        );
                      })
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  // ── Shared ──

  Widget _invActionBtn(String label, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );

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
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
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
