import '../catalogs/office_catalog.dart';
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

      // Pay salary
      money -= emp.salaryPerTick;

      // Apply income-generating effects
      switch (emp.effect) {
        case EmployeeEffect.trader:
          // Can lose money in fear, profit in greed.
          // Range: mood=-1 → -40%, mood=+1 → +100% of base.
          // With FinTech synergy: bonus × 1.2
          final synergyMult = _synergyActive('fintech', hired) ? 1.20 : 1.0;
          final mood = game.marketMood;
          // Non-linear: 0.7× mood for moderate swings, amplified at extremes
          final factor = mood > 0
              ? mood * 0.7 + mood * mood * 0.3
              : mood * 0.7 - mood * mood * 0.3;
          money += emp.effectValue * factor * synergyMult;
          break;
        case EmployeeEffect.sales:
          money += emp.effectValue;
          break;
        case EmployeeEffect.miner:
        case EmployeeEffect.repair:
        case EmployeeEffect.electrician:
        case EmployeeEffect.security:
          // Applied in other systems (MiningSystem, WearSystem, ElectricitySystem, EventSystem)
          break;
      }
    }

    // Pay office rent
    final rentMult = game.activeEvents.any((e) => e.id == 'rent_hike')
        ? 2.0
        : 1.0;
    money -= office.rentPerTick * rentMult;

    return game.copyWith(money: money.clamp(0, double.infinity));
  }

  // ── Passive effects queried by other systems ──

  /// Returns hashrate bonus from supervisor (unique, 0 or 1 instance).
  static double hashrateBonus(Game game) {
    for (final empId in game.employees) {
      final emp = EmployeeCatalog.byId(empId);
      if (emp != null && emp.effect == EmployeeEffect.miner) {
        var base = emp.effectValue;
        // Optimized Mining synergy: bonus +5% hashrate
        if (_synergyActive('optimized', game.employees.toSet())) base += 0.05;
        return base;
      }
    }
    return 0;
  }

  /// Returns wear reduction from repair tech (unique).
  static double wearReduction(Game game) {
    for (final empId in game.employees) {
      final emp = EmployeeCatalog.byId(empId);
      if (emp != null && emp.effect == EmployeeEffect.repair) {
        var base = emp.effectValue;
        // Optimized Mining synergy: bonus -5% wear
        if (_synergyActive('optimized', game.employees.toSet())) base += 0.05;
        return base.clamp(0.0, 0.9);
      }
    }
    return 0;
  }

  /// Returns electricity cost reduction from electrician (unique).
  static double electricityReduction(Game game) {
    for (final empId in game.employees) {
      final emp = EmployeeCatalog.byId(empId);
      if (emp != null && emp.effect == EmployeeEffect.electrician) {
        var base = emp.effectValue;
        // Efficient Farm synergy: bonus -5% electricity
        if (_synergyActive('efficient', game.employees.toSet())) base += 0.05;
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
