class NutritionBudgetResult {
  final int targetCalories;
  final double consumedCalories;
  final double selectedFoodCalories;

  const NutritionBudgetResult({
    required this.targetCalories,
    required this.consumedCalories,
    required this.selectedFoodCalories,
  });

  double get remainingCalories => targetCalories - consumedCalories;

  double get progress {
    if (targetCalories <= 0) return 0;

    return (consumedCalories / targetCalories).clamp(0.0, 1.0);
  }

  double get consumedPercentage {
    if (targetCalories <= 0) return 0;

    return consumedCalories / targetCalories * 100;
  }

  double get selectedFoodPercentage {
    if (targetCalories <= 0) return 0;

    return selectedFoodCalories / targetCalories * 100;
  }

  bool get isOverTarget => remainingCalories < 0;
}

class NutritionBudgetCalculator {
  NutritionBudgetResult calculate({
    required int targetCalories,
    required double consumedCalories,
    required double selectedFoodCalories,
  }) {
    if (targetCalories <= 0) {
      throw ArgumentError('Daily calorie target must be greater than zero.');
    }

    if (!consumedCalories.isFinite ||
        consumedCalories < 0 ||
        !selectedFoodCalories.isFinite ||
        selectedFoodCalories < 0) {
      throw ArgumentError('Calories must be finite and non-negative.');
    }

    return NutritionBudgetResult(
      targetCalories: targetCalories,
      consumedCalories: consumedCalories,
      selectedFoodCalories: selectedFoodCalories,
    );
  }
}
