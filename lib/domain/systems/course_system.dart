import '../config/game_config.dart';
import '../models/game.dart';
import '../models/player_profile.dart';

class CourseSystem {
  CourseSystem._();

  static Game update(Game game) {
    final courseId = game.activeCourseId;
    if (courseId == null) return game;

    final ticks = game.character == CharacterType.student
        ? GameConfig.studentCourseSpeedup
        : 1.0;
    final left = (game.courseTicksLeft - ticks).ceil().clamp(0, 999999);
    if (left <= 0) {
      // Course completed!
      final completed = [...game.completedCourses, courseId];
      return game.copyWith(
        completedCourses: completed,
        activeCourseId: null,
        courseTicksLeft: 0,
      );
    }
    return game.copyWith(courseTicksLeft: left);
  }
}
