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

    return game.copyWith(
      money: game.money + job.salaryPerTick * multiplier,
      jobExperience: newExp,
    );
  }
}
