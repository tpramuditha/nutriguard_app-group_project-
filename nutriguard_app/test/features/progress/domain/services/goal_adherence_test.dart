import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/progress/domain/services/progress_calculation_service.dart';

void main() {
  const service = ProgressCalculationService();

  DailyProgressSummary createDay({
    required int day,
    required double calories,
    int mealCount = 1,
  }) {
    return DailyProgressSummary(
      date: DateTime(2026, 11, day),
      mealCount: mealCount,
      calories: calories,
      protein: 0,
      carbs: 0,
      fat: 0,
    );
  }

  group('Goal Adherence Calculation', () {
    test('calculates adherence for mixed logged days', () {
      final summaries = [
        createDay(day: 1, calories: 1950),
        createDay(day: 2, calories: 2050),
        createDay(day: 3, calories: 1500),
      ];

      final result = service.calculateGoalAdherence(
        summaries: summaries,
        dailyCalorieTarget: 2000,
      );

      expect(result.loggedDays, 3);
      expect(result.daysWithinTarget, 2);
      expect(result.percentage, closeTo(66.67, 0.01));
    });

    test('returns 100 percent when all logged days qualify', () {
      final summaries = [
        createDay(day: 1, calories: 1900),
        createDay(day: 2, calories: 2000),
        createDay(day: 3, calories: 2100),
      ];

      final result = service.calculateGoalAdherence(
        summaries: summaries,
        dailyCalorieTarget: 2000,
      );

      expect(result.loggedDays, 3);
      expect(result.daysWithinTarget, 3);
      expect(result.percentage, 100);
    });

    test('returns zero when all logged days are outside range', () {
      final summaries = [
        createDay(day: 1, calories: 1400),
        createDay(day: 2, calories: 2600),
      ];

      final result = service.calculateGoalAdherence(
        summaries: summaries,
        dailyCalorieTarget: 2000,
      );

      expect(result.loggedDays, 2);
      expect(result.daysWithinTarget, 0);
      expect(result.percentage, 0);
    });

    test('includes exact lower and upper boundaries', () {
      final summaries = [
        createDay(day: 1, calories: 1800),
        createDay(day: 2, calories: 2200),
      ];

      final result = service.calculateGoalAdherence(
        summaries: summaries,
        dailyCalorieTarget: 2000,
      );

      expect(result.daysWithinTarget, 2);
      expect(result.percentage, 100);
    });

    test('excludes days without food logs', () {
      final summaries = [
        createDay(day: 1, calories: 2000),
        createDay(day: 2, calories: 0, mealCount: 0),
        createDay(day: 3, calories: 1500),
      ];

      final result = service.calculateGoalAdherence(
        summaries: summaries,
        dailyCalorieTarget: 2000,
      );

      expect(result.loggedDays, 2);
      expect(result.daysWithinTarget, 1);
      expect(result.percentage, 50);
    });

    test('returns zero when summaries are empty', () {
      final result = service.calculateGoalAdherence(
        summaries: [],
        dailyCalorieTarget: 2000,
      );

      expect(result.loggedDays, 0);
      expect(result.daysWithinTarget, 0);
      expect(result.percentage, 0);
    });

    test('rejects zero calorie target', () {
      expect(
        () => service.calculateGoalAdherence(
          summaries: [],
          dailyCalorieTarget: 0,
        ),
        throwsArgumentError,
      );
    });

    test('rejects negative calorie target', () {
      expect(
        () => service.calculateGoalAdherence(
          summaries: [],
          dailyCalorieTarget: -100,
        ),
        throwsArgumentError,
      );
    });
  });
}
