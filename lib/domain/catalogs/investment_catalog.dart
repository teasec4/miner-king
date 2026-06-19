class Investment {
  final String id;
  final String name;
  final int minAmount;
  final int durationTicks;
  final double returnRate; // 0.05 = 5%

  const Investment({
    required this.id,
    required this.name,
    required this.minAmount,
    required this.durationTicks,
    required this.returnRate,
  });

  String get durationLabel {
    final m = durationTicks ~/ 60;
    return '${m}min';
  }

  String get returnLabel => '${(returnRate * 100).toInt()}%';
}

class InvestmentCatalog {
  InvestmentCatalog._();

  static const conservative = Investment(
    id: 'conservative',
    name: 'Conservative',
    minAmount: 500,
    durationTicks: 120,
    returnRate: 0.05,
  );
  static const balanced = Investment(
    id: 'balanced',
    name: 'Balanced',
    minAmount: 2000,
    durationTicks: 300,
    returnRate: 0.15,
  );
  static const aggressive = Investment(
    id: 'aggressive',
    name: 'Aggressive',
    minAmount: 5000,
    durationTicks: 600,
    returnRate: 0.30,
  );

  static final all = [conservative, balanced, aggressive];
  static Investment? byId(String id) {
    try {
      return all.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }
}
