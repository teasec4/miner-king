import '../catalogs/office_catalog.dart';
import '../models/game.dart';

class EmployeeSystem {
  EmployeeSystem._();

  static Game update(Game game) {
    final officeId = game.officeId;
    if (officeId == null) return game;
    final office = OfficeCatalog.byId(officeId);
    if (office == null) return game;

    var money = game.money;

    for (final empId in game.employees) {
      final emp = EmployeeCatalog.byId(empId);
      if (emp == null) continue;

      // Pay salary
      money -= emp.salaryPerTick;

      // Apply effect
      switch (emp.effect) {
        case EmployeeEffect.trader:
          // Income based on market mood: base + mood bonus
          final moodBonus = 1.0 + game.marketMood * 0.5;
          money += emp.effectValue * moodBonus;
          break;
        case EmployeeEffect.sales:
          money += emp.effectValue;
          break;
        case EmployeeEffect.miner:
        case EmployeeEffect.repair:
          // Applied in other systems (MiningSystem, WearSystem)
          break;
      }
    }

    // Pay office rent
    money -= office.rentPerTick;

    return game.copyWith(money: money.clamp(0, double.infinity));
  }

  /// Returns combined hashrate bonus from mining supervisors (0.0-1.0).
  static double hashrateBonus(Game game) {
    double bonus = 0;
    for (final empId in game.employees) {
      final emp = EmployeeCatalog.byId(empId);
      if (emp != null && emp.effect == EmployeeEffect.miner) {
        bonus += emp.effectValue;
      }
    }
    return bonus;
  }

  /// Returns combined wear reduction from repair techs (0.0-1.0).
  static double wearReduction(Game game) {
    double reduction = 0;
    for (final empId in game.employees) {
      final emp = EmployeeCatalog.byId(empId);
      if (emp != null && emp.effect == EmployeeEffect.repair) {
        reduction += emp.effectValue;
      }
    }
    return reduction.clamp(0.0, 0.9);
  }
}
