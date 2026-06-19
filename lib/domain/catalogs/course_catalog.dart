class Course {
  final String id;
  final String name;
  final int price;
  final int durationTicks; // 1 tick = 1 second
  final String unlocks; // description of what it unlocks
  final List<String> requiresCourse; // prerequisite course IDs

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
    price: 300,
    durationTicks: 120,
    unlocks: 'Unlocks Tech Support',
  );
  static const management = Course(
    id: 'management',
    name: 'Management 101',
    price: 500,
    durationTicks: 180,
    unlocks: 'Unlocks Retail',
  );
  static const programming = Course(
    id: 'programming',
    name: 'Programming',
    price: 800,
    durationTicks: 300,
    unlocks: 'Unlocks Freelance Dev',
    requiresCourse: ['basic_it'],
  );
  static const business = Course(
    id: 'business',
    name: 'Business Admin',
    price: 1000,
    durationTicks: 360,
    unlocks: 'Unlocks Office Manager',
    requiresCourse: ['management'],
  );

  static final all = [basicIt, management, programming, business];

  static Course? byId(String id) {
    try {
      return all.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
