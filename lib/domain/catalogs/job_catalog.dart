/// Simple job: player works for salary, gains experience.
class Job {
  final String id;
  final String name;
  final String description;
  final double salaryPerTick;
  final int maxLevel; // 0 = infinite
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

  // Tier 1 — no requirements
  static const fastFood = Job(
    id: 'fast_food',
    name: 'Fast Food',
    description: 'Flip burgers. Easy money.',
    salaryPerTick: 0.01,
  );
  static const courier = Job(
    id: 'courier',
    name: 'Courier',
    description: 'Deliver packages across town.',
    salaryPerTick: 0.011,
  );

  // Tier 2 — need Lv5 in any Tier 1
  static const techSupport = Job(
    id: 'tech_support',
    name: 'Tech Support',
    description: 'Help people reset routers.',
    salaryPerTick: 0.015,
  );
  static const retail = Job(
    id: 'retail',
    name: 'Retail',
    description: 'Manage a small store.',
    salaryPerTick: 0.016,
  );

  // Tier 3 — need Lv7 in Tier 2
  static const freelance = Job(
    id: 'freelance',
    name: 'Freelance Dev',
    description: 'Code for clients. Good pay.',
    salaryPerTick: 0.022,
    maxLevel: 15,
  );
  static const office = Job(
    id: 'office',
    name: 'Office Manager',
    description: 'Run an office team.',
    salaryPerTick: 0.025,
    maxLevel: 15,
  );

  static final all = [
    fastFood,
    courier,
    techSupport,
    retail,
    freelance,
    office,
  ];

  static Job? byId(String id) {
    try {
      return all.firstWhere((j) => j.id == id);
    } catch (_) {
      return null;
    }
  }
}
