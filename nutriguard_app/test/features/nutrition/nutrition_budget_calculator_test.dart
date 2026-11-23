import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/nutrition/domain/services/nutrition_budget_calculator.dart';

void main() {
  late NutritionBudgetCalculator calculator;

  setUp(() {
    calculator = NutritionBudgetCalculator();
  });

  test('calculates daily calorie budget correctly', () {
    final result = calculator.calculate(
      targetCalories: 1800,
      consumedCalories: 160,
      selectedFoodCalories: 150,
    );

    expect(result.targetCalories, 1800);
    expect(result.consumedCalories, 160);
    expect(result.selectedFoodCalories, 150);
    expect(result.remainingCalories, 1640);
    expect(result.progress, closeTo(160 / 1800, 0.0001));
    expect(result.consumedPercentage, closeTo(8.8889, 0.001));
    expect(result.selectedFoodPercentage, closeTo(8.3333, 0.001));
    expect(result.isOverTarget, isFalse);
  });

  test('returns zero progress when nothing is consumed', () {
    final result = calculator.calculate(
      targetCalories: 1800,
      consumedCalories: 0,
      selectedFoodCalories: 0,
    );

    expect(result.remainingCalories, 1800);
    expect(result.progress, 0);
    expect(result.consumedPercentage, 0);
    expect(result.selectedFoodPercentage, 0);
    expect(result.isOverTarget, isFalse);
  });

  test('handles reaching the calorie target exactly', () {
    final result = calculator.calculate(
      targetCalories: 2000,
      consumedCalories: 2000,
      selectedFoodCalories: 500,
    );

    expect(result.remainingCalories, 0);
    expect(result.progress, 1);
    expect(result.consumedPercentage, 100);
    expect(result.selectedFoodPercentage, 25);
    expect(result.isOverTarget, isFalse);
  });

  test('handles consumption exceeding the target', () {
    final result = calculator.calculate(
      targetCalories: 1800,
      consumedCalories: 2200,
      selectedFoodCalories: 400,
    );

    expect(result.remainingCalories, -400);
    expect(result.progress, 1);
    expect(result.consumedPercentage, closeTo(122.2222, 0.001));
    expect(result.selectedFoodPercentage, closeTo(22.2222, 0.001));
    expect(result.isOverTarget, isTrue);
  });

  test('rejects zero and negative calorie targets', () {
    for (final target in [0, -100]) {
      expect(
        () => calculator.calculate(
          targetCalories: target,
          consumedCalories: 100,
          selectedFoodCalories: 50,
        ),
        throwsArgumentError,
      );
    }
  });

  test('rejects negative calorie values', () {
    expect(
      () => calculator.calculate(
        targetCalories: 1800,
        consumedCalories: -10,
        selectedFoodCalories: 0,
      ),
      throwsArgumentError,
    );

    expect(
      () => calculator.calculate(
        targetCalories: 1800,
        consumedCalories: 100,
        selectedFoodCalories: -5,
      ),
      throwsArgumentError,
    );
  });

  test('rejects non-finite calorie values', () {
    for (final value in [
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      expect(
        () => calculator.calculate(
          targetCalories: 1800,
          consumedCalories: value,
          selectedFoodCalories: 100,
        ),
        throwsArgumentError,
      );

      expect(
        () => calculator.calculate(
          targetCalories: 1800,
          consumedCalories: 100,
          selectedFoodCalories: value,
        ),
        throwsArgumentError,
      );
    }
  });

  test('allows zero-calorie selected food', () {
    final result = calculator.calculate(
      targetCalories: 1800,
      consumedCalories: 500,
      selectedFoodCalories: 0,
    );

    expect(result.remainingCalories, 1300);
    expect(result.selectedFoodPercentage, 0);
  });
}
