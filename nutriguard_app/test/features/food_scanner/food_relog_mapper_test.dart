import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/food_scanner/data/models/food_log_model.dart';
import 'package:nutriguard_app/features/food_scanner/data/services/food_relog_mapper.dart';

void main() {
  FoodLogModel createTestLog({
    double grams = 250,
    double calories = 308,
    double protein = 26.25,
    double carbs = 5.75,
    double fat = 20,
  }) {
    return FoodLogModel(
      foodId: '4796025410677',
      foodName: 'Greek Yoghurt',
      brand: 'Ciao',
      source: 'Open Food Facts',
      grams: grams,
      mealType: 'Breakfast',
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      loggedAt: DateTime(2026, 10, 25),
    );
  }

  test('converts saved nutrition into per 100g values', () {
    final log = createTestLog();

    final food = FoodRelogMapper.fromFoodLog(log);

    expect(food.id, '4796025410677');
    expect(food.name, 'Greek Yoghurt');
    expect(food.brand, 'Ciao');

    expect(food.caloriesPer100g, closeTo(123.2, 0.001));
    expect(food.proteinPer100g, closeTo(10.5, 0.001));
    expect(food.carbsPer100g, closeTo(2.3, 0.001));
    expect(food.fatPer100g, closeTo(8.0, 0.001));
  });

  test('calculates nutrition for a new portion', () {
    final food = FoodRelogMapper.fromFoodLog(createTestLog());

    expect(food.caloriesForGrams(150), closeTo(184.8, 0.001));

    expect(food.proteinForGrams(150), closeTo(15.75, 0.001));

    expect(food.carbsForGrams(150), closeTo(3.45, 0.001));

    expect(food.fatForGrams(150), closeTo(12.0, 0.001));
  });

  test('rejects zero portion size', () {
    expect(
      () => FoodRelogMapper.fromFoodLog(createTestLog(grams: 0)),
      throwsArgumentError,
    );
  });

  test('rejects negative nutrition values', () {
    expect(
      () => FoodRelogMapper.fromFoodLog(createTestLog(calories: -20)),
      throwsArgumentError,
    );
  });

  test('rejects excessively large portions', () {
    expect(
      () => FoodRelogMapper.fromFoodLog(createTestLog(grams: 6000)),
      throwsArgumentError,
    );
  });
}
