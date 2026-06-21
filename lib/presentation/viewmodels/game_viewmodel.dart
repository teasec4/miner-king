import 'package:crypto_king/data/game_state.dart';
import 'package:crypto_king/domain/events/game_events.dart';
import 'package:crypto_king/domain/models/coin_state.dart';
import 'package:crypto_king/domain/models/game.dart';
import 'package:crypto_king/domain/models/gpu_model.dart';
import 'package:crypto_king/domain/models/inventory_item.dart';
import 'package:crypto_king/domain/models/investment.dart';
import 'package:crypto_king/domain/models/loan.dart';
import 'package:crypto_king/domain/models/player_profile.dart';
import 'package:crypto_king/presentation/viewmodels/rig_viewmodel.dart';
import 'package:crypto_king/presentation/viewmodels/economy_viewmodel.dart';
import 'package:crypto_king/presentation/viewmodels/market_viewmodel.dart';
import 'package:crypto_king/presentation/viewmodels/city_viewmodel.dart';

// Re-export from sub-VMs for backward compat
export 'package:crypto_king/presentation/viewmodels/rig_viewmodel.dart'
    show GpuDisplayInfo, ShopGpuEntry;
export 'package:crypto_king/presentation/viewmodels/economy_viewmodel.dart';
export 'package:crypto_king/presentation/viewmodels/market_viewmodel.dart';
export 'package:crypto_king/presentation/viewmodels/city_viewmodel.dart';

/// Thin aggregator over domain-specific ViewModels.
///
/// Each tab gets its own VM: RigViewModel, EconomyViewModel,
/// MarketViewModel, CityViewModel.  Forwarding getters preserve
/// backward compat while allowing `vm.rig.gpus` for new code.
class GameViewModel {
  final RigViewModel rig;
  final EconomyViewModel economy;
  final MarketViewModel market;
  final CityViewModel city;

  GameViewModel(GameState state)
    : rig = RigViewModel(state),
      economy = EconomyViewModel(state),
      market = MarketViewModel(state),
      city = CityViewModel(state);

  // ── Common ──

  int get tick => rig.game.tick;
  Game get game => rig.game;
  CharacterType? get character => rig.game.character;
  List<Perk> get perks => rig.game.perks;

  // ── Rig ──

  double get totalHashrate => rig.totalHashrate;
  double get totalPowerDraw => rig.totalPowerDraw;
  double get solarPower => rig.solarPower;
  String get coolingSystem => rig.coolingSystem;
  String get coolingLabel => rig.coolingLabel;
  String get psuTier => rig.psuTier;
  int get psuMaxWatt => rig.psuMaxWatt;
  String get psuLabel => rig.psuLabel;
  bool psuSupports(double w) => rig.psuSupports(w);
  int get totalSlots => rig.totalSlots;
  int get usedSlots => rig.usedSlots;
  bool get farmHasFreeSlots => rig.farmHasFreeSlots;
  int? get nextSlotTier => rig.nextSlotTier;
  int get nextSlotCost => rig.nextSlotCost;
  bool get canBuySlot => rig.canBuySlot;
  List<GpuDisplayInfo> get gpus => rig.gpus;
  bool canUpgrade(String id) => rig.canUpgrade(id);
  int upgradeCost(String id) => rig.upgradeCost(id);
  int repairCost(String id) => rig.repairCost(id);
  bool canRepair(String id) => rig.canRepair(id);
  int debuffRepairCost(String id) => rig.debuffRepairCost(id);
  bool get hasGpuSale => rig.hasGpuSale;
  List<ShopGpuEntry> get shopGpus => rig.shopGpus;
  List<InventoryItem> get inventory => rig.inventory;
  List<InventoryItem> get unequippedInventory => rig.unequippedInventory;
  int equippedUpgradeCost(String g, String t) => rig.equippedUpgradeCost(g, t);
  String? equippedNextTier(String g, String t) => rig.equippedNextTier(g, t);

  // ── Economy ──

  double get money => economy.money;
  double get electricityRate => economy.electricityRate;
  double get electricityCostPerHour => economy.electricityCostPerHour;
  double get electricityCostPerMin => economy.electricityCostPerMin;
  double get netProfitPerMin => economy.netProfitPerMin;
  double holding(String id) => economy.holding(id);
  List<CoinState> get coins => economy.coins;
  CoinState? coinState(String id) => economy.coinState(id);
  double holdingValue(String id) => economy.holdingValue(id);
  double get totalHoldingsValue => economy.totalHoldingsValue;
  bool canSellCoin(String id) => economy.canSellCoin(id);
  List<Loan> get activeLoans => economy.activeLoans;
  Map<String, int> get loanRepayments => economy.loanRepayments;
  double get totalDebt => economy.totalDebt;
  bool isLoanUnlocked(String id) => economy.isLoanUnlocked(id);
  List<ActiveInvestment> get activeInvestments => economy.activeInvestments;
  List<String> get properties => economy.properties;

  // ── Market ──

  double get marketMood => market.marketMood;
  List<GameEvent> get activeEvents => market.activeEvents;
  GameEvent? eventForCoin(int idx) => market.eventForCoin(idx);

  // ── City ──

  String? get activeJobId => city.activeJobId;
  int jobExp(String id) => city.jobExp(id);
  double get jobIncomePerMin => city.jobIncomePerMin;
  String? get activeCourseId => city.activeCourseId;
  int get courseTicksLeft => city.courseTicksLeft;
  List<String> get completedCourses => city.completedCourses;
  String? get officeId => city.officeId;
  List<String> get employees => city.employees;
  List<String> get employeePool => city.employeePool;
  int get nextPoolRefresh => city.nextPoolRefresh;
  int get poolRefreshIn => city.poolRefreshIn;
  List<Employee> get availableEmployees => city.availableEmployees;
  List<EmployeeSynergy> get activeSynergies => city.activeSynergies;
  int get officeSlots => city.officeSlots;

  // ── Events / Black Market ──

  Map<String, int> get unseenEvents => rig.game.unseenEvents;
  void clearUnseen(String cat) => city.state.clearUnseen(cat);
  int get blackMarketRefreshIn => city.state.blackMarketRefreshIn;
  int get blackMarketGen => city.state.blackMarketGen;
  void resetBlackMarketTimer() => city.state.resetBlackMarketTimer();
  void startTicks() => city.state.startTicks();

  // ── Actions ──

  void sellCoin(String id) => economy.sellCoin(id);
  void sellAllCoins() => economy.sellAllCoins();
  bool buyCoinWithCash(String id, double c) => economy.buyCoinWithCash(id, c);
  bool sellCoinForCash(String id, double a) => economy.sellCoinForCash(id, a);
  bool swapCoins(String f, String t, double a) => economy.swapCoins(f, t, a);
  bool takeLoan(String id) => economy.takeLoan(id);
  bool repayLoan(String id, double a) => economy.repayLoan(id, a);
  bool invest(String id, double a) => economy.invest(id, a);
  bool buyProperty(String id) => economy.buyProperty(id);
  bool buyGpu(GpuModel m) => rig.buyGpu(m);
  bool buyBlackMarketGpu(GpuModel m, int p, List<String> d) =>
      rig.buyBlackMarketGpu(m, p, d);
  bool installGpu(String id) => rig.installGpu(id);
  bool upgradeGpu(String id) => rig.upgradeGpu(id);
  void toggleOverclock(String id) => rig.toggleOverclock(id);
  bool repairGpu(String id) => rig.repairGpu(id);
  bool repairDebuff(String g, String d) => rig.repairDebuff(g, d);
  bool buySlotTier(SlotTier t) => rig.buySlotTier(t);
  bool buyCooling(CoolingUpgrade u) => rig.buyCooling(u);
  bool buySolar(SolarUpgrade u) => rig.buySolar(u);
  bool buyPsu(PsuUpgrade u) => rig.buyPsu(u);
  bool buyPaste(PasteUpgrade u) => rig.buyPaste(u);
  bool equipToGpu(String i, String g) => rig.equipToGpu(i, g);
  bool unequipFromGpu(String g, String t) => rig.unequipFromGpu(g, t);
  bool useMotherboard(String id) => rig.useMotherboard(id);
  bool upgradeEquipped(String g, String t) => rig.upgradeEquipped(g, t);
  void setMiningCoin(String g, String c) => rig.setMiningCoin(g, c);
  void togglePower(String g) => rig.togglePower(g);
  void startJob(String id) => city.startJob(id);
  void quitJob() => city.quitJob();
  bool enrollCourse(String id) => city.enrollCourse(id);
  bool buyOffice(String id) => city.buyOffice(id);
  bool hireEmployee(String id) => city.hireEmployee(id);
  void fireEmployee(String id) => city.fireEmployee(id);
  void refreshEmployeePool() => city.refreshEmployeePool();
}
