/// Buyable upgrade: solar panels.
class SolarUpgrade {
  final String id;
  final String name;
  final int price;
  final double powerGen; // watts generated

  const SolarUpgrade({
    required this.id,
    required this.name,
    required this.price,
    required this.powerGen,
  });
}

class SolarCatalog {
  SolarCatalog._();

  static const basic = SolarUpgrade(
    id: 'solar_basic',
    name: 'Basic Panels',
    price: 500,
    powerGen: 100,
  );
  static const advanced = SolarUpgrade(
    id: 'solar_advanced',
    name: 'Advanced Panels',
    price: 2000,
    powerGen: 300,
  );
  static const farm = SolarUpgrade(
    id: 'solar_farm',
    name: 'Solar Farm',
    price: 8000,
    powerGen: 1000,
  );

  static final all = [basic, advanced, farm];
}
