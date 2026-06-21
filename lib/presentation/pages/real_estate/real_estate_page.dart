import 'package:crypto_king/data/game_state.dart';
import 'package:crypto_king/domain/catalogs/property_catalog.dart';
import 'package:crypto_king/presentation/viewmodels/game_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RealEstatePage extends StatelessWidget {
  const RealEstatePage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = GameViewModel.fromState(context.watch<GameState>());

    return Scaffold(
      appBar: AppBar(title: const Text('Real Estate'), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '\$${vm.money.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Owned properties
            if (vm.properties.isNotEmpty) ...[
              Text(
                'Your Properties',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              ...vm.properties.map((pid) {
                final p = PropertyCatalog.byId(pid);
                if (p == null) return const SizedBox.shrink();
                return Card(
                  color: Colors.green.shade50,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  child: ListTile(
                    leading: const Icon(Icons.home, color: Colors.green),
                    title: Text(
                      p.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '\$${(p.rentPerTick * 60).toStringAsFixed(2)}/min rent',
                      style: TextStyle(color: Colors.green.shade700),
                    ),
                    trailing: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
            ],

            Text(
              'Available Properties',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            ...PropertyCatalog.all.map((p) {
              final owned = vm.properties.contains(p.id);
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 2),
                color: owned ? Colors.grey.shade100 : null,
                child: ListTile(
                  leading: Icon(
                    Icons.home_outlined,
                    color: owned ? Colors.grey : Colors.blue,
                  ),
                  title: Text(
                    p.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: owned ? Colors.grey.shade500 : null,
                    ),
                  ),
                  subtitle: Text(
                    '\$${p.price}  •  \$${(p.rentPerTick * 60).toStringAsFixed(2)}/min income',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  trailing: owned
                      ? Text(
                          'Owned',
                          style: TextStyle(color: Colors.grey.shade500),
                        )
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: vm.money >= p.price
                                ? Colors.blue
                                : Colors.grey,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: vm.money >= p.price
                              ? () => vm.buyProperty(p.id)
                              : null,
                          child: Text('Buy \$${p.price}'),
                        ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
