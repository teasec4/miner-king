import '../models/loan.dart';

/// Available loan products.
/// Interest rate is per HOUR (applied per-tick as rate/3600).
class LoanCatalog {
  LoanCatalog._();

  static final small = Loan(
    id: 'small',
    name: 'Quick Loan',
    principal: 500,
    interestPerMinute: 0.0025, // 15% per hour = 0.25% per minute
  );

  static final medium = Loan(
    id: 'medium',
    name: 'Business Loan',
    principal: 2000,
    interestPerMinute: 0.00167, // 10% per hour
  );

  static final large = Loan(
    id: 'large',
    name: 'Expansion Loan',
    principal: 8000,
    interestPerMinute: 0.00117, // 7% per hour
  );

  static final all = [small, medium, large];

  static Loan? byId(String id) {
    try {
      return all.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }
}
