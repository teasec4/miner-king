import '../catalogs/job_catalog.dart';
import '../models/game.dart';
import '../models/player_profile.dart';

class JobSystem {
  JobSystem._();

  /// Pay salary + gain exp if on a job.
  static Game update(Game game) {
    final jobId = game.activeJobId;
    if (jobId == null) return game;
    final job = JobCatalog.byId(jobId);
    if (job == null) return game;

    final newExp = Map<String, int>.from(game.jobExperience);
    final expGain = game.character == CharacterType.hustler ? 2 : 1;
    newExp[jobId] = (newExp[jobId] ?? 0) + expGain;

    // Experience bonus: each expPerLevel EXP = +10% income
    final exp = newExp[jobId] ?? 0;
    final level = (exp ~/ job.expPerLevel).clamp(0, job.maxLevel);
    final multiplier = 1.0 + level * 0.1;
    // Diploma bonus: check completed courses
    var diplomaBonus = 1.0;
    // Find which path this job belongs to
    for (final entry in JobCatalog.paths.entries) {
      final name = entry.key;
      final path = entry.value;
      if (path.any((j) => j.id == jobId)) {
        switch (name) {
          case 'Tech & IT':
            if (game.completedCourses.contains('basic_it')) {
              diplomaBonus += 0.20;
            }
            if (game.completedCourses.contains('data_analytics')) {
              diplomaBonus += 0.20;
            }
            if (game.completedCourses.contains('programming')) {
              diplomaBonus += 0.20;
            }
          case 'Business & Finance':
            if (game.completedCourses.contains('management')) {
              diplomaBonus += 0.20;
            }
            if (game.completedCourses.contains('data_analytics')) {
              diplomaBonus += 0.20;
            }
            if (game.completedCourses.contains('marketing')) {
              diplomaBonus += 0.20;
            }
          case 'Creative & Media':
            if (game.completedCourses.contains('marketing')) {
              diplomaBonus += 0.20;
            }
          case 'Engineering':
            if (game.completedCourses.contains('programming')) {
              diplomaBonus += 0.20;
            }
          default:
        }
        if (game.completedCourses.contains('business')) diplomaBonus += 0.25;
        break;
      }
    }
    // Job Fair event: double salary
    final fairBonus = game.activeEvents.any((e) => e.id == 'job_fair')
        ? 2.0
        : 1.0;

    return game.copyWith(
      money:
          game.money +
          job.salaryPerTick * multiplier * diplomaBonus * fairBonus,
      jobExperience: newExp,
    );
  }
}
