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
      // Course completed!
      final completed = [...game.completedCourses, courseId];
      return game.copyWith(
        activeCourseId: null,
        courseTicksLeft: 0,
        completedCourses: completed,
      );
    }
    return game.copyWith(courseTicksLeft: left);
  }
}
