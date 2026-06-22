import 'package:crypto_king/data/game_state.dart';
import 'package:crypto_king/domain/catalogs/job_catalog.dart';
import 'package:crypto_king/presentation/viewmodels/game_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class JobPage extends StatelessWidget {
  const JobPage({super.key});

  int _levelForPath(List<Job> path, GameViewModel vm) {
    int totalExp = 0;
    for (final j in path) {
      totalExp += vm.jobExp(j.id);
    }
    return (totalExp ~/ 100).clamp(0, path.length - 1);
  }

  int _expForLevel(List<Job> path, GameViewModel vm) {
    int totalExp = 0;
    for (final j in path) {
      totalExp += vm.jobExp(j.id);
    }
    return totalExp % 100;
  }

  double _salaryBonus(GameViewModel vm, String pathName) {
    double bonus = 1.0;
    final courses = vm.completedCourses;
    switch (pathName) {
      case 'Tech & IT':
        if (courses.contains('basic_it')) bonus += 0.20;
        if (courses.contains('data_analytics')) bonus += 0.20;
        if (courses.contains('programming')) bonus += 0.20;
      case 'Business & Finance':
        if (courses.contains('management')) bonus += 0.20;
        if (courses.contains('data_analytics')) bonus += 0.20;
        if (courses.contains('marketing')) bonus += 0.20;
      case 'Creative & Media':
        if (courses.contains('marketing')) bonus += 0.20;
      case 'Engineering':
        if (courses.contains('programming')) bonus += 0.20;
      default:
    }
    if (courses.contains('business')) bonus += 0.25;
    return bonus;
  }

  IconData _iconForPath(String name) => switch (name) {
    'Food & Service' => Icons.restaurant,
    'Tech & IT' => Icons.computer,
    'Business & Finance' => Icons.account_balance,
    'Creative & Media' => Icons.palette,
    'Engineering' => Icons.code,
    _ => Icons.work,
  };

  @override
  Widget build(BuildContext context) {
    final vm = GameViewModel.fromState(context.watch<GameState>());
    final activeId = vm.activeJobId;
    final activeJob = activeId != null ? JobCatalog.byId(activeId) : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Career'), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (activeJob != null) ...[
              Card(
                color: Colors.amber.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.work, color: Colors.amber, size: 28),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Builder(
                              builder: (_) {
                                for (final entry in JobCatalog.paths.entries) {
                                  if (entry.value.any(
                                    (j) => j.id == activeJob.id,
                                  )) {
                                    final lv = _levelForPath(entry.value, vm);
                                    final bonus = _salaryBonus(vm, entry.key);
                                    final income =
                                        activeJob.salaryPerTick * 60 * bonus;
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          activeJob.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          '\$${income.toStringAsFixed(2)}/min  •  Lv${lv + 1}/${entry.value.length}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        ],
                      ),
                      Builder(
                        builder: (_) {
                          for (final entry in JobCatalog.paths.entries) {
                            if (entry.value.any((j) => j.id == activeJob.id)) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(3),
                                        child: LinearProgressIndicator(
                                          value:
                                              _expForLevel(entry.value, vm) /
                                              100,
                                          minHeight: 6,
                                          backgroundColor: Colors.grey.shade200,
                                          valueColor:
                                              const AlwaysStoppedAnimation(
                                                Colors.blue,
                                              ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'EXP',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () => vm.quitJob(),
                          child: const Text(
                            'Quit',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            ...JobCatalog.paths.entries.map((entry) {
              final name = entry.key;
              final path = entry.value;
              final level = _levelForPath(path, vm);
              final title = JobCatalog.titleForPath(path, level)!;
              final bonus = _salaryBonus(vm, name);
              final income = title.salaryPerTick * 60 * bonus;
              final isWorking = path.any((j) => j.id == activeJob?.id);
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _iconForPath(name),
                            size: 24,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  '\$${income.toStringAsFixed(2)}/min  •  ${title.name}  •  Lv${level + 1}/${path.length}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isWorking
                                  ? Colors.grey
                                  : Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                            onPressed: isWorking
                                ? null
                                : () => vm.startJob(title.id),
                            child: Text(isWorking ? 'Active' : 'Work'),
                          ),
                        ],
                      ),
                      if (level < path.length - 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 34),
                          child: Text(
                            'Next: ${path[level + 1].name}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                    ],
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
