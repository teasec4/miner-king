import '../config/game_config.dart';
import '../catalogs/course_catalog.dart';
import '../catalogs/job_catalog.dart';
import '../catalogs/office_catalog.dart';
import '../models/game.dart';
import '../models/player_profile.dart';
import '../models/specialization.dart';

/// Pure functions for life operations: jobs, courses, office, employees, perks.
class LifeCommands {
  LifeCommands._();

  // ── Jobs ──

  static Game startJob(Game game, String jobId) {
    return game.copyWith(activeJobId: jobId);
  }

  static Game quitJob(Game game) {
    return game.copyWith(activeJobId: null);
  }

  // ── Courses ──

  static Game? enrollCourse(Game game, String courseId) {
    final course = CourseCatalog.byId(courseId);
    if (course == null) return null;
    var price = game.character == CharacterType.student
        ? (course.price * GameConfig.studentCourseDiscount).ceil()
        : course.price;
    price = GameConfig.applyShopDiscount(price, game.shopMultiplier);
    if (game.money < price) return null;
    if (game.activeCourseId != null) return null;
    if (game.completedCourses.contains(courseId)) return null;
    for (final req in course.requiresCourse) {
      if (!game.completedCourses.contains(req)) return null;
    }
    return game.copyWith(
      money: game.money - price,
      activeCourseId: courseId,
      courseTicksLeft: course.durationTicks,
      courseMilestone: 0,
    );
  }

  // ── Office ──

  static Game? buyOffice(Game game, String officeId) {
    final next = OfficeCatalog.nextTier(game.officeId);
    if (next == null || next.id != officeId) return null;
    final price = GameConfig.applyShopDiscount(next.price, game.shopMultiplier);
    if (game.money < price) return null;
    return game.copyWith(money: game.money - price, officeId: officeId);
  }

  static Game hireEmployee(Game game, String empId) {
    final office = game.officeId != null
        ? OfficeCatalog.byId(game.officeId!)
        : null;
    if (office == null) return game;
    if (game.employees.length >= office.slots) return game;
    if (game.employees.contains(empId)) return game;
    return game.copyWith(employees: [...game.employees, empId]);
  }

  static Game fireEmployee(Game game, String empId) {
    return game.copyWith(
      employees: game.employees.where((e) => e != empId).toList(),
    );
  }

  static Game refreshEmployeePool(Game game) {
    final all = EmployeeCatalog.all.map((e) => e.id).toList();
    all.shuffle();
    return game.copyWith(
      employeePool: all.take(all.length > 4 ? 4 : all.length).toList(),
      nextPoolRefresh: game.tick + GameConfig.employeePoolRefreshTicks,
    );
  }

  // ── Specialization ──

  /// Returns true if the player can pick a specialization right now.
  /// Requires: no specialization yet AND any job at level 3+.
  static bool canPickSpecialization(Game game) {
    if (game.specialization != null) return false;
    for (final entry in JobCatalog.paths.entries) {
      var totalExp = 0;
      for (final job in entry.value) {
        totalExp += game.jobExperience[job.id] ?? 0;
      }
      if (totalExp >= entry.value.first.expPerLevel * 3) return true;
    }
    return false;
  }

  static Game pickSpecialization(Game game, Specialization spec) {
    return game.copyWith(specialization: spec);
  }

  // ── Cram Study ──

  /// Activate cram study mode (+50% cost, ×2 speed, risk of burnout).
  static Game? activateCramStudy(Game game) {
    if (game.activeCourseId == null) return null;
    if (game.isCramStudy) return null;
    final course = CourseCatalog.byId(game.activeCourseId!);
    if (course == null) return null;
    final cost = (course.price * GameConfig.cramStudyCostMultiplier).ceil();
    if (game.money < cost) return null;
    return game.copyWith(money: game.money - cost, isCramStudy: true);
  }

  // ── Perks ──

  static Game? addPerk(Game game, Perk perk) {
    if (game.perks.any((p) => p.id == perk.id)) return null;
    var g = game;
    switch (perk.effect) {
      case PerkEffect.betterMobo:
        g = g.copyWith(
          farm: g.farm.copyWith(
            totalSlots: g.farm.totalSlots + GameConfig.betterMoboSlots,
          ),
        );
      case PerkEffect.cheapElectricity:
        g = g.copyWith(
          electricityRate:
              g.electricityRate * (1 - GameConfig.cheapElectricityDiscount),
        );
      default:
    }
    return g.copyWith(perks: [...g.perks, perk]);
  }
}
