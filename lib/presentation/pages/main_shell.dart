import 'package:crypto_king/data/game_state.dart';
import 'package:crypto_king/presentation/pages/city/city_page.dart';
import 'package:crypto_king/presentation/pages/home/home_page.dart';
import 'package:crypto_king/presentation/pages/market/market_page.dart';
import 'package:crypto_king/presentation/pages/wallet/wallet_page.dart';
import 'package:crypto_king/presentation/viewmodels/game_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  static const _tabs = <Widget>[
    HomePage(),
    WalletPage(),
    MarketPage(),
    CityPage(),
  ];

  static const _categories = ['rig', '', 'market', 'city'];

  @override
  Widget build(BuildContext context) {
    final vm = GameViewModel(context.watch<GameState>());
    final unseen = vm.unseenEvents;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() => _currentIndex = i);
          final cat = _categories[i];
          if (cat.isNotEmpty) vm.clearUnseen(cat);
        },
        selectedItemColor: Colors.deepPurple,
        items: [
          BottomNavigationBarItem(
            icon: _tabIcon(Icons.memory, unseen['rig'] ?? 0),
            label: 'Rig',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.wallet),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(
            icon: _tabIcon(Icons.show_chart, unseen['market'] ?? 0),
            label: 'Market',
          ),
          BottomNavigationBarItem(
            icon: _tabIcon(Icons.location_city, unseen['city'] ?? 0),
            label: 'City',
          ),
        ],
      ),
    );
  }

  Widget _tabIcon(IconData icon, int badge) {
    if (badge <= 0) return Icon(icon);
    return Badge(label: Text('$badge'), child: Icon(icon));
  }
}
