import '../models/loan.dart';

/// Available loan products. Interest rate is per HOUR.
class LoanCatalog {
  LoanCatalog._();

  static final small = Loan(
    id: 'small',
    name: 'Quick Loan',
    principal: 500,
    interestPerMinute: 0.00015,
  );
  static final medium = Loan(
    id: 'medium',
    name: 'Business Loan',
    principal: 2000,
    interestPerMinute: 0.00020,
  );
  static final large = Loan(
    id: 'large',
    name: 'Expansion Loan',
    principal: 8000,
    interestPerMinute: 0.00025,
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
