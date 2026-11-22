import '../../../food_scanner/data/models/food_log_model.dart';

class DailyNutritionSummary {
  final DateTime date;
  final int foodCount;

  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;

  final Map<String, double> mealCalories;

  const DailyNutritionSummary({
    required this.date,
    required this.foodCount,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.mealCalories,
  });
}

class NutritionAnalysisService {
  DailyNutritionSummary calculateDailyNutrition({
    required List<FoodLogModel> foodLogs,
    required DateTime selectedDate,
  }) {
    final dayStart = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    final nextDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day + 1,
    );

    final dailyLogs = foodLogs.where((log) {
      final loggedAt = log.loggedAt.toLocal();

      return !loggedAt.isBefore(dayStart) && loggedAt.isBefore(nextDay);
    }).toList();

    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;

    final mealCalories = <String, double>{
      'Breakfast': 0,
      'Lunch': 0,
      'Dinner': 0,
      'Snack': 0,
    };

    for (final log in dailyLogs) {
      calories += log.calories;
      protein += log.protein;
      carbs += log.carbs;
      fat += log.fat;

      if (mealCalories.containsKey(log.mealType)) {
        mealCalories[log.mealType] = mealCalories[log.mealType]! + log.calories;
      }
    }

    return DailyNutritionSummary(
      date: dayStart,
      foodCount: dailyLogs.length,
      totalCalories: calories,
      totalProtein: protein,
      totalCarbs: carbs,
      totalFat: fat,
      mealCalories: Map.unmodifiable(mealCalories),
    );
  }
}
