import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguard_app/features/food_scanner/data/models/food_log_model.dart';
import 'package:nutriguard_app/features/progress/domain/services/progress_calculation_service.dart';

void main() {
  const service = ProgressCalculationService();

  FoodLogModel createFoodLog({
    required DateTime loggedAt,
    double calories = 420,
    double protein = 15,
    double carbs = 58,
    double fat = 14,
  }) {
    return FoodLogModel(
      foodId: 'test_food',
      foodName: 'Test Food',
      source: 'manual',
      grams: 200,
      mealType: 'Lunch',
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      loggedAt: loggedAt,
    );
  }

  group('ProgressCalculationService - Daily Summary', () {
    test('calculates totals for multiple meals', () {
      final date = DateTime(2026, 11, 8);

      final logs = [
        createFoodLog(
          loggedAt: DateTime(2026, 11, 8, 8),
          calories: 260,
          protein: 18,
          carbs: 10,
          fat: 16,
        ),
        createFoodLog(
          loggedAt: DateTime(2026, 11, 8, 13),
          calories: 420,
          protein: 15,
          carbs: 58,
          fat: 14,
        ),
      ];

      final result = service.calculateDailySummary(date: date, foodLogs: logs);

      expect(result.mealCount, 2);
      expect(result.calories, 680);
      expect(result.protein, 33);
      expect(result.carbs, 68);
      expect(result.fat, 30);
    });

    test('ignores meals from other dates', () {
      final logs = [
        createFoodLog(loggedAt: DateTime(2026, 11, 8), calories: 420),
        createFoodLog(loggedAt: DateTime(2026, 11, 7), calories: 260),
      ];

      final result = service.calculateDailySummary(
        date: DateTime(2026, 11, 8),
        foodLogs: logs,
      );

      expect(result.mealCount, 1);
      expect(result.calories, 420);
    });

    test('returns zero totals when no meals exist', () {
      final result = service.calculateDailySummary(
        date: DateTime(2026, 11, 8),
        foodLogs: [],
      );

      expect(result.mealCount, 0);
      expect(result.calories, 0);
      expect(result.protein, 0);
      expect(result.carbs, 0);
      expect(result.fat, 0);
    });

    test('calculates calorie target percentage', () {
      final summary = service.calculateDailySummary(
        date: DateTime(2026, 11, 8),
        foodLogs: [
          createFoodLog(loggedAt: DateTime(2026, 11, 8), calories: 1500),
        ],
      );

      expect(summary.calorieGoalPercentage(2000), 75);

      expect(summary.calorieGoalPercentage(0), 0);
    });
  });

  group('ProgressCalculationService - Date Range', () {
    test('creates a summary for each selected date', () {
      final result = service.calculateDateRange(
        startDate: DateTime(2026, 11, 6),
        endDate: DateTime(2026, 11, 8),
        foodLogs: [
          createFoodLog(loggedAt: DateTime(2026, 11, 7), calories: 420),
        ],
      );

      expect(result.length, 3);
      expect(result[0].calories, 0);
      expect(result[1].calories, 420);
      expect(result[2].calories, 0);
    });

    test('includes both start and end dates', () {
      final result = service.calculateDateRange(
        startDate: DateTime(2026, 11, 7),
        endDate: DateTime(2026, 11, 8),
        foodLogs: [
          createFoodLog(loggedAt: DateTime(2026, 11, 7), calories: 260),
          createFoodLog(loggedAt: DateTime(2026, 11, 8), calories: 420),
        ],
      );

      expect(result.length, 2);
      expect(result[0].calories, 260);
      expect(result[1].calories, 420);
    });

    test('rejects invalid date ranges', () {
      expect(
        () => service.calculateDateRange(
          startDate: DateTime(2026, 11, 8),
          endDate: DateTime(2026, 11, 1),
          foodLogs: [],
        ),
        throwsArgumentError,
      );
    });
  });

  group('ProgressCalculationService - Logging Streak', () {
    test('counts consecutive days including today', () {
      final logs = [
        createFoodLog(loggedAt: DateTime(2026, 11, 8)),
        createFoodLog(loggedAt: DateTime(2026, 11, 7)),
        createFoodLog(loggedAt: DateTime(2026, 11, 6)),
      ];

      final result = service.calculateLoggingStreak(
        foodLogs: logs,
        today: DateTime(2026, 11, 8),
      );

      expect(result, 3);
    });

    test('keeps streak if user logged yesterday', () {
      final logs = [
        createFoodLog(loggedAt: DateTime(2026, 11, 7)),
        createFoodLog(loggedAt: DateTime(2026, 11, 6)),
      ];

      final result = service.calculateLoggingStreak(
        foodLogs: logs,
        today: DateTime(2026, 11, 8),
      );

      expect(result, 2);
    });

    test('returns zero when streak is broken', () {
      final result = service.calculateLoggingStreak(
        foodLogs: [createFoodLog(loggedAt: DateTime(2026, 11, 5))],
        today: DateTime(2026, 11, 8),
      );

      expect(result, 0);
    });
  });

  group('ProgressCalculationService - Averages', () {
    test('calculates average calories across all days', () {
      final summaries = service.calculateDateRange(
        startDate: DateTime(2026, 11, 6),
        endDate: DateTime(2026, 11, 8),
        foodLogs: [
          createFoodLog(loggedAt: DateTime(2026, 11, 6), calories: 600),
          createFoodLog(loggedAt: DateTime(2026, 11, 7), calories: 900),
        ],
      );

      final average = service.calculateAverageCalories(summaries);

      expect(average, 500);
    });

    test('returns zero average for empty summaries', () {
      expect(service.calculateAverageCalories([]), 0);
    });
  });
}
