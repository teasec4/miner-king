import 'coin_state.dart';
import 'farm.dart';
import 'game_event.dart';
import 'loan.dart';
import 'modifier.dart';
import 'player_profile.dart';

class Game {
  final double money;
  final Map<String, double> holdings;
  final List<CoinState> coins;
  final double electricityRate;
  final Farm farm;
  final List<Modifier> activeModifiers;
  final List<GameEvent> activeEvents;
  final List<Loan> activeLoans;
  final double marketMood;
  final Map<String, int> loanRepayments;
  final String? activeJobId;
  final Map<String, int> jobExperience;
  final List<String> completedCourses;
  final String? activeCourseId;
  final int courseTicksLeft;
  final CharacterType? character;
  final List<Perk> perks;
  final int tick;

  const Game({
    required this.money,
    required this.holdings,
    required this.coins,
    required this.farm,
    this.electricityRate = 0.12,
    this.activeModifiers = const [],
    this.activeEvents = const [],
    this.activeLoans = const [],
    this.marketMood = 0,
    this.loanRepayments = const {},
    this.activeJobId,
    this.jobExperience = const {},
    this.completedCourses = const [],
    this.activeCourseId,
    this.courseTicksLeft = 0,
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
    double? marketMood,
    Map<String, int>? loanRepayments,
    String? activeJobId,
    Map<String, int>? jobExperience,
    List<String>? completedCourses,
    String? activeCourseId,
    int? courseTicksLeft,
    CharacterType? character,
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
      marketMood: marketMood ?? this.marketMood,
      loanRepayments: loanRepayments ?? this.loanRepayments,
      activeJobId: activeJobId ?? this.activeJobId,
      jobExperience: jobExperience ?? this.jobExperience,
      completedCourses: completedCourses ?? this.completedCourses,
      activeCourseId: activeCourseId ?? this.activeCourseId,
      courseTicksLeft: courseTicksLeft ?? this.courseTicksLeft,
      character: character ?? this.character,
      perks: perks ?? this.perks,
      tick: tick ?? this.tick,
    );
  }
}
