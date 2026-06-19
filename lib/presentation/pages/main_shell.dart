import 'package:crypto_king/presentation/pages/city/city_page.dart';
import 'package:crypto_king/presentation/pages/home/home_page.dart';
import 'package:crypto_king/presentation/pages/market/market_page.dart';
import 'package:crypto_king/presentation/pages/wallet/wallet_page.dart';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: IndexedStack(index: _currentIndex, children: _tabs),
      ),
      BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: Colors.deepPurple,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.memory), label: 'Rig'),
          BottomNavigationBarItem(icon: Icon(Icons.wallet), label: 'Wallet'),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Market',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_city),
            label: 'City',
          ),
        ],
      ),
    ],
  );
}
