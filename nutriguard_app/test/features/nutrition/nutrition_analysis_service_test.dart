import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/food_scanner/data/models/food_log_model.dart';
import 'package:nutriguard_app/features/nutrition/domain/services/nutrition_analysis_service.dart';

void main() {
  late NutritionAnalysisService service;

  setUp(() {
    service = NutritionAnalysisService();
  });

  FoodLogModel makeFoodLog({
    required String name,
    required DateTime loggedAt,
    String mealType = 'Breakfast',
    double calories = 100,
    double protein = 5,
    double carbs = 10,
    double fat = 2,
  }) {
    return FoodLogModel(
      foodId: 'test-$name',
      foodName: name,
      brand: null,
      source: 'Manual Entry',
      grams: 100,
      mealType: mealType,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      loggedAt: loggedAt,
    );
  }

  final selectedDate = DateTime(2026, 11, 2);

  test('calculates total daily calories and macronutrients', () {
    final logs = [
      makeFoodLog(
        name: 'Rice and Dhal Curry',
        loggedAt: DateTime(2026, 11, 2, 8),
        calories: 150,
        protein: 10,
        carbs: 20,
        fat: 5,
      ),
      makeFoodLog(
        name: 'Kottu',
        loggedAt: DateTime(2026, 11, 2, 13),
        mealType: 'Lunch',
        calories: 250,
        protein: 12,
        carbs: 30,
        fat: 9,
      ),
    ];

    final summary = service.calculateDailyNutrition(
      foodLogs: logs,
      selectedDate: selectedDate,
    );

    expect(summary.foodCount, 2);
    expect(summary.totalCalories, 400);
    expect(summary.totalProtein, 22);
    expect(summary.totalCarbs, 50);
    expect(summary.totalFat, 14);
  });

  test('groups calorie totals by meal type', () {
    final logs = [
      makeFoodLog(
        name: 'Oats',
        loggedAt: DateTime(2026, 11, 2, 8),
        calories: 200,
      ),
      makeFoodLog(
        name: 'Rice',
        loggedAt: DateTime(2026, 11, 2, 13),
        mealType: 'Lunch',
        calories: 350,
      ),
      makeFoodLog(
        name: 'Fruit',
        loggedAt: DateTime(2026, 11, 2, 16),
        mealType: 'Snack',
        calories: 80,
      ),
      makeFoodLog(
        name: 'Soup',
        loggedAt: DateTime(2026, 11, 2, 19),
        mealType: 'Dinner',
        calories: 150,
      ),
    ];

    final summary = service.calculateDailyNutrition(
      foodLogs: logs,
      selectedDate: selectedDate,
    );

    expect(summary.mealCalories['Breakfast'], 200);
    expect(summary.mealCalories['Lunch'], 350);
    expect(summary.mealCalories['Snack'], 80);
    expect(summary.mealCalories['Dinner'], 150);
    expect(summary.totalCalories, 780);
  });

  test('returns zero totals when food history is empty', () {
    final summary = service.calculateDailyNutrition(
      foodLogs: [],
      selectedDate: selectedDate,
    );

    expect(summary.foodCount, 0);
    expect(summary.totalCalories, 0);
    expect(summary.totalProtein, 0);
    expect(summary.totalCarbs, 0);
    expect(summary.totalFat, 0);

    expect(summary.mealCalories.values.every((value) => value == 0), isTrue);
  });

  test('excludes food logs from other dates', () {
    final logs = [
      makeFoodLog(
        name: 'Yesterday Food',
        loggedAt: DateTime(2026, 11, 1, 20),
        calories: 500,
      ),
      makeFoodLog(
        name: 'Today Food',
        loggedAt: DateTime(2026, 11, 2, 12),
        calories: 250,
      ),
      makeFoodLog(
        name: 'Tomorrow Food',
        loggedAt: DateTime(2026, 11, 3, 8),
        calories: 300,
      ),
    ];

    final summary = service.calculateDailyNutrition(
      foodLogs: logs,
      selectedDate: selectedDate,
    );

    expect(summary.foodCount, 1);
    expect(summary.totalCalories, 250);
  });

  test('includes food at midnight and excludes next midnight', () {
    final logs = [
      makeFoodLog(
        name: 'Start of Day',
        loggedAt: DateTime(2026, 11, 2, 0, 0),
        calories: 100,
      ),
      makeFoodLog(
        name: 'End of Day',
        loggedAt: DateTime(2026, 11, 2, 23, 59, 59),
        calories: 200,
      ),
      makeFoodLog(
        name: 'Next Midnight',
        loggedAt: DateTime(2026, 11, 3, 0, 0),
        calories: 300,
      ),
    ];

    final summary = service.calculateDailyNutrition(
      foodLogs: logs,
      selectedDate: selectedDate,
    );

    expect(summary.foodCount, 2);
    expect(summary.totalCalories, 300);
  });

  test('treats zero-calorie entries as valid food logs', () {
    final logs = [
      makeFoodLog(
        name: 'Water',
        loggedAt: DateTime(2026, 11, 2, 10),
        mealType: 'Snack',
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
      ),
    ];

    final summary = service.calculateDailyNutrition(
      foodLogs: logs,
      selectedDate: selectedDate,
    );

    expect(summary.foodCount, 1);
    expect(summary.totalCalories, 0);
    expect(summary.mealCalories['Snack'], 0);
  });
}
