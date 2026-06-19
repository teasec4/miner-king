import '../models/loan.dart';

/// Available loan products.
/// Interest rate is per HOUR. Small loans have higher rates (unsecured).
class LoanCatalog {
  LoanCatalog._();

  static final small = Loan(
    id: 'small',
    name: 'Quick Loan',
    principal: 500,
    interestPerMinute: 0.0005, // 3% per hour
  );

  static final medium = Loan(
    id: 'medium',
    name: 'Business Loan',
    principal: 2000,
    interestPerMinute: 0.00033, // 2% per hour
  );

  static final large = Loan(
    id: 'large',
    name: 'Expansion Loan',
    principal: 8000,
    interestPerMinute: 0.00025, // 1.5% per hour
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
