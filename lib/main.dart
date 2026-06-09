import 'package:crypto_king/data/repositories/balance_manager.dart';
import 'package:crypto_king/presentation/viewmodels/home_viewmodel.dart';
import 'package:crypto_king/router/router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  final balanceManager = BalanceManager(0);
  final homeViewModel = HomeViewModel(balanceRepo: balanceManager);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: homeViewModel),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: AppRouter.router,
      title: 'Miner King',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
    );
  }
}
