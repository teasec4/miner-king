import '../catalogs/job_catalog.dart';
import '../models/game.dart';
import '../models/player_profile.dart';

class JobSystem {
  JobSystem._();

  /// Pay salary + gain exp + auto-promote on level up.
  static Game update(Game game) {
    final jobId = game.activeJobId;
    if (jobId == null) return game;

    final job = JobCatalog.byId(jobId);
    if (job == null) return game;

    // Find which path this job belongs to
    String? pathName;
    List<Job>? path;
    for (final entry in JobCatalog.paths.entries) {
      if (entry.value.any((j) => j.id == jobId)) {
        pathName = entry.key;
        path = entry.value;
        break;
      }
    }
    if (pathName == null || path == null) return game;

    // Use path-level EXP (sum of all job EXPs in the path)
    int totalExp = 0;
    for (final j in path) {
      totalExp += game.jobExperience[j.id] ?? 0;
    }
    final expGain = game.character == CharacterType.hustler ? 2 : 1;
    totalExp += expGain;

    // Calculate level from total EXP
    final level = (totalExp ~/ job.expPerLevel).clamp(0, path.length - 1);
    final title = path[level];

    // Distribute EXP to the current title's ID (for tracking)
    final newExp = Map<String, int>.from(game.jobExperience);
    newExp[jobId] = (newExp[jobId] ?? 0) + expGain;

    // Auto-promote to new title if level advanced
    var newJobId = jobId;
    if (title.id != jobId) {
      newJobId = title.id;
    }

    // Income multiplier: +10% per level
    final multiplier = 1.0 + level * 0.1;
    var diplomaBonus = 1.0;
    // Diploma bonus calculation
    switch (pathName) {
      case 'Tech & IT':
        if (game.completedCourses.contains('basic_it')) diplomaBonus += 0.20;
        if (game.completedCourses.contains('data_analytics'))
          diplomaBonus += 0.20;
        if (game.completedCourses.contains('programming')) diplomaBonus += 0.20;
      case 'Business & Finance':
        if (game.completedCourses.contains('management')) diplomaBonus += 0.20;
        if (game.completedCourses.contains('data_analytics'))
          diplomaBonus += 0.20;
        if (game.completedCourses.contains('marketing')) diplomaBonus += 0.20;
      case 'Creative & Media':
        if (game.completedCourses.contains('marketing')) diplomaBonus += 0.20;
      case 'Engineering':
        if (game.completedCourses.contains('programming')) diplomaBonus += 0.20;
      default:
    }
    if (game.completedCourses.contains('business')) diplomaBonus += 0.25;

    final fairBonus = game.activeEvents.any((e) => e.id == 'job_fair')
        ? 2.0
        : 1.0;

    return game.copyWith(
      money:
          game.money +
          title.salaryPerTick * multiplier * diplomaBonus * fairBonus,
      jobExperience: newExp,
      activeJobId: newJobId,
    );
  }
}
