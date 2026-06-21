/// Player specialization — a mutually exclusive path chosen mid-run.
///
/// Once picked, it cannot be changed for the rest of the run.
enum Specialization {
  /// +30% hashrate, -50% job income
  miningTycoon('Mining Tycoon', '+30% hashrate, -50% job income'),

  /// ×2 job salary, -30% electricity cost
  careerClimber('Career Climber', '×2 job salary, -30% electricity cost'),

  /// +50% sell/swap profit, -20% hashrate
  marketSpeculator('Market Speculator', '+50% sell/swap profit, -20% hashrate');

  final String name;
  final String description;

  const Specialization(this.name, this.description);
}
