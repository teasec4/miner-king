import '../config/game_config.dart';
import '../catalogs/course_catalog.dart';
import '../models/game.dart';
import '../models/player_profile.dart';
import 'dart:math';

class CourseSystem {
  CourseSystem._();

  static final _random = Random();

  static Game update(Game game) {
    final courseId = game.activeCourseId;
    if (courseId == null) return game;

    final course = CourseCatalog.byId(courseId);
    if (course == null) return game;

    var speed = game.character == CharacterType.student
        ? GameConfig.studentCourseSpeedup
        : 1.0;

    // Cram Study: ×2 speed, risk of burnout
    if (game.isCramStudy) {
      speed *= GameConfig.cramStudySpeedMultiplier;
    }

    var left = (game.courseTicksLeft - speed).ceil().clamp(0, 999999);
    var milestone = game.courseMilestone;
    var awarded = game.courseAwardedMilestones;
    var isCramStudy = game.isCramStudy;

    // Cram Study burnout check: reset to previous milestone
    if (game.isCramStudy &&
        milestone > 0 &&
        _random.nextDouble() < GameConfig.cramStudyBurnoutChance) {
      // Burnout! Reset to previous milestone
      milestone--;
      isCramStudy = false; // can't cram again without re-enrolling
      final prevThreshold =
          (course.milestones[milestone] * course.durationTicks).ceil();
      left = (course.durationTicks - prevThreshold).clamp(0, 999999);
    }

    // Check for new milestones
    final elapsed = course.durationTicks - left;
    final progress = elapsed / course.durationTicks;
    var money = game.money;

    while (awarded < course.milestones.length &&
        progress >= course.milestones[awarded]) {
      final bonus = course.milestoneBonuses[awarded];
      money += bonus;
      awarded++;
    }
    milestone = awarded;

    if (left <= 0) {
      // Course completed!
      final completed = [...game.completedCourses, courseId];
      return game.copyWith(
        money: money,
        completedCourses: completed,
        activeCourseId: null,
        courseTicksLeft: 0,
        courseMilestone: 0,
        courseAwardedMilestones: awarded,
        isCramStudy: false,
      );
    }

    return game.copyWith(
      money: money,
      courseTicksLeft: left,
      courseMilestone: milestone,
      courseAwardedMilestones: awarded,
      isCramStudy: isCramStudy,
    );
  }
}
