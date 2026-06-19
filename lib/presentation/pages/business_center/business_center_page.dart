import 'package:crypto_king/data/game_state.dart';
import 'package:crypto_king/domain/catalogs/office_catalog.dart';
import 'package:crypto_king/presentation/viewmodels/game_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BusinessCenterPage extends StatelessWidget {
  const BusinessCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = GameViewModel(context.watch<GameState>());
    final office = vm.officeId != null
        ? OfficeCatalog.byId(vm.officeId!)
        : null;
    final usedSlots = vm.employees.length;
    final maxSlots = vm.officeSlots;

    return Scaffold(
      appBar: AppBar(title: const Text('Business Center'), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Current office
            if (office != null) ...[
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.business,
                            color: Colors.blue,
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  office.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '\$${(office.rentPerTick * 60).toStringAsFixed(2)}/min rent',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '$usedSlots/$maxSlots slots',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      if (usedSlots < maxSlots)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Hire employees below',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Employee list
              if (vm.employees.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Your Team',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                ...vm.employees.map((eId) {
                  final emp = EmployeeCatalog.byId(eId);
                  if (emp == null) return const SizedBox.shrink();
                  final income = switch (emp.effect) {
                    EmployeeEffect.trader =>
                      '\$${(emp.effectValue * 60).toStringAsFixed(2)}/min (mood-based)',
                    EmployeeEffect.sales =>
                      '\$${(emp.effectValue * 60).toStringAsFixed(2)}/min fixed',
                    EmployeeEffect.miner =>
                      '+${(emp.effectValue * 100).toInt()}% hashrate',
                    EmployeeEffect.repair =>
                      '-${(emp.effectValue * 100).toInt()}% wear',
                  };
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    child: ListTile(
                      leading: const Icon(Icons.person, color: Colors.blue),
                      title: Text(
                        emp.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        income,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.red,
                        ),
                        onPressed: () => vm.fireEmployee(eId),
                      ),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 12),
            ],

            // Hire section
            if (office != null && usedSlots < maxSlots) ...[
              Text(
                'Hire Employees',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              ...EmployeeCatalog.all.map((e) {
                final hired = vm.employees.contains(e.id);
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  color: hired ? Colors.grey.shade100 : null,
                  child: ListTile(
                    leading: Icon(
                      Icons.person_outline,
                      color: hired ? Colors.grey : Colors.blue,
                    ),
                    title: Text(
                      e.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: hired ? Colors.grey.shade500 : null,
                      ),
                    ),
                    subtitle: Text(
                      '\$${(e.salaryPerTick * 60).toStringAsFixed(2)}/min salary  •  ${e.description}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    trailing: hired
                        ? Text(
                            'Hired',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          )
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => vm.hireEmployee(e.id),
                            child: const Text('Hire'),
                          ),
                  ),
                );
              }),
            ],

            // Buy office
            if (office == null) ...[
              const SizedBox(height: 8),
              Text(
                'Buy Office',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              ...OfficeCatalog.all.map(
                (o) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: const Icon(
                      Icons.business_outlined,
                      color: Colors.blue,
                    ),
                    title: Text(
                      o.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '\$${o.price}  •  ${o.slots} slots  •  \$${(o.rentPerTick * 60).toStringAsFixed(2)}/min rent',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: vm.money >= o.price
                            ? Colors.blue
                            : Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: vm.money >= o.price
                          ? () => vm.buyOffice(o.id)
                          : null,
                      child: Text('Buy \$${o.price}'),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
