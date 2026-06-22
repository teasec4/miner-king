import '../models/gpu_model.dart';

class GpuCatalog {
  GpuCatalog._();

  static const gtx1060 = GpuModel(
    id: 'gtx_1060',
    name: 'GTX 1060',
    baseHashrate: 10,
    basePowerConsumption: 120,
    baseTemperature: 45,
    price: 200,
  );
  static const rtx2060 = GpuModel(
    id: 'rtx_2060',
    name: 'RTX 2060',
    baseHashrate: 30,
    basePowerConsumption: 160,
    baseTemperature: 50,
    price: 500,
  );
  static const rtx3070 = GpuModel(
    id: 'rtx_3070',
    name: 'RTX 3070',
    baseHashrate: 60,
    basePowerConsumption: 220,
    baseTemperature: 55,
    price: 1200,
  );
  static const rtx5090 = GpuModel(
    id: 'rtx_5090',
    name: 'RTX 5090',
    baseHashrate: 250,
    basePowerConsumption: 650,
    baseTemperature: 65,
    price: 5000,
  );

  static const List<GpuModel> all = [gtx1060, rtx2060, rtx3070, rtx5090];

  static GpuModel? byId(String id) {
    try {
      return all.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 0-based tier index.
  static int indexOf(String id) {
    final idx = all.indexWhere((g) => g.id == id);
    return idx >= 0 ? idx : 0;
  }

  static GpuModel? byIndex(int idx) {
    if (idx < 0 || idx >= all.length) return null;
    return all[idx];
  }

  /// Cost to upgrade from one GPU tier to another (sum of intermediate prices).
  static int upgradeCost(int fromIdx, int toIdx) {
    if (toIdx <= fromIdx || toIdx >= all.length) return 0;
    int cost = 0;
    for (int i = fromIdx + 1; i <= toIdx; i++) {
      cost += all[i].price;
    }
    return cost;
  }
}
