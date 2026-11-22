import '../../../food_scanner/data/models/food_log_model.dart';

class DailyProgressSummary {
  final DateTime date;
  final int mealCount;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  const DailyProgressSummary({
    required this.date,
    required this.mealCount,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  double calorieGoalPercentage(int dailyTarget) {
    if (dailyTarget <= 0) return 0;

    return (calories / dailyTarget) * 100;
  }
}

class GoalAdherenceResult {
  final int loggedDays;
  final int daysWithinTarget;

  const GoalAdherenceResult({
    required this.loggedDays,
    required this.daysWithinTarget,
  });

  double get percentage {
    if (loggedDays == 0) return 0;

    return (daysWithinTarget / loggedDays) * 100;
  }
}

class ProgressCalculationService {
  const ProgressCalculationService();

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _sameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  DailyProgressSummary calculateDailySummary({
    required DateTime date,
    required List<FoodLogModel> foodLogs,
  }) {
    final selectedDate = _dateOnly(date);

    final dailyLogs = foodLogs.where((log) {
      return _sameDay(log.loggedAt.toLocal(), selectedDate);
    }).toList();

    return DailyProgressSummary(
      date: selectedDate,
      mealCount: dailyLogs.length,
      calories: dailyLogs.fold<double>(0, (sum, log) => sum + log.calories),
      protein: dailyLogs.fold<double>(0, (sum, log) => sum + log.protein),
      carbs: dailyLogs.fold<double>(0, (sum, log) => sum + log.carbs),
      fat: dailyLogs.fold<double>(0, (sum, log) => sum + log.fat),
    );
  }

  List<DailyProgressSummary> calculateDateRange({
    required DateTime startDate,
    required DateTime endDate,
    required List<FoodLogModel> foodLogs,
  }) {
    final start = _dateOnly(startDate);
    final end = _dateOnly(endDate);

    if (end.isBefore(start)) {
      throw ArgumentError('End date cannot be before start date.');
    }

    final summaries = <DailyProgressSummary>[];

    for (
      var current = start;
      !current.isAfter(end);
      current = DateTime(current.year, current.month, current.day + 1)
    ) {
      summaries.add(calculateDailySummary(date: current, foodLogs: foodLogs));
    }

    return summaries;
  }

  int calculateLoggingStreak({
    required List<FoodLogModel> foodLogs,
    required DateTime today,
  }) {
    final loggedDates = foodLogs
        .map((log) => _dateOnly(log.loggedAt.toLocal()))
        .toSet();

    var currentDate = _dateOnly(today);

    // A streak remains active if the user logged yesterday
    // but has not logged anything today yet.
    if (!loggedDates.contains(currentDate)) {
      currentDate = DateTime(
        currentDate.year,
        currentDate.month,
        currentDate.day - 1,
      );
    }

    var streak = 0;

    while (loggedDates.contains(currentDate)) {
      streak++;

      currentDate = DateTime(
        currentDate.year,
        currentDate.month,
        currentDate.day - 1,
      );
    }

    return streak;
  }

  double calculateAverageCalories(List<DailyProgressSummary> summaries) {
    if (summaries.isEmpty) return 0;

    final total = summaries.fold<double>(0, (sum, day) => sum + day.calories);

    return total / summaries.length;
  }

  GoalAdherenceResult calculateGoalAdherence({
    required List<DailyProgressSummary> summaries,
    required int dailyCalorieTarget,
  }) {
    if (dailyCalorieTarget <= 0) {
      throw ArgumentError('Daily calorie target must be greater than zero.');
    }

    const tolerance = 0.10;

    final minimumCalories = dailyCalorieTarget * (1 - tolerance);
    final maximumCalories = dailyCalorieTarget * (1 + tolerance);

    var loggedDays = 0;
    var daysWithinTarget = 0;

    for (final day in summaries) {
      // Exclude days without food log records.
      if (day.mealCount == 0) continue;

      loggedDays++;

      if (day.calories >= minimumCalories && day.calories <= maximumCalories) {
        daysWithinTarget++;
      }
    }

    return GoalAdherenceResult(
      loggedDays: loggedDays,
      daysWithinTarget: daysWithinTarget,
    );
  }
}
