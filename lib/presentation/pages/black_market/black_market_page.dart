import 'dart:math';
import 'package:crypto_king/data/game_state.dart';
import 'package:crypto_king/domain/catalogs/debuff_catalog.dart';
import 'package:crypto_king/domain/catalogs/gpu_catalog.dart';
import 'package:crypto_king/domain/catalogs/psu_catalog.dart';
import 'package:crypto_king/domain/models/gpu_model.dart';
import 'package:crypto_king/presentation/viewmodels/game_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BlackMarketPage extends StatefulWidget {
  const BlackMarketPage({super.key});
  @override
  State<BlackMarketPage> createState() => _BlackMarketPageState();
}

class _BlackMarketPageState extends State<BlackMarketPage> {
  static final _r = Random();
  late List<_BlackOffer> _offers;
  int _lastGen = -1;

  @override
  void initState() {
    super.initState();
    _generateOffers();
  }

  void _generateOffers() {
    final allGpus = [...GpuCatalog.all];
    allGpus.shuffle(_r);
    _offers = allGpus.take(3).map((model) {
      final debuffs = <String>[];
      final count = 1 + _r.nextInt(2);
      for (int i = 0; i < count; i++) {
        final available = DebuffCatalog.all
            .where((d) => !debuffs.contains(d.id))
            .toList();
        if (available.isNotEmpty) {
          debuffs.add(available[_r.nextInt(available.length)].id);
        }
      }
      final discount = 0.4 + _r.nextDouble() * 0.2;
      final price = (model.price * discount).ceil();
      final approxHash =
          '~${(model.baseHashrate * (0.85 + _r.nextDouble() * 0.3)).toStringAsFixed(0)} MH/s';
      return _BlackOffer(
        model: model,
        price: price,
        debuffs: debuffs,
        approxHash: approxHash,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final vm = GameViewModel(context.watch<GameState>());
    final gen = vm.blackMarketGen;
    final refreshIn = vm.blackMarketRefreshIn;

    // Detect global refresh (even when page was closed)
    if (_lastGen >= 0 && gen > _lastGen) {
      _lastGen = gen;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _generateOffers();
      });
    }
    if (_lastGen < 0) _lastGen = gen;

    final mins = refreshIn ~/ 60;
    final secs = refreshIn % 60;

    return Scaffold(
      appBar: AppBar(title: const Text('Black Market'), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Text(
                  'Shady deals — stats are approximate.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const Spacer(),
                Text(
                  'Refresh in $mins:${secs.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '\$${vm.money.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Text(
                  'PSU: ${vm.psuLabel} (max ${vm.psuMaxWatt}W)',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 8),
                Text(
                  'Slots: ${vm.usedSlots}/${vm.totalSlots}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._offers.map((o) => _offerCard(o, vm)),
          ],
        ),
      ),
    );
  }

  Widget _offerCard(_BlackOffer offer, GameViewModel vm) {
    final m = offer.model;
    final psuOk = vm.psuSupports(m.basePowerConsumption);
    final canBuy = vm.money >= offer.price && psuOk;

    // Find which PSU is needed
    String? psuNeeded;
    if (!psuOk) {
      for (final psu in PsuCatalog.all) {
        if (m.basePowerConsumption <= psu.maxWattPerGpu) {
          psuNeeded = psu.name;
          break;
        }
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.memory, size: 36, color: Colors.red),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        m.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 6),
                      for (final _ in offer.debuffs)
                        Text(
                          '⚠',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade500,
                          ),
                        ),
                    ],
                  ),
                  Text(
                    offer.approxHash,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  if (!psuOk)
                    Text(
                      'Need $psuNeeded',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.red.shade400,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${offer.price}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'vs \$${m.price}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade400,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(height: 4),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canBuy ? Colors.red.shade600 : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                  onPressed: canBuy
                      ? () {
                          vm.buyBlackMarketGpu(m, offer.price, offer.debuffs);
                          setState(() => _offers.remove(offer));
                        }
                      : null,
                  child: Text(!psuOk ? 'Need PSU' : 'Buy'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BlackOffer {
  final GpuModel model;
  final int price;
  final List<String> debuffs;
  final String approxHash;
  _BlackOffer({
    required this.model,
    required this.price,
    required this.debuffs,
    required this.approxHash,
  });
}
