/// A game event — can be instant or last multiple ticks.
class GameEvent {
  final String id;
  final String name;
  final String description;
  final int durationTicks; // 0 = instant
  int remainingTicks;

  GameEvent({
    required this.id,
    required this.name,
    required this.description,
    required this.durationTicks,
  }) : remainingTicks = durationTicks;

  bool get isExpired => durationTicks > 0 && remainingTicks <= 0;
  bool get isInstant => durationTicks == 0;

  GameEvent copyWith({int? remainingTicks}) {
    final e = GameEvent(
      id: id,
      name: name,
      description: description,
      durationTicks: durationTicks,
    );
    e.remainingTicks = remainingTicks ?? this.remainingTicks;
    return e;
  }
}
