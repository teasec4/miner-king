import '../catalogs/job_catalog.dart';
import '../config/game_config.dart';
import '../models/game.dart';
import '../models/player_profile.dart';
import '../models/specialization.dart';

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

    var finalSalary =
        title.salaryPerTick * multiplier * diplomaBonus * fairBonus;

    // Specialization effects
    switch (game.specialization) {
      case Specialization.miningTycoon:
        finalSalary *= GameConfig.tycoonJobPenalty;
      case Specialization.careerClimber:
        finalSalary *= GameConfig.climberJobMultiplier;
      default:
    }

    return game.copyWith(
      money: game.money + finalSalary,
      jobExperience: newExp,
      activeJobId: newJobId,
    );
  }

  /// Check if player has reached level 3 in a given job path.
  static bool _hasPathLevel(Game game, List<Job> path, int minLevel) {
    var totalExp = 0;
    for (final job in path) {
      totalExp += game.jobExperience[job.id] ?? 0;
    }
    return totalExp >= path.first.expPerLevel * minLevel;
  }

  /// Tech & IT Lv3: -10% electricity.
  static double electricityDiscount(Game game) {
    return _hasPathLevel(game, JobCatalog.paths['Tech & IT']!, 3)
        ? GameConfig.techPerkElectricityDiscount
        : 0;
  }

  /// Business & Finance Lv3: +10% sell price.
  static double sellPriceBonus(Game game) {
    return _hasPathLevel(game, JobCatalog.paths['Business & Finance']!, 3)
        ? GameConfig.bizPerkSellBonus
        : 0;
  }

  /// Engineering Lv3: +5% hashrate.
  static double hashrateBonus(Game game) {
    return _hasPathLevel(game, JobCatalog.paths['Engineering']!, 3)
        ? GameConfig.engPerkHashrateBonus
        : 0;
  }
}
