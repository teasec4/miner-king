import 'package:crypto_king/data/game_state.dart';
import 'package:crypto_king/domain/catalogs/office_catalog.dart';
import 'package:crypto_king/presentation/viewmodels/game_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BusinessCenterPage extends StatelessWidget {
  const BusinessCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = GameViewModel.fromState(context.watch<GameState>());
    final office = vm.officeId != null
        ? OfficeCatalog.byId(vm.officeId!)
        : null;
    final usedSlots = vm.employees.length;
    final maxSlots = vm.officeSlots;
    final synergies = vm.activeSynergies;
    final nextOffice = OfficeCatalog.nextTier(vm.officeId);
    final poolSecs = vm.poolRefreshIn;

    return Scaffold(
      appBar: AppBar(title: const Text('Business Center'), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Office card ──
            if (office != null) ...[
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: usedSlots >= maxSlots
                                  ? Colors.red.shade100
                                  : Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$usedSlots/$maxSlots',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: usedSlots >= maxSlots
                                    ? Colors.red.shade700
                                    : Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // ── Synergies ──
                      if (synergies.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        Text(
                          'Synergies',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.amber.shade800,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...synergies.map(
                          (s) => Row(
                            children: [
                              Icon(
                                Icons.bolt,
                                size: 14,
                                color: Colors.amber.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                s.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.amber.shade900,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // ── Hired employees ──
                      if (vm.employees.isNotEmpty) ...[
                        const Divider(height: 20),
                        ...vm.employees.map((eId) {
                          final emp = EmployeeCatalog.byId(eId);
                          if (emp == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(
                                  _iconForEffect(emp.effect),
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${emp.name}  •  ${_effectLabel(emp)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                                Text(
                                  '-\$${(emp.salaryPerTick * 60).toStringAsFixed(2)}/min',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.red.shade400,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => vm.fireEmployee(eId),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
            ],

            // ── Upgrade office ──
            if (nextOffice != null) ...[
              const SizedBox(height: 12),
              Text(
                office == null ? 'Buy Office' : 'Upgrade Office',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.business_outlined,
                    color: Colors.blue,
                  ),
                  title: Text(
                    nextOffice.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '\$${nextOffice.price}  •  ${nextOffice.slots} slots  •  \$${(nextOffice.rentPerTick * 60).toStringAsFixed(2)}/min',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: vm.money >= nextOffice.price
                          ? Colors.blue
                          : Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: vm.money >= nextOffice.price
                        ? () => vm.buyOffice(nextOffice.id)
                        : null,
                    child: Text('Buy \$${nextOffice.price}'),
                  ),
                ),
              ),
            ],

            // ── Hire employees ──
            if (office != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      usedSlots < maxSlots
                          ? 'Hire Employee ($usedSlots/$maxSlots)'
                          : 'Office full',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  // Pool refresh timer
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh,
                          size: 12,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${poolSecs}s',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: vm.refreshEmployeePool,
                    child: Icon(
                      Icons.cached,
                      size: 16,
                      color: Colors.blue.shade400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (vm.availableEmployees.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'No candidates right now...',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                )
              else
                ...vm.availableEmployees.map((e) {
                  final hired = vm.employees.contains(e.id);
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: hired ? Colors.grey.shade100 : null,
                    child: ListTile(
                      leading: Icon(
                        _iconForEffect(e.effect),
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
                        '\$${(e.salaryPerTick * 60).toStringAsFixed(2)}/min  •  ${e.description}',
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
                          : usedSlots >= maxSlots
                          ? const SizedBox.shrink()
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
          ],
        ),
      ),
    );
  }

  IconData _iconForEffect(EmployeeEffect effect) => switch (effect) {
    EmployeeEffect.trader => Icons.show_chart,
    EmployeeEffect.sales => Icons.attach_money,
    EmployeeEffect.miner => Icons.memory,
    EmployeeEffect.repair => Icons.build,
    EmployeeEffect.electrician => Icons.bolt,
    EmployeeEffect.security => Icons.shield,
  };

  String _effectLabel(Employee emp) => switch (emp.effect) {
    EmployeeEffect.trader =>
      '±\$${(emp.effectValue * 60).toStringAsFixed(1)}/min mood',
    EmployeeEffect.sales =>
      '\$${(emp.effectValue * 60).toStringAsFixed(2)}/min',
    EmployeeEffect.miner => '+${(emp.effectValue * 100).toInt()}% hashrate',
    EmployeeEffect.repair => '-${(emp.effectValue * 100).toInt()}% wear',
    EmployeeEffect.electrician =>
      '-${(emp.effectValue * 100).toInt()}% electricity',
    EmployeeEffect.security =>
      '-${(emp.effectValue * 100).toInt()}% rig events',
  };
}
