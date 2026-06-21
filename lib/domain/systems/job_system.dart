import '../catalogs/job_catalog.dart';
import '../config/game_config.dart';
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

    int totalExp = 0;
    for (final j in path) {
      totalExp += game.jobExperience[j.id] ?? 0;
    }
    final expGain = game.character == CharacterType.hustler
        ? GameConfig.hustlerExpMultiplier.toInt()
        : 1;
    totalExp += expGain;

    final level = (totalExp ~/ job.expPerLevel).clamp(0, path.length - 1);
    final title = path[level];

    final newExp = Map<String, int>.from(game.jobExperience);
    newExp[jobId] = (newExp[jobId] ?? 0) + expGain;

    var newJobId = jobId;
    if (title.id != jobId) {
      newJobId = title.id;
    }

    final multiplier = 1.0 + level * GameConfig.levelIncomeMultiplier;
    var diplomaBonus = 1.0;
    switch (pathName) {
      case 'Tech & IT':
        if (game.completedCourses.contains('basic_it'))
          diplomaBonus += GameConfig.diplomaBonusPerCourse;
        if (game.completedCourses.contains('data_analytics'))
          diplomaBonus += GameConfig.diplomaBonusPerCourse;
        if (game.completedCourses.contains('programming'))
          diplomaBonus += GameConfig.diplomaBonusPerCourse;
      case 'Business & Finance':
        if (game.completedCourses.contains('management'))
          diplomaBonus += GameConfig.diplomaBonusPerCourse;
        if (game.completedCourses.contains('data_analytics'))
          diplomaBonus += GameConfig.diplomaBonusPerCourse;
        if (game.completedCourses.contains('marketing'))
          diplomaBonus += GameConfig.diplomaBonusPerCourse;
      case 'Creative & Media':
        if (game.completedCourses.contains('marketing'))
          diplomaBonus += GameConfig.diplomaBonusPerCourse;
      case 'Engineering':
        if (game.completedCourses.contains('programming'))
          diplomaBonus += GameConfig.diplomaBonusPerCourse;
      default:
    }
    if (game.completedCourses.contains('business'))
      diplomaBonus += GameConfig.diplomaBonusGlobal;

    final fairBonus = game.activeEvents.any((e) => e.id == 'job_fair')
        ? GameConfig.jobFairMultiplier
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
