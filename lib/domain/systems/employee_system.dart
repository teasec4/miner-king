import '../catalogs/office_catalog.dart';
import '../config/game_config.dart';
import '../models/game.dart';

class EmployeeSystem {
  EmployeeSystem._();

  /// Process one tick: pay salaries, apply income effects, pay rent.
  static Game update(Game game) {
    final officeId = game.officeId;
    if (officeId == null) return game;
    final office = OfficeCatalog.byId(officeId);
    if (office == null) return game;

    var money = game.money;
    final hired = game.employees.toSet();

    for (final empId in game.employees) {
      final emp = EmployeeCatalog.byId(empId);
      if (emp == null) continue;

      money -= emp.salaryPerTick;

      switch (emp.effect) {
        case EmployeeEffect.trader:
          final synergyMult = _synergyActive('fintech', hired)
              ? GameConfig.fintechSynergyMultiplier
              : 1.0;
          final mood = game.marketMood;
          final factor = mood > 0
              ? mood * GameConfig.traderLinearWeight +
                    mood * mood * GameConfig.traderQuadraticWeight
              : mood * GameConfig.traderLinearWeight -
                    mood * mood * GameConfig.traderQuadraticWeight;
          money += emp.effectValue * factor * synergyMult;
          break;
        case EmployeeEffect.sales:
          money += emp.effectValue;
          break;
        case EmployeeEffect.miner:
        case EmployeeEffect.repair:
        case EmployeeEffect.electrician:
        case EmployeeEffect.security:
          break;
      }
    }

    final rentMult = game.activeEvents.any((e) => e.id == 'rent_hike')
        ? GameConfig.rentHikeMultiplier
        : 1.0;
    money -= office.rentPerTick * rentMult;

    return game.copyWith(money: money);
  }

  // ── Passive effects queried by other systems ──

  static double hashrateBonus(Game game) {
    for (final empId in game.employees) {
      final emp = EmployeeCatalog.byId(empId);
      if (emp != null && emp.effect == EmployeeEffect.miner) {
        var base = emp.effectValue;
        if (_synergyActive('optimized', game.employees.toSet()))
          base += GameConfig.optimizedHashrateBonus;
        return base;
      }
    }
    return 0;
  }

  static double wearReduction(Game game) {
    for (final empId in game.employees) {
      final emp = EmployeeCatalog.byId(empId);
      if (emp != null && emp.effect == EmployeeEffect.repair) {
        var base = emp.effectValue;
        if (_synergyActive('optimized', game.employees.toSet()))
          base += GameConfig.optimizedWearBonus;
        return base.clamp(0.0, 0.9);
      }
    }
    return 0;
  }

  static double electricityReduction(Game game) {
    for (final empId in game.employees) {
      final emp = EmployeeCatalog.byId(empId);
      if (emp != null && emp.effect == EmployeeEffect.electrician) {
        var base = emp.effectValue;
        if (_synergyActive('efficient', game.employees.toSet()))
          base += GameConfig.efficientFarmBonus;
        return base;
      }
    }
    return 0;
  }

  /// Returns event risk reduction from security guard (unique).
  static double eventChanceReduction(Game game) {
    for (final empId in game.employees) {
      final emp = EmployeeCatalog.byId(empId);
      if (emp != null && emp.effect == EmployeeEffect.security) {
        return emp.effectValue;
      }
    }
    return 0;
  }

  /// Returns event duration reduction from security guard (unique).
  static double eventDurationReduction(Game game) {
    for (final empId in game.employees) {
      final emp = EmployeeCatalog.byId(empId);
      if (emp != null && emp.effect == EmployeeEffect.security) {
        return emp.effectValue;
      }
    }
    return 0;
  }

  static bool _synergyActive(String synergyId, Set<String> hired) {
    final syn = EmployeeSynergy.all.where((s) => s.id == synergyId).firstOrNull;
    if (syn == null) return false;
    return hired.contains(syn.empA) && hired.contains(syn.empB);
  }

  /// Active synergies for display.
  static List<EmployeeSynergy> activeSynergies(Game game) {
    return EmployeeSynergy.activeFor(game.employees.toSet());
  }
}
