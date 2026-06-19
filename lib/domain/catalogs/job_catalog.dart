class Job {
  final String id;
  final String name;
  final String description;
  final double salaryPerTick;
  final int maxLevel;
  final int expPerLevel;

  const Job({
    required this.id,
    required this.name,
    required this.description,
    required this.salaryPerTick,
    this.maxLevel = 10,
    this.expPerLevel = 100,
  });
}

class JobCatalog {
  JobCatalog._();

  // Tier 1 — Entry level (no requirements)
  static const fastFood = Job(
    id: 'fast_food',
    name: 'Fast Food',
    description: 'Flip burgers. Greasy but pays.',
    salaryPerTick: 0.01,
  );
  static const courier = Job(
    id: 'courier',
    name: 'Courier',
    description: 'Deliver packages across town.',
    salaryPerTick: 0.011,
  );
  static const janitor = Job(
    id: 'janitor',
    name: 'Janitor',
    description: 'Clean offices at night. Nobody sees you.',
    salaryPerTick: 0.009,
  );
  static const delivery = Job(
    id: 'delivery',
    name: 'Delivery Driver',
    description: 'Drive around town. Tips included.',
    salaryPerTick: 0.012,
  );
  static const barista = Job(
    id: 'barista',
    name: 'Barista',
    description: 'Make coffee. Deal with Karens.',
    salaryPerTick: 0.0095,
  );
  static const warehouse = Job(
    id: 'warehouse',
    name: 'Warehouse Worker',
    description: 'Lift boxes. Stay fit.',
    salaryPerTick: 0.0115,
  );

  static final tier1 = [
    fastFood,
    courier,
    janitor,
    delivery,
    barista,
    warehouse,
  ];

  // Tier 2 — Office/Service (need Tier1 Lv3 or diploma)
  static const techSupport = Job(
    id: 'tech_support',
    name: 'Tech Support',
    description: 'Have you tried turning it off and on again?',
    salaryPerTick: 0.015,
  );
  static const retail = Job(
    id: 'retail',
    name: 'Retail',
    description: 'Manage a small store. Talk to customers.',
    salaryPerTick: 0.016,
  );
  static const callCenter = Job(
    id: 'call_center',
    name: 'Call Center',
    description: 'Answer calls. Stay calm.',
    salaryPerTick: 0.014,
  );
  static const officeClerk = Job(
    id: 'office_clerk',
    name: 'Office Clerk',
    description: 'File papers. Drink coffee.',
    salaryPerTick: 0.017,
  );
  static const dataEntry = Job(
    id: 'data_entry',
    name: 'Data Entry',
    description: 'Type numbers. Listen to podcasts.',
    salaryPerTick: 0.0145,
  );
  static const insurance = Job(
    id: 'insurance',
    name: 'Insurance Agent',
    description: 'Sell policies. Smile a lot.',
    salaryPerTick: 0.0165,
  );

  static final tier2 = [
    techSupport,
    retail,
    callCenter,
    officeClerk,
    dataEntry,
    insurance,
  ];

  // Tier 3 — Professional (need Tier2 Lv5 or advanced diploma)
  static const freelance = Job(
    id: 'freelance',
    name: 'Freelance Dev',
    description: 'Code for clients. Good pay, flexible hours.',
    salaryPerTick: 0.022,
    maxLevel: 15,
  );
  static const officeManager = Job(
    id: 'office',
    name: 'Office Manager',
    description: 'Run an office team. Manage people.',
    salaryPerTick: 0.025,
    maxLevel: 15,
  );
  static const itAdmin = Job(
    id: 'it_admin',
    name: 'IT Admin',
    description: 'Manage servers. Keep everything running.',
    salaryPerTick: 0.023,
    maxLevel: 15,
  );
  static const accountant = Job(
    id: 'accountant',
    name: 'Accountant',
    description: 'Crunch numbers. Tax season is hell.',
    salaryPerTick: 0.026,
    maxLevel: 15,
  );
  static const architect = Job(
    id: 'architect',
    name: 'Software Architect',
    description: 'Design systems. Big salary.',
    salaryPerTick: 0.028,
    maxLevel: 15,
  );
  static const marketing = Job(
    id: 'marketing',
    name: 'Marketing Director',
    description: 'Run campaigns. Big budget.',
    salaryPerTick: 0.027,
    maxLevel: 15,
  );

  static final tier3 = [
    freelance,
    officeManager,
    itAdmin,
    accountant,
    architect,
    marketing,
  ];

  static final all = [...tier1, ...tier2, ...tier3];

  static Job? byId(String id) {
    try {
      return all.firstWhere((j) => j.id == id);
    } catch (_) {
      return null;
    }
  }
}
