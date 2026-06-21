import 'package:crypto_king/data/game_state.dart';
import 'package:crypto_king/presentation/viewmodels/game_viewmodel.dart';
import 'package:crypto_king/router/router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  final gameState = GameState();
  final gameViewModel = GameViewModel(
    rig: gameState.rigN,
    economy: gameState.economyN,
    market: gameState.marketN,
    city: gameState.cityN,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: gameState),
        ChangeNotifierProvider.value(value: gameState.rigN),
        ChangeNotifierProvider.value(value: gameState.economyN),
        ChangeNotifierProvider.value(value: gameState.marketN),
        ChangeNotifierProvider.value(value: gameState.cityN),
        Provider.value(value: gameViewModel),
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
      title: 'Mining Roguelike',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
    );
  }
}
