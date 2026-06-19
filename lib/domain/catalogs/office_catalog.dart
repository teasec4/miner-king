class Office {
  final String id;
  final String name;
  final int price;
  final double rentPerTick;
  final int slots;

  const Office({
    required this.id,
    required this.name,
    required this.price,
    required this.rentPerTick,
    required this.slots,
  });
}

class OfficeCatalog {
  OfficeCatalog._();

  static const small = Office(
    id: 'office_small',
    name: 'Small Office',
    price: 5000,
    rentPerTick: 0.02,
    slots: 2,
  );
  static const medium = Office(
    id: 'office_medium',
    name: 'Medium Office',
    price: 20000,
    rentPerTick: 0.05,
    slots: 4,
  );
  static const large = Office(
    id: 'office_large',
    name: 'Large Office',
    price: 100000,
    rentPerTick: 0.15,
    slots: 8,
  );

  static final all = [small, medium, large];
  static Office? byId(String id) {
    try {
      return all.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
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
  trader, // market-based income
  sales, // fixed income
  miner, // +% hashrate
  repair, // -% wear rate
}

class EmployeeCatalog {
  EmployeeCatalog._();

  static const analyst = Employee(
    id: 'crypto_analyst',
    name: 'Crypto Analyst',
    salaryPerTick: 0.02,
    description: 'Auto-trades based on market mood',
    effect: EmployeeEffect.trader,
    effectValue: 0.025,
  );
  static const sales = Employee(
    id: 'sales_manager',
    name: 'Sales Manager',
    salaryPerTick: 0.023,
    description: 'Stable income, market-proof',
    effect: EmployeeEffect.sales,
    effectValue: 0.028,
  );
  static const supervisor = Employee(
    id: 'mining_supervisor',
    name: 'Mining Supervisor',
    salaryPerTick: 0.03,
    description: '+15% hashrate to all GPUs',
    effect: EmployeeEffect.miner,
    effectValue: 0.15,
  );
  static const repairTech = Employee(
    id: 'repair_tech',
    name: 'Repair Tech',
    salaryPerTick: 0.015,
    description: '-30% wear on all GPUs',
    effect: EmployeeEffect.repair,
    effectValue: 0.3,
  );

  static final all = [analyst, sales, supervisor, repairTech];
  static Employee? byId(String id) {
    try {
      return all.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}
