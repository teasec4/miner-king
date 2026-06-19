import 'package:crypto_king/data/game_state.dart';
import 'package:crypto_king/domain/models/game_event.dart';
import 'package:crypto_king/domain/systems/market_system.dart';
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
                _bottomBar(vm),
              ],
            ),
            if (vm.activeEvents.isNotEmpty) _eventOverlay(vm),
          ],
        ),
      ),
    );
  }

  Widget _eventOverlay(GameViewModel vm) => Positioned(
    bottom: 70,
    right: 8,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: vm.activeEvents.map((e) {
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
    final profit = vm.netProfitPerHour;
    final c = profit >= 0 ? Colors.green : Colors.red;
    final btc = vm.coinState('btc');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              _chip(
                Icons.attach_money,
                '\$${vm.money.toStringAsFixed(0)}',
                Colors.green,
              ),
              const SizedBox(width: 8),
              _chip(
                Icons.account_balance_wallet,
                '\$${vm.totalHoldingsValue.toStringAsFixed(0)}',
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
                      color: c,
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
              if (vm.solarPower > 0) ...[
                Text(
                  ' \u2212 ${vm.solarPower.toStringAsFixed(0)}W \u2600',
                  style: TextStyle(fontSize: 11, color: Colors.amber.shade700),
                ),
              ],
              const SizedBox(width: 8),
              Text(
                '\u2212${vm.electricityCostPerHour.toStringAsFixed(2)}\$/h',
                style: TextStyle(fontSize: 11, color: Colors.red.shade400),
              ),
              const Spacer(),
              if (btc != null)
                Text(
                  '${MarketSystem.phaseIcon(btc.phase)} BTC \$${btc.price.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
            ],
          ),
          if (vm.solarPower > 0 || vm.coolingSystem != 'basic')
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                children: [
                  if (vm.coolingSystem != 'basic') ...[
                    Icon(Icons.ac_unit, size: 12, color: Colors.blue.shade400),
                    const SizedBox(width: 2),
                    Text(
                      vm.coolingLabel,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue.shade400,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (vm.solarPower > 0) ...[
                    Icon(
                      Icons.solar_power,
                      size: 12,
                      color: Colors.amber.shade600,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${vm.solarPower.toStringAsFixed(0)}W \u2600',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.amber.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String value, Color color) => Row(
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

  Widget _gpuList(GameViewModel vm) {
    final gpus = vm.gpus;
    final e = vm.totalSlots - vm.usedSlots;
    if (gpus.isEmpty && e == 0) {
      return const Center(child: Text('No GPUs installed'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: gpus.length + (e > 0 ? 1 : 0),
      itemBuilder: (_, i) =>
          i < gpus.length ? _gpuCard(gpus[i], vm) : _emptySlotCard(e),
    );
  }

  Widget _emptySlotCard(int count) => Card(
    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    color: Colors.grey.shade100,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.memory, size: 36, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count empty slot${count > 1 ? "s" : ""}',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: Colors.grey.shade500,
                  ),
                ),
                Text(
                  'Go to Shop to buy a GPU',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey.shade400),
        ],
      ),
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
                            _badge('SL', Colors.purple, Colors.purple.shade50),
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
                              '${gpu.miningCoinName} +\$${gpu.revenuePerHour.toStringAsFixed(1)}/h',
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
            const SizedBox(height: 8),
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
                const SizedBox(width: 6),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: gpu.condition,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(cc),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$cp%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cc,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!dead) ...[
                  _iconBtn(
                    gpu.isPowered ? Icons.power_settings_new : Icons.power_off,
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
                  if (vm.upgradeCost(gpu.instanceId) > 0)
                    _btn(
                      'Up \$${vm.upgradeCost(gpu.instanceId)}',
                      Icons.upgrade,
                      vm.canUpgrade(gpu.instanceId)
                          ? Colors.amber
                          : Colors.grey,
                      vm.canUpgrade(gpu.instanceId)
                          ? () => vm.upgradeGpu(gpu.instanceId)
                          : null,
                    ),
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _coinSwitcher(GpuDisplayInfo gpu, GameViewModel vm) {
    final coins = vm.coins.where((c) => c.id != 'usdt').toList();
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

  Widget _bottomBar(GameViewModel vm) => Container(
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
          label: Text('Sell All \$${vm.totalHoldingsValue.toStringAsFixed(2)}'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 12),
          ),
          onPressed: vm.totalHoldingsValue > 0 ? () => vm.sellAllCoins() : null,
        ),
      ],
    ),
  );
}
