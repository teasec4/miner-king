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

  String? _jobRequirement(Job job, GameViewModel vm) {
    switch (job.id) {
      case 'tech_support':
        final exp = vm.jobExp('fast_food');
        if (exp < 100) return 'Need Fast Food Lv2 ($exp/100 EXP)';
        return null;
      case 'freelance':
        final ffExp = vm.jobExp('fast_food');
        if (ffExp < 200) return 'Need Fast Food Lv3 ($ffExp/200 EXP)';
        return null;
      default:
        return null;
    }
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
              final req = _jobRequirement(j, vm);
              final locked = req != null;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: locked ? Colors.grey.shade100 : null,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: locked
                              ? Colors.grey.shade200
                              : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.work_outline,
                          color: locked ? Colors.grey : Colors.blue,
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
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: locked ? Colors.grey.shade500 : null,
                              ),
                            ),
                            if (locked)
                              Text(
                                req,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.red.shade400,
                                ),
                              )
                            else ...[
                              Text(
                                j.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                '\$${income.toStringAsFixed(2)}/min',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: locked ? Colors.grey : Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: locked || activeJob?.id == j.id
                            ? null
                            : () => vm.startJob(j.id),
                        child: Text(
                          activeJob?.id == j.id
                              ? 'Working'
                              : locked
                              ? 'Locked'
                              : 'Start',
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
