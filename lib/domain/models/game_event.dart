/// A game event — can be instant or last multiple ticks.
class GameEvent {
  final String id;
  final String name;
  final String description;
  final String category; // 'rig', 'market', 'city'
  final int durationTicks; // 0 = instant
  int remainingTicks;
  Map<String, dynamic>? data;

  GameEvent({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.durationTicks,
  }) : remainingTicks = durationTicks;

  bool get isExpired => durationTicks > 0 && remainingTicks <= 0;
  bool get isInstant => durationTicks == 0;

  GameEvent copyWith({int? remainingTicks, Map<String, dynamic>? data}) {
    final e = GameEvent(
      id: id,
      name: name,
      description: description,
      category: category,
      durationTicks: durationTicks,
    );
    e.remainingTicks = remainingTicks ?? this.remainingTicks;
    e.data = data ?? this.data;
    return e;
  }
}
