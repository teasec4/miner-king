/// Simple job: player works for salary, gains experience, farms slower.
class Job {
  final String id;
  final String name;
  final double salaryPerTick;
  final String description;

  const Job({
    required this.id,
    required this.name,
    required this.salaryPerTick,
    required this.description,
  });
}

class JobCatalog {
  JobCatalog._();

  static const fastFood = Job(
    id: 'fast_food',
    name: 'Fast Food',
    salaryPerTick: 0.01,
    description: 'Flip burgers. Easy money.',
  );
  static const techSupport = Job(
    id: 'tech_support',
    name: 'Tech Support',
    salaryPerTick: 0.015,
    description: 'Help people reset routers.',
  );
  static const freelance = Job(
    id: 'freelance',
    name: 'Freelance Dev',
    salaryPerTick: 0.02,
    description: 'Code for clients. Good pay.',
  );

  static final all = [fastFood, techSupport, freelance];
  static Job? byId(String id) {
    try {
      return all.firstWhere((j) => j.id == id);
    } catch (_) {
      return null;
    }
  }
}
