import '../models/game.dart';

class CourseSystem {
  CourseSystem._();

  /// Tick active course progress. Complete it when done.
  static Game update(Game game) {
    final courseId = game.activeCourseId;
    if (courseId == null) return game;

    final left = game.courseTicksLeft - 1;
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
