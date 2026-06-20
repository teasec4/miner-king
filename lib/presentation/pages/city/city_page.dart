import 'package:crypto_king/data/game_state.dart';
import 'package:crypto_king/domain/models/game_event.dart';
import 'package:crypto_king/presentation/pages/bank/bank_page.dart';
import 'package:crypto_king/presentation/pages/black_market/black_market_page.dart';
import 'package:crypto_king/presentation/pages/institute/institute_page.dart';
import 'package:crypto_king/presentation/pages/business_center/business_center_page.dart';
import 'package:crypto_king/presentation/pages/job/job_page.dart';
import 'package:crypto_king/presentation/pages/real_estate/real_estate_page.dart';
import 'package:crypto_king/presentation/pages/shop/shop_page.dart';
import 'package:crypto_king/presentation/viewmodels/game_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CityPage extends StatefulWidget {
  const CityPage({super.key});
  @override
  State<CityPage> createState() => _CityPageState();
}

class _CityPageState extends State<CityPage> {
  GameEvent? _expandedEvent;

  @override
  Widget build(BuildContext context) {
    final vm = GameViewModel(context.watch<GameState>());
    final cityEvents = vm.activeEvents
        .where((e) => e.category == 'city')
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('City'), centerTitle: true),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\$${vm.money.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Cash available',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.1,
                      children: [
                        _building(
                          context,
                          Icons.store,
                          'Shop',
                          'GPUs, cooling\nsolar, slots',
                          Colors.deepPurple,
                          '/shop',
                        ),
                        _building(
                          context,
                          Icons.account_balance,
                          'Bank',
                          'Loans & debt\n3 loan types',
                          Colors.blue,
                          '/bank',
                          badge: vm.activeLoans.isNotEmpty
                              ? _loanBadge(vm)
                              : null,
                        ),
                        _building(
                          context,
                          Icons.work,
                          'Job',
                          'Earn cash\n+EXP per level',
                          Colors.orange,
                          '/job',
                          badge: vm.activeJobId != null ? _activeBadge() : null,
                        ),
                        _building(
                          context,
                          Icons.dark_mode,
                          'Black Market',
                          'Cheap flawed GPUs\n40-60% off',
                          Colors.red,
                          '/blackmarket',
                        ),
                        _building(
                          context,
                          Icons.business,
                          'Business Center',
                          'Buy office, hire staff\nPassive income & buffs',
                          Colors.teal,
                          '/business',
                        ),
                        _building(
                          context,
                          Icons.school,
                          'Institute',
                          'Study courses\nUnlock better jobs',
                          Colors.indigo,
                          '/institute',
                          badge: vm.activeCourseId != null
                              ? _activeBadge()
                              : null,
                        ),
                        _building(
                          context,
                          Icons.home,
                          'Real Estate',
                          'Buy property\nPassive rent income',
                          Colors.brown,
                          '/realestate',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ── Event overlay (positioned, like Rig) ──
            if (cityEvents.isNotEmpty) _eventOverlay(cityEvents),
          ],
        ),
      ),
    );
  }

  Widget _eventOverlay(List<GameEvent> events) => Positioned(
    bottom: 8,
    right: 8,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: events.map((e) {
        final open = _expandedEvent?.id == e.id;
        return GestureDetector(
          onTap: () => setState(() => _expandedEvent = open ? null : e),
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.all(10),
            width: 190,
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.campaign, color: Colors.white, size: 14),
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

  Widget _building(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color,
    String? route, {
    Widget? badge,
  }) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: route != null
          ? () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => _buildingPage(route)))
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: route != null ? null : Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          if (badge != null) Positioned(top: 6, right: 6, child: badge),
        ],
      ),
    ),
  );

  Widget _buildingPage(String route) {
    if (route == '/shop') return const ShopPage();
    if (route == '/bank') return const BankPage();
    if (route == '/job') return const JobPage();
    if (route == '/blackmarket') return const BlackMarketPage();
    if (route == '/institute') return const InstitutePage();
    if (route == '/business') return const BusinessCenterPage();
    if (route == '/realestate') return const RealEstatePage();
    return const SizedBox.shrink();
  }

  Widget _activeBadge() => Container(
    width: 12,
    height: 12,
    decoration: const BoxDecoration(
      color: Colors.green,
      shape: BoxShape.circle,
    ),
  );

  Widget _loanBadge(GameViewModel vm) => Container(
    width: 22,
    height: 22,
    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
    child: Center(
      child: Text(
        '${vm.activeLoans.length}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}
