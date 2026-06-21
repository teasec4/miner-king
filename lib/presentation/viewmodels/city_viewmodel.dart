import 'package:crypto_king/data/game_state.dart';
import 'package:crypto_king/domain/catalogs/job_catalog.dart';
import 'package:crypto_king/domain/catalogs/office_catalog.dart';
import 'package:crypto_king/domain/config/game_config.dart';
import 'package:crypto_king/domain/models/game.dart';
import 'package:crypto_king/domain/systems/employee_system.dart';

/// ViewModel for the City tab: jobs, courses, office, employees.
class CityViewModel {
  final GameState state;
  CityViewModel(this.state);
  Game get game => state.game;

  // ── Jobs ──

  String? get activeJobId => game.activeJobId;
  int jobExp(String jobId) => game.jobExperience[jobId] ?? 0;

  void startJob(String id) => state.startJob(id);
  void quitJob() => state.quitJob();

  double get jobIncomePerMin {
    final id = game.activeJobId;
    if (id == null) return 0;
    for (final entry in JobCatalog.paths.entries) {
      final path = entry.value;
      if (path.any((j) => j.id == id)) {
        int totalExp = 0;
        for (final j in path) {
          totalExp += game.jobExperience[j.id] ?? 0;
        }
        final job = JobCatalog.byId(id)!;
        final level = (totalExp ~/ job.expPerLevel).clamp(0, path.length - 1);
        return path[level].salaryPerTick *
            60 *
            (1.0 + level * GameConfig.levelIncomeMultiplier) *
            _diplomaBonus(entry.key);
      }
    }
    return 0;
  }

  double _diplomaBonus(String pathName) {
    double bonus = 1.0;
    final courses = game.completedCourses;
    switch (pathName) {
      case 'Tech & IT':
        if (courses.contains('basic_it'))
          bonus += GameConfig.diplomaBonusPerCourse;
        if (courses.contains('data_analytics'))
          bonus += GameConfig.diplomaBonusPerCourse;
        if (courses.contains('programming'))
          bonus += GameConfig.diplomaBonusPerCourse;
      case 'Business & Finance':
        if (courses.contains('management'))
          bonus += GameConfig.diplomaBonusPerCourse;
        if (courses.contains('data_analytics'))
          bonus += GameConfig.diplomaBonusPerCourse;
        if (courses.contains('marketing'))
          bonus += GameConfig.diplomaBonusPerCourse;
      case 'Creative & Media':
        if (courses.contains('marketing'))
          bonus += GameConfig.diplomaBonusPerCourse;
      case 'Engineering':
        if (courses.contains('programming'))
          bonus += GameConfig.diplomaBonusPerCourse;
      default:
    }
    if (courses.contains('business')) bonus += GameConfig.diplomaBonusGlobal;
    return bonus;
  }

  // ── Education ──

  String? get activeCourseId => game.activeCourseId;
  int get courseTicksLeft => game.courseTicksLeft;
  List<String> get completedCourses => game.completedCourses;
  bool enrollCourse(String id) => state.enrollCourse(id);

  // ── Office ──

  String? get officeId => game.officeId;
  List<String> get employees => game.employees;
  List<String> get employeePool => game.employeePool;
  int get nextPoolRefresh => game.nextPoolRefresh;
  int get poolRefreshIn => (game.nextPoolRefresh - game.tick).clamp(0, 9999);
  List<Employee> get availableEmployees => game.employeePool
      .map((id) => EmployeeCatalog.byId(id))
      .whereType<Employee>()
      .toList();
  List<EmployeeSynergy> get activeSynergies =>
      EmployeeSystem.activeSynergies(_game);

  int get officeSlots {
    final id = game.officeId;
    if (id == null) return 0;
    return OfficeCatalog.byId(id)?.slots ?? 0;
  }

  bool buyOffice(String id) => state.buyOffice(id);
  bool hireEmployee(String id) => state.hireEmployee(id);
  void fireEmployee(String id) => state.fireEmployee(id);
  void refreshEmployeePool() => state.refreshEmployeePool();
}
