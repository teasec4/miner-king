import 'package:crypto_king/data/game_state.dart';
import 'package:crypto_king/presentation/pages/bank/bank_page.dart';
import 'package:crypto_king/presentation/pages/black_market/black_market_page.dart';
import 'package:crypto_king/presentation/pages/job/job_page.dart';
import 'package:crypto_king/presentation/pages/shop/shop_page.dart';
import 'package:crypto_king/presentation/viewmodels/game_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CityPage extends StatelessWidget {
  const CityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = GameViewModel(context.watch<GameState>());
    return Scaffold(
      appBar: AppBar(title: const Text('City'), centerTitle: true),
      body: SafeArea(
        child: Padding(
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
                      badge: vm.activeLoans.isNotEmpty ? _loanBadge(vm) : null,
                    ),
                    _building(
                      context,
                      Icons.work,
                      'Job',
                      'Earn cash\n-40% mining speed',
                      Colors.orange,
                      '/job',
                      badge: vm.activeJobId != null ? _activeBadge() : null,
                    ),
                    _building(
                      context,
                      Icons.warehouse,
                      'Warehouse',
                      'Coming soon...',
                      Colors.grey,
                      null,
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
                      Icons.people,
                      'Employees',
                      'Coming soon...',
                      Colors.grey,
                      null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
