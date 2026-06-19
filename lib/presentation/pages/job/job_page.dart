import 'package:crypto_king/data/game_state.dart';
import 'package:crypto_king/domain/catalogs/job_catalog.dart';
import 'package:crypto_king/presentation/viewmodels/game_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class JobPage extends StatelessWidget {
  const JobPage({super.key});

  double _jobIncome(Job job, GameViewModel vm) {
    final exp = vm.jobExp(job.id);
    final level = exp ~/ 100;
    return job.salaryPerTick * 60 * (1.0 + level * 0.1);
  }

  @override
  Widget build(BuildContext context) {
    final vm = GameViewModel(context.watch<GameState>());
    final activeId = vm.activeJobId;
    final activeJob = activeId != null ? JobCatalog.byId(activeId) : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Jobs'), centerTitle: true),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activeJob.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Earning: \$${_jobIncome(activeJob, vm).toStringAsFixed(2)}/min',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Lv ${(vm.jobExp(activeJob.id) / 100).floor() + 1}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _expBar(vm.jobExp(activeJob.id) % 100),
                          const SizedBox(width: 8),
                          Text(
                            'EXP',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '⚠ -40% mining',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.red.shade400,
                            ),
                          ),
                        ],
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
                            'Quit Job',
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
            Text(
              'Available Jobs',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            ...JobCatalog.all.map((j) {
              final income = _jobIncome(j, vm);
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.work_outline,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              j.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              j.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              '\$${income.toStringAsFixed(2)}/min  •  -40% mining speed',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: activeJob?.id == j.id
                            ? null
                            : () => vm.startJob(j.id),
                        child: Text(
                          activeJob?.id == j.id ? 'Working' : 'Start',
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

  Widget _expBar(int exp) => Expanded(
    child: ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
        value: exp / 100,
        minHeight: 6,
        backgroundColor: Colors.grey.shade200,
        valueColor: const AlwaysStoppedAnimation(Colors.blue),
      ),
    ),
  );
}
