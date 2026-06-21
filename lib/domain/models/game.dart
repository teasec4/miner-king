import 'coin_state.dart';
import 'farm.dart';
import 'game_event.dart';
import 'inventory_item.dart';
import 'investment.dart';
import 'loan.dart';
import 'modifier.dart';
import 'player_profile.dart';

/// Sentinel used in [Game.copyWith] to distinguish "not provided" from "null".
/// Without this, `copyWith(activeJobId: null)` is silently ignored by `??`.
class _Unset {
  const _Unset();
}

const _unset = _Unset();

class Game {
  final double money;
  final Map<String, double> holdings;
  final List<CoinState> coins;
  final double electricityRate;
  final Farm farm;
  final List<Modifier> activeModifiers;
  final List<GameEvent> activeEvents;
  final List<Loan> activeLoans;
  final List<ActiveInvestment> activeInvestments;
  final List<String> properties;
  final double marketMood;
  final Map<String, int> loanRepayments;
  final String? activeJobId;
  final Map<String, int> jobExperience;
  final List<String> completedCourses;
  final String? activeCourseId;
  final int courseTicksLeft;
  final List<String> employees;
  final String? officeId;
  final Map<String, int> unseenEvents;
  final List<String> employeePool;
  final int nextPoolRefresh;
  final List<InventoryItem> inventory;
  final CharacterType? character;
  final List<Perk> perks;
  final int tick;

  const Game({
    required this.money,
    required this.holdings,
    required this.coins,
    required this.farm,
    this.electricityRate = 0.25,
    this.activeModifiers = const [],
    this.activeEvents = const [],
    this.activeLoans = const [],
    this.activeInvestments = const [],
    this.properties = const [],
    this.marketMood = 0,
    this.loanRepayments = const {},
    this.activeJobId,
    this.jobExperience = const {},
    this.completedCourses = const [],
    this.activeCourseId,
    this.courseTicksLeft = 0,
    this.employees = const [],
    this.officeId,
    this.unseenEvents = const {},
    this.employeePool = const [],
    this.nextPoolRefresh = 0,
    this.inventory = const [],
    this.character,
    this.perks = const [],
    this.tick = 0,
  });

  CoinState? coin(String id) {
    try {
      return coins.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  CoinState get primaryCoin => coins.first;

  Game copyWith({
    double? money,
    Map<String, double>? holdings,
    List<CoinState>? coins,
    double? electricityRate,
    Farm? farm,
    List<Modifier>? activeModifiers,
    List<GameEvent>? activeEvents,
    List<Loan>? activeLoans,
    List<ActiveInvestment>? activeInvestments,
    List<String>? properties,
    double? marketMood,
    Map<String, int>? loanRepayments,
    // Nullable fields use Object? so we can tell "not provided" from "null":
    Object? activeJobId = _unset,
    Map<String, int>? jobExperience,
    List<String>? completedCourses,
    Object? activeCourseId = _unset,
    int? courseTicksLeft,
    List<String>? employees,
    Object? officeId = _unset,
    Map<String, int>? unseenEvents,
    List<String>? employeePool,
    int? nextPoolRefresh,
    List<InventoryItem>? inventory,
    Object? character = _unset,
    List<Perk>? perks,
    int? tick,
  }) {
    return Game(
      money: money ?? this.money,
      holdings: holdings ?? this.holdings,
      coins: coins ?? this.coins,
      electricityRate: electricityRate ?? this.electricityRate,
      farm: farm ?? this.farm,
      activeModifiers: activeModifiers ?? this.activeModifiers,
      activeEvents: activeEvents ?? this.activeEvents,
      activeLoans: activeLoans ?? this.activeLoans,
      activeInvestments: activeInvestments ?? this.activeInvestments,
      properties: properties ?? this.properties,
      marketMood: marketMood ?? this.marketMood,
      loanRepayments: loanRepayments ?? this.loanRepayments,
      activeJobId: _unwrapOr<String?>(activeJobId, this.activeJobId),
      jobExperience: jobExperience ?? this.jobExperience,
      completedCourses: completedCourses ?? this.completedCourses,
      activeCourseId: _unwrapOr<String?>(activeCourseId, this.activeCourseId),
      courseTicksLeft: courseTicksLeft ?? this.courseTicksLeft,
      employees: employees ?? this.employees,
      officeId: _unwrapOr<String?>(officeId, this.officeId),
      unseenEvents: unseenEvents ?? this.unseenEvents,
      employeePool: employeePool ?? this.employeePool,
      nextPoolRefresh: nextPoolRefresh ?? this.nextPoolRefresh,
      inventory: inventory ?? this.inventory,
      character: _unwrapOr<CharacterType?>(character, this.character),
      perks: perks ?? this.perks,
      tick: tick ?? this.tick,
    );
  }

  /// Returns [value] if it was explicitly provided (even if null),
  /// otherwise returns [fallback].
  static T _unwrapOr<T>(Object? value, T fallback) {
    return identical(value, _unset) ? fallback : value as T;
  }
}
