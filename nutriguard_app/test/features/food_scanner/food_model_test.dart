import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/food_scanner/data/models/food_model.dart';

void main() {
  const testFood = FoodModel(
    id: 'food001',
    name: 'Test Rice',
    brand: null,
    source: 'Test Database',
    caloriesPer100g: 130,
    proteinPer100g: 2.7,
    carbsPer100g: 28.2,
    fatPer100g: 0.3,
  );

  test('calculates calories for a 150g portion', () {
    expect(testFood.caloriesForGrams(150), closeTo(195, 0.001));
  });

  test('calculates protein for a 150g portion', () {
    expect(testFood.proteinForGrams(150), closeTo(4.05, 0.001));
  });

  test('calculates carbohydrates for a 150g portion', () {
    expect(testFood.carbsForGrams(150), closeTo(42.3, 0.001));
  });

  test('calculates fat for a 150g portion', () {
    expect(testFood.fatForGrams(150), closeTo(0.45, 0.001));
  });

  test('returns original nutrition values for 100g', () {
    expect(testFood.caloriesForGrams(100), 130);
    expect(testFood.proteinForGrams(100), 2.7);
    expect(testFood.carbsForGrams(100), 28.2);
    expect(testFood.fatForGrams(100), 0.3);
  });

  test('preserves food information when converting to and from a map', () {
    final restored = FoodModel.fromMap(testFood.toMap());

    expect(restored.id, 'food001');
    expect(restored.name, 'Test Rice');
    expect(restored.brand, isNull);
    expect(restored.source, 'Test Database');
    expect(restored.caloriesPer100g, 130);
    expect(restored.proteinPer100g, 2.7);
    expect(restored.carbsPer100g, 28.2);
    expect(restored.fatPer100g, 0.3);
  });

  test('preserves a food brand when converting to and from a map', () {
    const brandedFood = FoodModel(
      id: 'food002',
      name: 'Test Cereal',
      brand: 'Example Brand',
      source: 'Test Database',
      caloriesPer100g: 380,
      proteinPer100g: 8,
      carbsPer100g: 75,
      fatPer100g: 5,
    );

    final restored = FoodModel.fromMap(brandedFood.toMap());

    expect(restored.brand, 'Example Brand');
    expect(restored.name, 'Test Cereal');
  });

  test('preserves decimal nutrition values', () {
    final restored = FoodModel.fromMap(testFood.toMap());

    expect(restored.proteinPer100g, 2.7);
    expect(restored.fatPer100g, 0.3);
  });

  test('calculates nutrition for a decimal gram portion', () {
    expect(testFood.caloriesForGrams(125.5), closeTo(163.15, 0.001));
    expect(testFood.proteinForGrams(125.5), closeTo(3.3885, 0.001));
    expect(testFood.carbsForGrams(125.5), closeTo(35.391, 0.001));
    expect(testFood.fatForGrams(125.5), closeTo(0.3765, 0.001));
  });

  test('returns zero nutrition for a zero gram portion', () {
    expect(testFood.caloriesForGrams(0), 0);
    expect(testFood.proteinForGrams(0), 0);
    expect(testFood.carbsForGrams(0), 0);
    expect(testFood.fatForGrams(0), 0);
  });

  test('rejects a negative gram portion', () {
    expect(() => testFood.caloriesForGrams(-100), throwsArgumentError);
    expect(() => testFood.proteinForGrams(-100), throwsArgumentError);
    expect(() => testFood.carbsForGrams(-100), throwsArgumentError);
    expect(() => testFood.fatForGrams(-100), throwsArgumentError);
  });

  test('rejects portions greater than 5000 grams', () {
    expect(() => testFood.caloriesForGrams(5001), throwsArgumentError);
  });

  test('rejects NaN and infinite gram portions', () {
    expect(() => testFood.caloriesForGrams(double.nan), throwsArgumentError);
    expect(
      () => testFood.caloriesForGrams(double.infinity),
      throwsArgumentError,
    );
  });
}
