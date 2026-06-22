class Office {
  final String id;
  final String name;
  final int price;
  final double rentPerTick;
  final int slots;

  /// Next tier id (null if max level).
  final String? nextId;

  const Office({
    required this.id,
    required this.name,
    required this.price,
    required this.rentPerTick,
    required this.slots,
    this.nextId,
  });
}

class OfficeCatalog {
  OfficeCatalog._();

  /// Sequential upgrade path: 1 → 2 → 4 slots.
  static const small = Office(
    id: 'office_small',
    name: 'Small Office',
    price: 1500,
    rentPerTick: 0.02,
    slots: 1,
    nextId: 'office_medium',
  );
  static const medium = Office(
    id: 'office_medium',
    name: 'Medium Office',
    price: 8000,
    rentPerTick: 0.04,
    slots: 2,
    nextId: 'office_large',
  );
  static const large = Office(
    id: 'office_large',
    name: 'Large Office',
    price: 40000,
    rentPerTick: 0.10,
    slots: 4,
  );

  static final all = [small, medium, large];
  static Office? byId(String id) {
    try {
      return all.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Next upgrade from current office.
  static Office? nextTier(String? currentId) {
    if (currentId == null) return small;
    final current = byId(currentId);
    if (current?.nextId == null) return null;
    return byId(current!.nextId!);
  }
}

class Employee {
  final String id;
  final String name;
  final double salaryPerTick;
  final String description;
  final EmployeeEffect effect;
  final double effectValue;

  const Employee({
    required this.id,
    required this.name,
    required this.salaryPerTick,
    required this.description,
    required this.effect,
    required this.effectValue,
  });
}

enum EmployeeEffect {
  trader, // market-based income with downside risk
  sales, // fixed stable income
  miner, // +% hashrate (unique, doesn't stack)
  repair, // -% wear rate (unique)
  electrician, // -% electricity cost (unique)
  security, // reduced event chance & duration (unique)
}

/// Synergy bonuses between pairs of employees.
class EmployeeSynergy {
  final String id;
  final String empA;
  final String empB;
  final String label;
  final double bonus;

  const EmployeeSynergy({
    required this.id,
    required this.empA,
    required this.empB,
    required this.label,
    required this.bonus,
  });

  static const fintech = EmployeeSynergy(
    id: 'fintech',
    empA: 'crypto_analyst',
    empB: 'sales_manager',
    label: 'FinTech Synergy',
    bonus: 0.20,
  );
  static const optimized = EmployeeSynergy(
    id: 'optimized',
    empA: 'mining_supervisor',
    empB: 'repair_tech',
    label: 'Optimized Mining',
    bonus: 0.05,
  );
  static const efficient = EmployeeSynergy(
    id: 'efficient',
    empA: 'electrician',
    empB: 'mining_supervisor',
    label: 'Efficient Farm',
    bonus: 0.05,
  );

  static final all = [fintech, optimized, efficient];

  /// Returns active synergies given a set of hired employee IDs.
  static List<EmployeeSynergy> activeFor(Set<String> hired) {
    return all
        .where((s) => hired.contains(s.empA) && hired.contains(s.empB))
        .toList();
  }
}

class EmployeeCatalog {
  EmployeeCatalog._();

  // ── Original roles (rebalanced) ──

  static const analyst = Employee(
    id: 'crypto_analyst',
    name: 'Crypto Analyst',
    salaryPerTick: 0.015, // $0.90/min
    description: 'Trades on market mood. Profit in greed, loss in fear.',
    effect: EmployeeEffect.trader,
    effectValue: 0.08, // base income ± mood multiplier
  );
  static const sales = Employee(
    id: 'sales_manager',
    name: 'Sales Manager',
    salaryPerTick: 0.020, // $1.20/min
    description: 'Steady revenue, no surprises.',
    effect: EmployeeEffect.sales,
    effectValue: 0.025, // $1.50/min
  );
  static const supervisor = Employee(
    id: 'mining_supervisor',
    name: 'Mining Supervisor',
    salaryPerTick: 0.040, // $2.40/min
    description: '+12% hashrate (unique, non-stacking)',
    effect: EmployeeEffect.miner,
    effectValue: 0.12,
  );
  static const repairTech = Employee(
    id: 'repair_tech',
    name: 'Repair Tech',
    salaryPerTick: 0.010, // $0.60/min
    description: '-25% wear (unique, non-stacking)',
    effect: EmployeeEffect.repair,
    effectValue: 0.25,
  );

  // ── New roles ──

  static const electrician = Employee(
    id: 'electrician',
    name: 'Electrician',
    salaryPerTick: 0.015, // $0.90/min
    description: '-15% electricity cost (unique)',
    effect: EmployeeEffect.electrician,
    effectValue: 0.15,
  );
  static const security = Employee(
    id: 'security_guard',
    name: 'Security Guard',
    salaryPerTick: 0.010, // $0.60/min
    description: '-30% rig event chance & duration (unique)',
    effect: EmployeeEffect.security,
    effectValue: 0.30,
  );

  static final all = [
    analyst,
    sales,
    supervisor,
    repairTech,
    electrician,
    security,
  ];
  static Employee? byId(String id) {
    try {
      return all.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}
