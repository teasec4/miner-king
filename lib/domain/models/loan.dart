/// A loan taken from the bank.
class Loan {
  final String id;
  final String name;
  final double principal;
  final double interestPerMinute; // e.g. 0.05 = 5% per minute
  double remaining;

  Loan({
    required this.id,
    required this.name,
    required this.principal,
    required this.interestPerMinute,
  }) : remaining = principal;

  Loan copyWith({double? remaining}) {
    return Loan(
      id: id,
      name: name,
      principal: principal,
      interestPerMinute: interestPerMinute,
    )..remaining = remaining ?? this.remaining;
  }
}
