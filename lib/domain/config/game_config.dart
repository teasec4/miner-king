/// Centralised tuning constants for the entire game.
///
/// Every magic number that lives in a system should live here.
/// This makes balance tuning trivial (no code changes needed)
/// and gives a single place to see all dials.
///
/// See refactoring_plan.md phase 2.1.
class GameConfig {
  GameConfig._();

  // ──────────────────────────── Mining ────────────────────────────

  /// Progress each tick = hashrate × this (before employee bonus).
  static const double cycleProgressPerHashrate = 0.025;

  /// Coins awarded per completed cycle = rewardPerCycle × coin.baseReward.
  static const double rewardPerCycle = 0.020;

  // ──────────────────────────── Market ────────────────────────────

  /// Random walk step size for market mood (per tick).
  static const double moodRandomWalk = 0.03;

  /// Mean-reversion strength pulling mood back to 0.
  static const double moodMeanReversion = 0.002;

  /// Per-tick probability multiplier for micro-shocks.
  static const double microShockChanceMultiplier = 1.5;

  /// Amplitude of micro-shocks (× volatility).
  static const double microShockAmplitude = 0.12;

  /// Per-tick chance of a volatility explosion (fat-tail event).
  static const double volatilityExplosionChance = 0.0005;

  /// Amplitude of volatility explosions (× volatility).
  static const double volatilityExplosionAmplitude = 0.4;

  /// Min / max ticks a market phase lasts.
  static const int minPhaseTicks = 60;
  static const int maxPhaseTicks = 300;

  /// Base drift magnitude per phase type.
  static const double driftBaseMagnitude = 0.004;
  static const double driftBaseOffset = 0.001;

  /// How much mood amplifies drift (fraction of |mood|).
  static const double driftMoodAmplifier = 0.3;

  /// Extra random wiggle multiplier (× volatility).
  static const double driftNoiseMultiplier = 0.003;

  /// Mood thresholds for phase bias.
  static const double moodBiasThreshold = 0.3;
  static const double moodBiasProbabilityScalar = 0.4;

  // ──────────────────────────── Thermal ────────────────────────────

  /// Cooling efficiency by system id (°C reduction).
  static const Map<String, double> coolingPower = {
    'basic': 0.0,
    'fans': -10.0,
    'water': -20.0,
    'immersion': -30.0,
  };

  /// Base heat added per overclock level.
  static const double overclockBaseHeat = 25.0;

  /// Worn cards add up to this many °C (× (1 - condition)).
  static const double wearHeatFactor = 20.0;

  /// Fan Failure event: +25°C to one GPU.
  static const double fanFailTempBonus = 25.0;

  /// Dust Storm event: +15°C to all GPUs.
  static const double dustStormTempBonus = 15.0;

  /// Perk: Efficient Fans -15°C.
  static const double efficientFansTempReduction = 15.0;

  /// Temperature clamping range.
  static const double minTemperature = 20.0;
  static const double maxTemperature = 150.0;

  /// Dead / powered-off GPU ambient temp.
  static const double ambientTemperature = 25.0;

  // ──────────────────────────── Wear ────────────────────────────

  /// Temperature below which no wear occurs.
  static const double safeTemp = 50.0;

  /// Temperature above which critical failures can happen.
  static const double dangerousTemp = 90.0;

  /// Wear rate at the dangerousTemp threshold (per tick).
  static const double wearRateAtDangerous = 0.001;

  /// Extra wear rate per degree above dangerousTemp.
  static const double wearRateAboveDangerousPerDegree = 0.001;

  /// Acceleration factor for fully-worn cards (× (1 - condition)).
  static const double wearConditionAccelerator = 2.0;

  /// Risk Lover perk: extra wear multiplier.
  static const double riskLoverWearMultiplier = 1.5;

  /// Per-tick chance of critical failure above dangerousTemp.
  static const double critFailureChance = 0.002;

  /// Condition damage on critical failure.
  static const double critFailureDamage = 0.05;

  // ──────────────────────────── Electricity ───────────────────────

  /// Default electricity rate ($ per watt-hour, game coefficient).
  static const double defaultElectricityRate = 0.08;

  /// Ticks per in-game hour (used to convert hourly costs).
  static const int ticksPerHour = 3600;

  // ──────────────────────────── Events ────────────────────────────

  /// Min / max ticks between random events.
  static const int minEventInterval = 60;
  static const int maxEventInterval = 300;

  /// Maximum simultaneous active events.
  static const int maxActiveEvents = 3;

  /// Warning period before an event fires (ticks).
  static const int eventWarningTicks = 12;

  /// Initial delay before the first event is possible.
  static const int initialEventDelay = 180;

  /// How many ticks before an expired instant event is cleaned up.
  static const int instantEventCleanupDelay = 60;

  /// Security guard event tick-down acceleration (additive to 1.0).
  static const double securityTickDecay = 1.0;

  // ──────────────────────────── Economy ───────────────────────────

  /// Fee for buying / selling coins with cash.
  static const double cashExchangeFee = 0.05;

  /// Fee for swapping one coin for another.
  static const double swapFee = 0.01;

  // ──────────────────────────── Loans ────────────────────────────

  /// Origination fee added to principal (10 %).
  static const double loanOriginationFee = 0.10;

  // ──────────────────────────── Jobs ──────────────────────────────

  /// Income multiplier per job level (+10 %).
  static const double levelIncomeMultiplier = 0.10;

  /// Job Fair event: salary multiplier.
  static const double jobFairMultiplier = 2.0;

  /// EXP gain multiplier for Hustler character.
  static const double hustlerExpMultiplier = 2.0;

  /// Diploma bonus per relevant course (fraction).
  static const double diplomaBonusPerCourse = 0.20;
  static const double diplomaBonusGlobal = 0.25;

  // ────────────────────────── Employees / Trader ──────────────────

  /// Trader mood formula: weight of linear component.
  static const double traderLinearWeight = 0.7;

  /// Trader mood formula: weight of quadratic component.
  static const double traderQuadraticWeight = 0.3;

  /// FinTech synergy: trader profit multiplier.
  static const double fintechSynergyMultiplier = 1.20;

  /// Optimized Mining synergy: extra hashrate bonus.
  static const double optimizedHashrateBonus = 0.05;

  /// Optimized Mining synergy: extra wear reduction.
  static const double optimizedWearBonus = 0.05;

  /// Efficient Farm synergy: extra electricity reduction.
  static const double efficientFarmBonus = 0.05;

  /// Rent Hike event: rent multiplier.
  static const double rentHikeMultiplier = 2.0;

  // ──────────────────────────── GPU ───────────────────────────────

  /// Overclock: +20 % hashrate per level.
  static const double overclockHashratePerLevel = 0.20;

  /// Overclock: +10 % power consumption per level.
  static const double overclockPowerPerLevel = 0.10;

  /// Max overclock level.
  static const int maxOverclockLevel = 2;

  /// PSU efficiency: power reduction per tier (5 %).
  static const double psuEfficiencyPerTier = 0.05;

  /// GPU Sale event: discount on GPU prices (30 % off → 0.70).
  static const double gpuSaleDiscount = 0.70;

  /// Black Market: GPU price range (40-60 %).
  static const double blackMarketMinPrice = 0.40;
  static const double blackMarketMaxPrice = 0.60;

  /// Black Market: refresh interval in ticks.
  static const int blackMarketRefreshTicks = 300;

  /// Employee pool: refresh interval in ticks.
  static const int employeePoolRefreshTicks = 300;

  // ──────────────────────────── Repair ────────────────────────────

  /// Base repair cost: fraction of GPU price × damage.
  static const double repairCostFraction = 0.30;

  /// Engineer character: repair cost discount.
  static const double engineerRepairDiscount = 0.70;

  /// Tech Lab: cost to reroll silicon lottery on a GPU.
  static const int siliconLotteryRerollCost = 500;

  // ──────────────────────────── Perks ─────────────────────────────

  /// Perk: Silicon Lottery hashrate bonus.
  static const double siliconLotteryHashrateBonus = 0.10;

  /// Perk: Risk Lover hashrate bonus.
  static const double riskLoverHashrateBonus = 0.50;

  /// Perk: Cheap Electricity discount.
  static const double cheapElectricityDiscount = 0.20;

  /// Perk: Better Motherboard extra slots.
  static const int betterMoboSlots = 2;

  // ──────────────────────────── Characters ────────────────────────

  /// Miner character: hashrate bonus.
  static const double minerHashrateBonus = 0.25;

  /// Engineer character: wear reduction.
  static const double engineerWearReduction = 0.50;

  /// Engineer character: repair cost discount (applied to base).
  static const double engineerRepairCostReduction = 0.70;

  /// Businessman character: shop discount.
  static const double businessmanShopDiscount = 0.85;

  /// Apply character shop discount to a base price.
  static int applyShopDiscount(int basePrice, double shopMultiplier) {
    return (basePrice * shopMultiplier).ceil();
  }

  /// Student character: course time speedup (1.25 = 25 % faster).
  static const double studentCourseSpeedup = 1.25;

  /// Student character: course cost discount.
  static const double studentCourseDiscount = 0.70;

  /// Cram Study: speed multiplier when studying intensively.
  static const double cramStudySpeedMultiplier = 2.0;

  /// Cram Study: per-tick chance of burnout (progress reset to previous milestone).
  static const double cramStudyBurnoutChance = 0.008;

  /// Cram Study: extra cost multiplier on course price.
  static const double cramStudyCostMultiplier = 0.50;

  // ──────────────────────── Specializations ───────────────────────

  /// Mining Tycoon: hashrate bonus.
  static const double tycoonHashrateBonus = 0.30;

  /// Mining Tycoon: job income penalty.
  static const double tycoonJobPenalty = 0.50;

  /// Career Climber: job salary multiplier.
  static const double climberJobMultiplier = 2.0;

  /// Career Climber: electricity discount.
  static const double climberElectricityDiscount = 0.30;

  /// Market Speculator: sell/swap profit bonus.
  static const double speculatorProfitBonus = 0.50;

  /// Market Speculator: hashrate penalty.
  static const double speculatorHashratePenalty = 0.20;

  // ──────────────────────────── Job Perks ─────────────────────────

  /// Tech & IT Lv3: electricity discount.
  static const double techPerkElectricityDiscount = 0.10;

  /// Business & Finance Lv3: sell price bonus.
  static const double bizPerkSellBonus = 0.10;

  /// Engineering Lv3: hashrate bonus.
  static const double engPerkHashrateBonus = 0.05;

  // ──────────────────────────── Misc ──────────────────────────────

  /// Event overlay auto-dismiss delay in seconds.
  static const int eventOverlayDismissSeconds = 5;

  /// Tick interval (real seconds per game tick).
  static const int tickIntervalSeconds = 1;

  /// Watchdog check interval (real seconds).
  static const int watchdogIntervalSeconds = 3;
}
