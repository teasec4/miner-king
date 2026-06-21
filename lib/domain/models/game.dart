import 'coin_state.dart';
import '../config/game_config.dart';
import 'farm.dart';
import '../events/game_events.dart';
import 'inventory_item.dart';
import 'loan.dart';
import 'player_profile.dart';
import 'specialization.dart';

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
  final List<GameEvent> activeEvents;
  final List<Loan> activeLoans;
  final double marketMood;
  final Map<String, int> loanRepayments;
  final String? activeJobId;
  final Map<String, int> jobExperience;
  final List<String> completedCourses;
  final String? activeCourseId;
  final int courseTicksLeft;

  /// Which milestone (0-3) the active course is currently at.
  final int courseMilestone;

  /// Whether the player is cram-studying (×2 speed, risk of burnout).
  final bool isCramStudy;

  final List<String> employees;
  final String? officeId;
  final Map<String, int> unseenEvents;
  final List<String> employeePool;
  final int nextPoolRefresh;
  final List<InventoryItem> inventory;
  final CharacterType? character;
  final List<Perk> perks;
  final int tick;

  /// Chosen specialization (locked after pick).
  final Specialization? specialization;

  /// GPU model name that was destroyed this tick (for UI notification).
  final String? destroyedGpu;

  /// Multiplier applied to all shop prices (default 1.0).
  /// Businessman character has 0.85 (15% discount).
  final double shopMultiplier;

  /// Whether the run has ended (bankruptcy, all GPUs dead, debt spiral).
  final bool gameOver;

  /// Human-readable reason for game over.
  final String? gameOverReason;

  /// Event that will trigger soon (warning period).
  final GameEvent? pendingEvent;

  /// Ticks remaining until the pending event fires.
  final int pendingEventTicksLeft;

  const Game({
    required this.money,
    required this.holdings,
    required this.coins,
    required this.farm,
    this.electricityRate = GameConfig.defaultElectricityRate,
    this.activeEvents = const [],
    this.activeLoans = const [],
    this.marketMood = 0,
    this.loanRepayments = const {},
    this.activeJobId,
    this.jobExperience = const {},
    this.completedCourses = const [],
    this.activeCourseId,
    this.courseTicksLeft = 0,
    this.courseMilestone = 0,
    this.isCramStudy = false,
    this.employees = const [],
    this.officeId,
    this.unseenEvents = const {},
    this.employeePool = const [],
    this.nextPoolRefresh = 0,
    this.inventory = const [],
    this.character,
    this.perks = const [],
    this.tick = 0,
    this.specialization,
    this.destroyedGpu,
    this.shopMultiplier = 1.0,
    this.gameOver = false,
    this.gameOverReason,
    this.pendingEvent,
    this.pendingEventTicksLeft = 0,
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
    List<GameEvent>? activeEvents,
    List<Loan>? activeLoans,
    double? marketMood,
    Map<String, int>? loanRepayments,
    // Nullable fields use Object? so we can tell "not provided" from "null":
    Object? activeJobId = _unset,
    Map<String, int>? jobExperience,
    List<String>? completedCourses,
    Object? activeCourseId = _unset,
    int? courseTicksLeft,
    int? courseMilestone,
    bool? isCramStudy,
    List<String>? employees,
    Object? officeId = _unset,
    Map<String, int>? unseenEvents,
    List<String>? employeePool,
    int? nextPoolRefresh,
    List<InventoryItem>? inventory,
    Object? character = _unset,
    List<Perk>? perks,
    int? tick,
    Object? specialization = _unset,
    String? destroyedGpu,
    double? shopMultiplier,
    bool? gameOver,
    String? gameOverReason,
    Object? pendingEvent = _unset,
    int? pendingEventTicksLeft,
  }) {
    return Game(
      money: money ?? this.money,
      holdings: holdings ?? this.holdings,
      coins: coins ?? this.coins,
      electricityRate: electricityRate ?? this.electricityRate,
      farm: farm ?? this.farm,
      activeEvents: activeEvents ?? this.activeEvents,
      activeLoans: activeLoans ?? this.activeLoans,
      marketMood: marketMood ?? this.marketMood,
      loanRepayments: loanRepayments ?? this.loanRepayments,
      activeJobId: _unwrapOr<String?>(activeJobId, this.activeJobId),
      jobExperience: jobExperience ?? this.jobExperience,
      completedCourses: completedCourses ?? this.completedCourses,
      activeCourseId: _unwrapOr<String?>(activeCourseId, this.activeCourseId),
      courseTicksLeft: courseTicksLeft ?? this.courseTicksLeft,
      courseMilestone: courseMilestone ?? this.courseMilestone,
      isCramStudy: isCramStudy ?? this.isCramStudy,
      employees: employees ?? this.employees,
      officeId: _unwrapOr<String?>(officeId, this.officeId),
      unseenEvents: unseenEvents ?? this.unseenEvents,
      employeePool: employeePool ?? this.employeePool,
      nextPoolRefresh: nextPoolRefresh ?? this.nextPoolRefresh,
      inventory: inventory ?? this.inventory,
      character: _unwrapOr<CharacterType?>(character, this.character),
      perks: perks ?? this.perks,
      tick: tick ?? this.tick,
      specialization: _unwrapOr<Specialization?>(
        specialization,
        this.specialization,
      ),
      destroyedGpu: destroyedGpu,
      shopMultiplier: shopMultiplier ?? this.shopMultiplier,
      gameOver: gameOver ?? this.gameOver,
      gameOverReason: gameOverReason,
      pendingEvent: _unwrapOr<GameEvent?>(pendingEvent, this.pendingEvent),
      pendingEventTicksLeft:
          pendingEventTicksLeft ?? this.pendingEventTicksLeft,
    );
  }

  /// Returns [value] if it was explicitly provided (even if null),
  /// otherwise returns [fallback].
  static T _unwrapOr<T>(Object? value, T fallback) {
    return identical(value, _unset) ? fallback : value as T;
  }
}
