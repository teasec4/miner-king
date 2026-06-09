import 'package:crypto_king/domain/entities/miner.dart';
import 'package:crypto_king/presentation/viewmodels/home_viewmodel.dart';
import 'package:crypto_king/presentation/widgets/ad_banner.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
      context.read<HomeViewModel>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();

    return Scaffold(
      body: SafeArea(
        child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: vm.miners.length + (vm.maxSlots < HomeViewModel.maxTotalSlots ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < vm.miners.length) {
                  return _minerTile(vm.miners[index], vm);
                }
                return _buySlotCard(vm);
              },
            ),
          ),
          AdBanner(onReward: () => vm.addReward(50)),
          _minersInfo(vm),
        ],
        ),
      ),
    );
  }

  Widget _minerTile(Miner miner, HomeViewModel vm) {
    final remaining = vm.remaining[miner.id] ?? 0;
    final total = miner.cycleSeconds;
    final progress = 1 - (remaining / total);
    final upgradeCost = HomeViewModel.upgradeCosts[miner.lvl];
    final canUpgrade = upgradeCost != null && vm.balance >= upgradeCost;

    return InkWell(
      onTap: () => context.push('/home/miner/${miner.id}'),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.computer, color: Colors.grey, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lvl ${miner.lvl}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('+${miner.incomePerCycle} coins — ${remaining}s'),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(value: progress),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (upgradeCost != null)
              Positioned(
                top: 4,
                right: 4,
                child: SizedBox(
                  width: 70,
                  height: 26,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor:
                          canUpgrade ? Colors.amber : Colors.grey.shade300,
                      foregroundColor:
                          canUpgrade ? Colors.black : Colors.grey.shade500,
                      textStyle: const TextStyle(fontSize: 10),
                    ),
                    onPressed:
                        canUpgrade ? () => vm.upgradeMiner(miner.id) : null,
                    child: Text('Upgrade $upgradeCost'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buySlotCard(HomeViewModel vm) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: Colors.grey.shade200,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.computer, color: Colors.grey.shade400, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Buy slot ${vm.maxSlots + 1}',
                      style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                  Text('${vm.nextSlotCost} coins',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 64,
              height: 36,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor:
                      vm.canBuySlot ? Colors.green : Colors.grey.shade300,
                  foregroundColor:
                      vm.canBuySlot ? Colors.white : Colors.grey.shade500,
                  textStyle: const TextStyle(fontSize: 11),
                ),
                onPressed: vm.canBuySlot ? () => vm.buySlot() : null,
                child: Text(vm.canBuySlot ? 'Buy' : '${vm.nextSlotCost}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _minersInfo(HomeViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          const Icon(Icons.computer, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            'Miners: ${vm.miners.length}',
            style: const TextStyle(fontSize: 16),
          ),
          const Spacer(),
          Text(
            '${vm.coinsPerMinute.toStringAsFixed(1)}/min',
            style: const TextStyle(fontSize: 16, color: Colors.amber),
          ),
          const Spacer(),
          Text(
            '${vm.balance} coins',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
