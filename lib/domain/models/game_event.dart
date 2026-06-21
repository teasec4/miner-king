/// A game event — can be instant or last multiple ticks.
class GameEvent {
  final String id;
  final String name;
  final String description;
  final String category; // 'rig', 'market', 'city'
  final int durationTicks; // 0 = instant
  final int remainingTicks;
  final Map<String, dynamic>? data;

  GameEvent({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.durationTicks,
    int? remainingTicks,
    this.data,
  }) : remainingTicks = remainingTicks ?? durationTicks,
       assert(durationTicks >= 0, 'durationTicks must be >= 0');

  bool get isExpired => durationTicks > 0 && remainingTicks <= 0;
  bool get isInstant => durationTicks == 0;

  GameEvent copyWith({int? remainingTicks, Map<String, dynamic>? data}) {
    return GameEvent(
      id: id,
      name: name,
      description: description,
      category: category,
      durationTicks: durationTicks,
      remainingTicks: remainingTicks ?? this.remainingTicks,
      data: data ?? this.data,
    );
  }
}
