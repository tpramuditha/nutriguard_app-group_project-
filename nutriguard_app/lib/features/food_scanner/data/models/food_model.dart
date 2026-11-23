class FoodModel {
  final String id;
  final String name;
  final String? brand;
  final String source;

  // Nutrition values per 100 grams
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;

  const FoodModel({
    required this.id,
    required this.name,
    this.brand,
    required this.source,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
  });

  void _validateGrams(double grams) {
    if (!grams.isFinite || grams < 0 || grams > 5000) {
      throw ArgumentError.value(
        grams,
        'grams',
        'Grams must be between 0 and 5000.',
      );
    }
  }

  double caloriesForGrams(double grams) {
    _validateGrams(grams);
    return caloriesPer100g * grams / 100;
  }

  double proteinForGrams(double grams) {
    _validateGrams(grams);
    return proteinPer100g * grams / 100;
  }

  double carbsForGrams(double grams) {
    _validateGrams(grams);
    return carbsPer100g * grams / 100;
  }

  double fatForGrams(double grams) {
    _validateGrams(grams);
    return fatPer100g * grams / 100;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'source': source,
      'caloriesPer100g': caloriesPer100g,
      'proteinPer100g': proteinPer100g,
      'carbsPer100g': carbsPer100g,
      'fatPer100g': fatPer100g,
    };
  }

  factory FoodModel.fromMap(Map<String, dynamic> map) {
    return FoodModel(
      id: map['id'] as String,
      name: map['name'] as String,
      brand: map['brand'] as String?,
      source: map['source'] as String,
      caloriesPer100g: (map['caloriesPer100g'] as num).toDouble(),
      proteinPer100g: (map['proteinPer100g'] as num).toDouble(),
      carbsPer100g: (map['carbsPer100g'] as num).toDouble(),
      fatPer100g: (map['fatPer100g'] as num).toDouble(),
    );
  }
}
