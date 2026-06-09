import 'package:crypto_king/domain/repositories/balance_repository.dart';

class BalanceManager implements BalanceRepository {
  int _balance;

  BalanceManager(this._balance);

  @override
  int get balance => _balance;

  @override
  void add(int amount) {
    _balance += amount;
  }

  @override
  void subtract(int amount) {
    _balance -= amount;
  }
}
