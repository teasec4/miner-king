import 'package:crypto_king/data/game_state.dart';
import 'package:crypto_king/domain/catalogs/job_catalog.dart';
import 'package:crypto_king/presentation/viewmodels/game_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class JobPage extends StatelessWidget {
  const JobPage({super.key});

  double _jobIncome(Job job, GameViewModel vm) {
    final exp = vm.jobExp(job.id);
    final level = (exp ~/ job.expPerLevel).clamp(0, job.maxLevel);
    return job.salaryPerTick * 60 * (1.0 + level * 0.1);
  }

  int _jobLevel(Job job, GameViewModel vm) {
    return (vm.jobExp(job.id) ~/ job.expPerLevel).clamp(0, job.maxLevel);
  }

  int _jobExpForLevel(Job job, GameViewModel vm) {
    return vm.jobExp(job.id) % job.expPerLevel;
  }

  String? _jobRequirement(Job job, GameViewModel vm) {
    final hasBasicIt = vm.completedCourses.contains('basic_it');
    final hasMgmt = vm.completedCourses.contains('management');
    final hasProg = vm.completedCourses.contains('programming');
    final hasBiz = vm.completedCourses.contains('business');
    final hasData = vm.completedCourses.contains('data_analytics');
    final hasMarketing = vm.completedCourses.contains('marketing');

    if (JobCatalog.tier1.any((j) => j.id == job.id)) return null;

    if (JobCatalog.tier2.any((j) => j.id == job.id)) {
      final hasExp = JobCatalog.tier1.any((t) => _jobLevel(t, vm) >= 5);
      if (hasExp) return null;
      if (job.id == 'tech_support' ||
          job.id == 'call_center' ||
          job.id == 'data_entry') {
        if (!hasBasicIt && !hasData) {
          return 'Need Basic IT/Data Analytics or Tier1 Lv5';
        }
        return null;
      }
      if (job.id == 'retail' ||
          job.id == 'office_clerk' ||
          job.id == 'insurance') {
        if (!hasMgmt && !hasMarketing) {
          return 'Need Management/Marketing or Tier1 Lv5';
        }
        return null;
      }
    }

    if (JobCatalog.tier3.any((j) => j.id == job.id)) {
      final hasExp = JobCatalog.tier2.any((t) => _jobLevel(t, vm) >= 8);
      if (hasExp) return null;
      if (job.id == 'freelance' ||
          job.id == 'it_admin' ||
          job.id == 'architect') {
        if (!hasProg && !hasData) {
          return 'Need Programming/Data Analytics or Tier2 Lv8';
        }
        return null;
      }
      if (job.id == 'office' ||
          job.id == 'accountant' ||
          job.id == 'marketing') {
        if (!hasBiz && !hasMarketing) {
          return 'Need Business/Marketing or Tier2 Lv8';
        }
        return null;
      }
    }

    return null;
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
                            'Lv ${_jobLevel(activeJob, vm)}/${activeJob.maxLevel}',
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
                          _expBar(
                            _jobExpForLevel(activeJob, vm),
                            activeJob.expPerLevel,
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
            _tierSection(
              'Entry Level',
              Icons.restaurant,
              Colors.grey,
              JobCatalog.tier1,
              vm,
              activeJob,
            ),
            _tierSection(
              'Office & Service',
              Icons.business_center,
              Colors.blue,
              JobCatalog.tier2,
              vm,
              activeJob,
            ),
            _tierSection(
              'Professional',
              Icons.star,
              Colors.amber,
              JobCatalog.tier3,
              vm,
              activeJob,
            ),
          ],
        ),
      ),
    );
  }

  Widget _tierSection(
    String title,
    IconData icon,
    Color color,
    List<Job> jobs,
    GameViewModel vm,
    Job? activeJob,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        ...jobs.map((j) {
          final income = _jobIncome(j, vm);
          final req = _jobRequirement(j, vm);
          final locked = req != null;
          final level = _jobLevel(j, vm);
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 2),
            color: locked ? Colors.grey.shade100 : null,
            child: ListTile(
              title: Row(
                children: [
                  Text(
                    j.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: locked ? Colors.grey.shade500 : null,
                    ),
                  ),
                  if (level > 0) ...[
                    const SizedBox(width: 6),
                    Text(
                      'Lv$level',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue.shade400,
                      ),
                    ),
                  ],
                ],
              ),
              subtitle: locked
                  ? Text(
                      req,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red.shade400,
                      ),
                    )
                  : Text(
                      '\$${income.toStringAsFixed(2)}/min  •  ${j.description}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: locked ? Colors.grey : Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  textStyle: const TextStyle(fontSize: 11),
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
            ),
          );
        }),
      ],
    );
  }

  Widget _expBar(int exp, int maxExp) => Expanded(
    child: ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
        value: exp / maxExp,
        minHeight: 6,
        backgroundColor: Colors.grey.shade200,
        valueColor: const AlwaysStoppedAnimation(Colors.blue),
      ),
    ),
  );
}
