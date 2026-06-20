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

  // Career path titles (ascending levels within each path)
  // Each level = new title, higher salary

  static final foodTitles = [
    Job(
      id: 'food_l1',
      name: 'Waiter',
      description: 'Take orders. Carry plates.',
      salaryPerTick: 0.008,
    ),
    Job(
      id: 'food_l2',
      name: 'Cook',
      description: 'Work the kitchen line.',
      salaryPerTick: 0.012,
    ),
    Job(
      id: 'food_l3',
      name: 'Sous Chef',
      description: 'Run the kitchen team.',
      salaryPerTick: 0.018,
    ),
    Job(
      id: 'food_l4',
      name: 'Restaurant Manager',
      description: 'Manage the whole place.',
      salaryPerTick: 0.025,
    ),
  ];

  static final techTitles = [
    Job(
      id: 'tech_l1',
      name: 'Helpdesk',
      description: 'Have you tried turning it off?',
      salaryPerTick: 0.010,
    ),
    Job(
      id: 'tech_l2',
      name: 'IT Support',
      description: 'Fix computers. Reset passwords.',
      salaryPerTick: 0.015,
    ),
    Job(
      id: 'tech_l3',
      name: 'SysAdmin',
      description: 'Manage servers and networks.',
      salaryPerTick: 0.022,
    ),
    Job(
      id: 'tech_l4',
      name: 'DevOps Engineer',
      description: 'Automate everything.',
      salaryPerTick: 0.030,
    ),
    Job(
      id: 'tech_l5',
      name: 'CTO',
      description: 'Run the tech department.',
      salaryPerTick: 0.040,
    ),
  ];

  static final businessTitles = [
    Job(
      id: 'biz_l1',
      name: 'Clerk',
      description: 'File papers. Make copies.',
      salaryPerTick: 0.009,
    ),
    Job(
      id: 'biz_l2',
      name: 'Accountant',
      description: 'Crunch numbers.',
      salaryPerTick: 0.014,
    ),
    Job(
      id: 'biz_l3',
      name: 'Financial Analyst',
      description: 'Analyze markets.',
      salaryPerTick: 0.021,
    ),
    Job(
      id: 'biz_l4',
      name: 'CFO',
      description: 'Run company finances.',
      salaryPerTick: 0.032,
    ),
  ];

  static final creativeTitles = [
    Job(
      id: 'cr_l1',
      name: 'Copywriter',
      description: 'Write ads and posts.',
      salaryPerTick: 0.009,
    ),
    Job(
      id: 'cr_l2',
      name: 'Designer',
      description: 'Create visuals.',
      salaryPerTick: 0.013,
    ),
    Job(
      id: 'cr_l3',
      name: 'Art Director',
      description: 'Lead creative projects.',
      salaryPerTick: 0.020,
    ),
    Job(
      id: 'cr_l4',
      name: 'Creative Director',
      description: 'Run the agency.',
      salaryPerTick: 0.028,
    ),
  ];

  static final engineeringTitles = [
    Job(
      id: 'eng_l1',
      name: 'Junior Dev',
      description: 'Learn the codebase.',
      salaryPerTick: 0.011,
    ),
    Job(
      id: 'eng_l2',
      name: 'Developer',
      description: 'Build features.',
      salaryPerTick: 0.017,
    ),
    Job(
      id: 'eng_l3',
      name: 'Senior Dev',
      description: 'Lead sprints. Mentor juniors.',
      salaryPerTick: 0.025,
    ),
    Job(
      id: 'eng_l4',
      name: 'Tech Lead',
      description: 'Architect systems.',
      salaryPerTick: 0.035,
    ),
    Job(
      id: 'eng_l5',
      name: 'Software Architect',
      description: 'Design everything. Big money.',
      salaryPerTick: 0.048,
    ),
  ];

  static final Map<String, List<Job>> paths = {
    'Food & Service': foodTitles,
    'Tech & IT': techTitles,
    'Business & Finance': businessTitles,
    'Creative & Media': creativeTitles,
    'Engineering': engineeringTitles,
  };

  static final all = [
    ...foodTitles,
    ...techTitles,
    ...businessTitles,
    ...creativeTitles,
    ...engineeringTitles,
  ];

  static Job? byId(String id) {
    try {
      return all.firstWhere((j) => j.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Find the title for a given path and level.
  static Job? titleForPath(List<Job> path, int level) {
    if (level < 0) return path.first;
    final idx = level.clamp(0, path.length - 1);
    return path[idx];
  }
}
