class Course {
  final String id;
  final String name;
  final int price;
  final int durationTicks;
  final String unlocks;
  final List<String> requiresCourse;

  const Course({
    required this.id,
    required this.name,
    required this.price,
    required this.durationTicks,
    required this.unlocks,
    this.requiresCourse = const [],
  });

  String get durationLabel {
    final mins = durationTicks ~/ 60;
    if (mins < 1) return '${durationTicks}s';
    return '${mins}min';
  }
}

class CourseCatalog {
  CourseCatalog._();

  static const basicIt = Course(
    id: 'basic_it',
    name: 'Basic IT',
    price: 500,
    durationTicks: 180,
    unlocks: 'Unlocks Tech Support, Call Center',
  );
  static const management = Course(
    id: 'management',
    name: 'Management 101',
    price: 800,
    durationTicks: 240,
    unlocks: 'Unlocks Retail, Office Clerk',
  );
  static const dataAnalytics = Course(
    id: 'data_analytics',
    name: 'Data Analytics',
    price: 1000,
    durationTicks: 300,
    unlocks: 'Unlocks Data Entry, Soft. Architect',
    requiresCourse: ['basic_it'],
  );
  static const marketingCourse = Course(
    id: 'marketing',
    name: 'Marketing',
    price: 1200,
    durationTicks: 300,
    unlocks: 'Unlocks Insurance, Marketing Dir.',
    requiresCourse: ['management'],
  );
  static const programming = Course(
    id: 'programming',
    name: 'Programming',
    price: 1500,
    durationTicks: 420,
    unlocks: 'Unlocks Freelance Dev, IT Admin',
    requiresCourse: ['basic_it'],
  );
  static const business = Course(
    id: 'business',
    name: 'Business Admin',
    price: 2000,
    durationTicks: 480,
    unlocks: 'Unlocks Office Manager, Accountant',
    requiresCourse: ['management'],
  );

  static final all = [
    basicIt,
    management,
    dataAnalytics,
    marketingCourse,
    programming,
    business,
  ];

  static Course? byId(String id) {
    try {
      return all.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
