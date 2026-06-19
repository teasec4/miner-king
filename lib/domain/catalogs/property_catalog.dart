class Property {
  final String id;
  final String name;
  final int price;
  final double rentPerTick;

  const Property({
    required this.id,
    required this.name,
    required this.price,
    required this.rentPerTick,
  });
}

class PropertyCatalog {
  PropertyCatalog._();

  static const apartment = Property(
    id: 'apartment',
    name: 'Apartment',
    price: 50000,
    rentPerTick: 0.05,
  );
  static const house = Property(
    id: 'house',
    name: 'House',
    price: 200000,
    rentPerTick: 0.17,
  );
  static const villa = Property(
    id: 'villa',
    name: 'Villa',
    price: 1000000,
    rentPerTick: 0.67,
  );

  static final all = [apartment, house, villa];
  static Property? byId(String id) {
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
