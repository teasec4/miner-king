import 'package:uuid/uuid.dart';

class Miner {
  final String id;
  final int lvl;

  const Miner(this.id, this.lvl);

  static const Map<int, int> earnings = {1: 1, 2: 2, 3: 4};
  static const Map<int, int> cycleTime = {1: 10, 2: 15, 3: 20};

  int get incomePerCycle => earnings[lvl] ?? 0;
  int get cycleSeconds => cycleTime[lvl] ?? 999;
}

class MockData {
  static final _uuidGen = const Uuid();

  static List<Miner> miners = [
    Miner(_uuidGen.v4(), 1),
    // Miner(_uuidGen.v4(), 2),
    // Miner(_uuidGen.v4(), 1),
    // Miner(_uuidGen.v4(), 2),
  ];
}
