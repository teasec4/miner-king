import 'package:crypto_king/data/game_state.dart';
import 'package:crypto_king/domain/catalogs/debuff_catalog.dart';
import 'package:crypto_king/domain/models/game_event.dart';
import 'package:crypto_king/domain/models/inventory_item.dart';
import 'package:crypto_king/domain/systems/market_system.dart';
import 'package:crypto_king/presentation/pages/home/gpu_detail_page.dart';
import 'package:crypto_king/presentation/viewmodels/game_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GameEvent? _expandedEvent;
  bool _showInventory = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameViewModel>().startTicks();
      context.read<GameState>().onEvent = (e) {
        if (!mounted) return;
        setState(() => _expandedEvent = e);
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) setState(() => _expandedEvent = null);
        });
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = GameViewModel(context.watch<GameState>());
    return Scaffold(
      appBar: AppBar(title: const Text('Mining Rig'), centerTitle: true),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _resourcesBar(vm),
                const Divider(height: 1),
                Expanded(child: _gpuList(vm)),
              ],
            ),
            if (vm.activeEvents.any((e) => e.category == 'rig'))
              _eventOverlay(vm),
            if (_showInventory) _inventoryPanel(vm),
          ],
        ),
      ),
      floatingActionButton: Badge(
        label: Text('${vm.unequippedInventory.length}'),
        isLabelVisible: vm.unequippedInventory.isNotEmpty,
        child: FloatingActionButton.small(
          onPressed: () => setState(() => _showInventory = !_showInventory),
          child: const Icon(Icons.inventory),
        ),
      ),
    );
  }

  Widget _eventOverlay(GameViewModel vm) => Positioned(
    bottom: 70,
    right: 8,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: vm.activeEvents.where((e) => e.category == 'rig').map((e) {
        final open = _expandedEvent?.id == e.id;
        return GestureDetector(
          onTap: () => setState(() => _expandedEvent = open ? null : e),
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.all(10),
            width: 190,
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade600,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        e.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      e.durationTicks > 0 ? '${e.remainingTicks}s' : 'Now',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.topCenter,
                  child: open
                      ? Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.description,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                e.durationTicks > 0
                                    ? '\u23F1 ${e.remainingTicks}s remaining'
                                    : 'Instant effect',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    ),
  );
  Widget _resourcesBar(GameViewModel vm) {
    final profit = vm.netProfitPerMin;
    final jobIncome = vm.jobIncomePerMin;
    final total = profit + jobIncome;
    final btc = vm.coinState('btc');
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 6, 8, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _hudStat(
                Icons.attach_money,
                vm.money.toStringAsFixed(0),
                Colors.greenAccent,
              ),
              const SizedBox(width: 10),
              _hudStat(
                Icons.account_balance_wallet,
                vm.totalHoldingsValue.toStringAsFixed(0),
                Colors.amberAccent,
              ),
              const Spacer(),
              _hudStat(
                Icons.speed,
                vm.totalHashrate.toStringAsFixed(1),
                Colors.cyanAccent,
              ),
              const SizedBox(width: 8),
              _hudStat(
                total >= 0 ? Icons.trending_up : Icons.trending_down,
                '${total >= 0 ? "+" : ""}${total.toStringAsFixed(2)}/min',
                total >= 0 ? Colors.greenAccent : Colors.redAccent,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.bolt, size: 11, color: Colors.orange.shade300),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  '${vm.totalPowerDraw.toStringAsFixed(0)}W  −\$${vm.electricityCostPerMin.toStringAsFixed(2)}/min',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                ),
              ),
              if (btc != null)
                Text(
                  '${MarketSystem.phaseIcon(btc.phase)} BTC \$${btc.price.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 10, color: Colors.white54),
                ),
              if (jobIncome > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '+job ${jobIncome.toStringAsFixed(2)}/min',
                  style: TextStyle(fontSize: 10, color: Colors.orange.shade300),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _hudStat(IconData icon, String value, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 3),
      Text(
        value,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: color,
        ),
      ),
    ],
  );

  Widget _gpuList(GameViewModel vm) {
    final gpus = vm.gpus;
    final totalSlots = vm.totalSlots;
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        // Motherboard card
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.dashboard, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Motherboard — $totalSlots slots',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${gpus.length}/$totalSlots',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Slots
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: List.generate(totalSlots, (i) {
                    final gpu = i < gpus.length ? gpus[i] : null;
                    if (gpu != null) {
                      return _gpuCard(gpu, vm);
                    }
                    return _emptySlotCard(i + 1);
                  }),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptySlotCard(int slotNum) => Container(
    margin: const EdgeInsets.symmetric(vertical: 4),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
    ),
    child: Row(
      children: [
        Icon(Icons.memory, size: 32, color: Colors.grey.shade400),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Slot $slotNum — Empty',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            Text(
              'Install GPU from inventory',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _gpuCard(GpuDisplayInfo gpu, GameViewModel vm) {
    final dead = gpu.isDead,
        oc = gpu.overclockLevel > 0,
        sl = gpu.siliconLotteryLevel > 0,
        cp = (gpu.condition * 100).toInt();
    final tc = switch (gpu.tempStatus) {
      'critical' => Colors.red,
      'warning' => Colors.orange,
      _ => Colors.green,
    };
    final cc = dead
        ? Colors.grey
        : gpu.condition > 0.7
        ? Colors.green
        : gpu.condition > 0.3
        ? Colors.orange
        : Colors.red;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: dead ? Colors.grey.shade100 : null,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GpuDetailPage(instanceId: gpu.instanceId),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.memory,
                    size: 36,
                    color: dead ? Colors.grey.shade400 : Colors.deepPurple,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                gpu.modelName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: dead ? Colors.grey.shade500 : null,
                                ),
                              ),
                            ),
                            if (oc) ...[
                              const SizedBox(width: 4),
                              _badge(
                                'OC',
                                Colors.deepOrange,
                                Colors.orange.shade100,
                              ),
                            ],
                            if (sl) ...[
                              const SizedBox(width: 4),
                              _badge(
                                'SL',
                                Colors.purple,
                                Colors.purple.shade50,
                              ),
                            ],
                            const SizedBox(width: 4),
                            _badge(
                              gpu.miningCoinName,
                              Colors.blue.shade700,
                              Colors.blue.shade50,
                            ),
                            if (!gpu.isPowered) ...[
                              const SizedBox(width: 4),
                              _badge('OFF', Colors.white, Colors.grey.shade600),
                            ],
                            if (dead) ...[
                              const SizedBox(width: 4),
                              _badge('DEAD', Colors.white, Colors.grey),
                            ],
                            for (final d in gpu.debuffs) ...[
                              const SizedBox(width: 4),
                              _badge(
                                _debuffName(d),
                                Colors.red.shade700,
                                Colors.red.shade50,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.thermostat, size: 14, color: tc),
                            const SizedBox(width: 2),
                            Text(
                              '${gpu.temperature.toStringAsFixed(0)}\u00B0C',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: tc,
                              ),
                            ),
                            const Spacer(),
                            if (!dead && gpu.isPowered)
                              Text(
                                '\$${gpu.revenuePerMin.toStringAsFixed(1)}/min',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade600,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      value: gpu.condition,
                      strokeWidth: 2,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(cc),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$cp%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cc,
                    ),
                  ),
                  const Spacer(),
                  if (!dead) ...[
                    _iconBtn(
                      gpu.isPowered
                          ? Icons.power_settings_new
                          : Icons.power_off,
                      gpu.isPowered ? Colors.green : Colors.grey,
                      () => vm.togglePower(gpu.instanceId),
                    ),
                    const SizedBox(width: 2),
                    _iconBtn(
                      Icons.speed,
                      oc ? Colors.deepOrange : Colors.grey.shade400,
                      () => vm.toggleOverclock(gpu.instanceId),
                    ),
                    const SizedBox(width: 4),
                    _coinSwitcher(gpu, vm),
                    const SizedBox(width: 4),
                  ],
                  if (vm.repairCost(gpu.instanceId) > 0 ||
                      gpu.condition < 1.0) ...[
                    if (!dead) const SizedBox(width: 4),
                    _btn(
                      'Fix \$${vm.repairCost(gpu.instanceId)}',
                      Icons.build,
                      vm.canRepair(gpu.instanceId) ? Colors.blue : Colors.grey,
                      vm.canRepair(gpu.instanceId)
                          ? () => vm.repairGpu(gpu.instanceId)
                          : null,
                    ),
                  ],
                  for (final d in gpu.debuffs) ...[
                    const SizedBox(width: 4),
                    _btn(
                      'Fix ${_debuffName(d)} \$${vm.debuffRepairCost(d)}',
                      Icons.cleaning_services,
                      vm.money >= vm.debuffRepairCost(d)
                          ? Colors.red.shade400
                          : Colors.grey,
                      vm.money >= vm.debuffRepairCost(d)
                          ? () => vm.repairDebuff(gpu.instanceId, d)
                          : null,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _coinSwitcher(GpuDisplayInfo gpu, GameViewModel vm) {
    final mineable = {'btc', 'doge'};
    final coins = vm.coins.where((c) => mineable.contains(c.id)).toList();
    if (coins.length < 2) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32),
      tooltip: 'Switch coin',
      onSelected: (id) => vm.setMiningCoin(gpu.instanceId, id),
      itemBuilder: (_) => coins
          .map(
            (c) => PopupMenuItem(
              value: c.id,
              child: Text(
                '${c.name}  \$${c.price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: c.id == gpu.miningCoinId
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          )
          .toList(),
      child: _iconBtn(Icons.currency_bitcoin, Colors.blue.shade600, null),
    );
  }

  String _debuffName(String id) {
    return DebuffCatalog.byId(id)?.name ?? id;
  }

  Widget _badge(String text, Color fg, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(3),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 9, color: fg, fontWeight: FontWeight.bold),
    ),
  );

  Widget _iconBtn(IconData icon, Color color, VoidCallback? onTap) => SizedBox(
    width: 30,
    height: 28,
    child: IconButton(
      icon: Icon(icon, size: 18),
      color: color,
      padding: EdgeInsets.zero,
      onPressed: onTap,
      splashRadius: 16,
    ),
  );

  Widget _btn(String label, IconData icon, Color color, VoidCallback? onTap) =>
      SizedBox(
        height: 26,
        child: ElevatedButton.icon(
          icon: Icon(icon, size: 12),
          label: Text(label, style: const TextStyle(fontSize: 10)),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            backgroundColor: color.withAlpha(onTap != null ? 255 : 80),
            foregroundColor: Colors.white,
          ),
          onPressed: onTap,
        ),
      );

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
                  children: vm.inventory.map((item) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: item.isEquipped
                          ? Colors.green.shade50
                          : Colors.grey.shade50,
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          _invIcon(item.type),
                          size: 20,
                          color: item.isEquipped
                              ? Colors.green
                              : Colors.grey.shade600,
                        ),
                        title: Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          item.isEquipped ? 'On GPU' : item.detail,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        trailing: !item.isEquipped
                            ? _invAction(item, vm)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  IconData _invIcon(String type) => switch (type) {
    'cooling' => Icons.ac_unit,
    'psu' => Icons.power,
    'paste' => Icons.water_drop,
    'bios' => Icons.tune,
    'motherboard' => Icons.dashboard,
    'gpu' => Icons.memory,
    _ => Icons.inventory,
  };

  Widget _invAction(InventoryItem item, GameViewModel vm) {
    if (item.type == 'gpu' && !vm.farmHasFreeSlots) {
      return Text(
        'No slots',
        style: TextStyle(fontSize: 10, color: Colors.red.shade400),
      );
    }
    final label = item.type == 'gpu' ? 'INSTALL' : 'USE';
    final color = item.type == 'gpu' ? Colors.deepPurple : Colors.green;
    final onTap = item.type == 'gpu'
        ? () => vm.installGpu(item.id)
        : item.type == 'motherboard'
        ? () => vm.useMotherboard(item.id)
        : null;
    if (onTap == null) return const SizedBox.shrink();
    return GestureDetector(
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
  }
}
