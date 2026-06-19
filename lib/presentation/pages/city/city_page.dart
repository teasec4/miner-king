import 'package:crypto_king/data/game_state.dart';
import 'package:crypto_king/presentation/pages/bank/bank_page.dart';
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
                      'Buy GPUs, cooling\nsolar panels, slots',
                      Colors.deepPurple,
                      '/shop',
                    ),
                    _building(
                      context,
                      Icons.account_balance,
                      'Bank',
                      'Take loans, repay debt\n3 loan types available',
                      Colors.blue,
                      '/bank',
                      badge: vm.activeLoans.isNotEmpty ? _loanBadge(vm) : null,
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
    child: InkWell(
      onTap: route != null
          ? () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => _buildingPage(route)))
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
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
            if (badge != null) ...[const SizedBox(height: 6), badge],
          ],
        ),
      ),
    ),
  );

  Widget _buildingPage(String route) {
    if (route == '/shop') return const ShopPage();
    if (route == '/bank') return const BankPage();
    return const SizedBox.shrink();
  }

  Widget _loanBadge(GameViewModel vm) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.red.shade100,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '${vm.activeLoans.length} loan',
          style: TextStyle(
            fontSize: 10,
            color: Colors.red.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
