import '../catalogs/job_catalog.dart';
import '../models/game.dart';

class JobSystem {
  JobSystem._();

  /// Pay salary + gain exp if on a job.
  static Game update(Game game) {
    final jobId = game.activeJobId;
    if (jobId == null) return game;
    final job = JobCatalog.byId(jobId);
    if (job == null) return game;

    final newExp = Map<String, int>.from(game.jobExperience);
    newExp[jobId] = (newExp[jobId] ?? 0) + 1;

    return game.copyWith(
      money: game.money + job.salaryPerTick,
      jobExperience: newExp,
    );
  }
}
