import '../models/game.dart';
import '../models/player_profile.dart';

class CourseSystem {
  CourseSystem._();

  /// Tick active course progress. Complete it when done.
  static Game update(Game game) {
    final courseId = game.activeCourseId;
    if (courseId == null) return game;

    // Student: courses tick 25% faster (≈ -20% time)
    final ticks = game.character == CharacterType.student ? 1.25 : 1.0;
    final left = (game.courseTicksLeft - ticks).ceil().clamp(0, 999999);
    if (left <= 0) {
      // Course completed! Use constructor to null-ify activeCourseId
      final completed = [...game.completedCourses, courseId];
      return Game(
        money: game.money,
        holdings: game.holdings,
        coins: game.coins,
        electricityRate: game.electricityRate,
        farm: game.farm,
        activeModifiers: game.activeModifiers,
        activeEvents: game.activeEvents,
        activeLoans: game.activeLoans,
        activeInvestments: game.activeInvestments,
        properties: game.properties,
        marketMood: game.marketMood,
        loanRepayments: game.loanRepayments,
        activeJobId: game.activeJobId,
        jobExperience: game.jobExperience,
        completedCourses: completed,
        activeCourseId: null,
        courseTicksLeft: 0,
        employees: game.employees,
        officeId: game.officeId,
        unseenEvents: game.unseenEvents,
        employeePool: game.employeePool,
        nextPoolRefresh: game.nextPoolRefresh,
        character: game.character,
        perks: game.perks,
        tick: game.tick,
      );
    }
    return game.copyWith(courseTicksLeft: left);
  }
}
