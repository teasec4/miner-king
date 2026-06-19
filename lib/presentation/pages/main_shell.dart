import 'package:crypto_king/presentation/pages/home/home_page.dart';
import 'package:crypto_king/presentation/pages/market/market_page.dart';
import 'package:crypto_king/presentation/pages/shop/shop_page.dart';
import 'package:flutter/material.dart';

/// Shell with bottom navigation bar — Rig / Market / Shop.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _tabs = <Widget>[HomePage(), MarketPage(), ShopPage()];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: IndexedStack(index: _currentIndex, children: _tabs),
        ),
        BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.memory), label: 'Rig'),
            BottomNavigationBarItem(
              icon: Icon(Icons.show_chart),
              label: 'Market',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Shop'),
          ],
        ),
      ],
    );
  }
}
