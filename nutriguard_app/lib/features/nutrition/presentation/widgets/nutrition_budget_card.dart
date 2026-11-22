import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../food_scanner/data/models/food_log_model.dart';
import '../../../food_scanner/data/repositories/food_log_repository.dart';
import '../../data/repositories/nutrition_goal_repository.dart';
import '../../domain/services/nutrition_budget_calculator.dart';

class NutritionBudgetCard extends StatefulWidget {
  final FoodLogModel foodLog;

  const NutritionBudgetCard({super.key, required this.foodLog});

  @override
  State<NutritionBudgetCard> createState() => _NutritionBudgetCardState();
}

class _BudgetData {
  final int targetCalories;
  final double consumedCalories;

  const _BudgetData({
    required this.targetCalories,
    required this.consumedCalories,
  });
}

class _NutritionBudgetCardState extends State<NutritionBudgetCard> {
  final NutritionBudgetCalculator _budgetCalculator =
      NutritionBudgetCalculator();
  final NutritionGoalRepository _goalRepository = NutritionGoalRepository();

  final FoodLogRepository _foodLogRepository = FoodLogRepository();

  late Future<_BudgetData> _budgetFuture;

  static const Color _teal = Color(0xFF009B8E);
  static const Color _dark = Color(0xFF073D58);

  @override
  void initState() {
    super.initState();
    _budgetFuture = _loadBudget();
  }

  @override
  void didUpdateWidget(covariant NutritionBudgetCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.foodLog != widget.foodLog) {
      _budgetFuture = _loadBudget();
    }
  }

  Future<_BudgetData> _loadBudget() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw StateError('Please log in to view your calorie budget.');
    }

    final goal = await _goalRepository.getNutritionGoal(userId: user.uid);

    final logs = await _foodLogRepository.getFoodLogs(userId: user.uid);

    // Use the selected food's local calendar date.
    // A food logged yesterday belongs to yesterday's budget.
    final selectedDate = widget.foodLog.loggedAt.toLocal();

    final dailyLogs = logs.where((log) {
      final date = log.loggedAt.toLocal();

      return date.year == selectedDate.year &&
          date.month == selectedDate.month &&
          date.day == selectedDate.day;
    });

    final consumedCalories = dailyLogs.fold<double>(
      0,
      (sum, log) => sum + log.calories,
    );

    return _BudgetData(
      targetCalories: goal.dailyCalorieTarget,
      consumedCalories: consumedCalories,
    );
  }

  Widget _content() {
    return FutureBuilder<_BudgetData>(
      future: _budgetFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(18),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Unable to load your calorie budget.',
                style: TextStyle(color: Colors.blueGrey),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _budgetFuture = _loadBudget();
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          );
        }

        final data = snapshot.data!;

        final budget = _budgetCalculator.calculate(
          targetCalories: data.targetCalories,
          consumedCalories: data.consumedCalories,
          selectedFoodCalories: widget.foodLog.calories,
        );

        final consumed = budget.consumedCalories;
        final remaining = budget.remainingCalories;
        final progress = budget.progress;
        final foodPercentage = budget.selectedFoodPercentage;

        final selectedDate = widget.foodLog.loggedAt.toLocal();

        final dateLabel = MaterialLocalizations.of(context)
            .formatMediumDate(selectedDate);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budget for $dateLabel',
              style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                SizedBox(
                  width: 86,
                  height: 86,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 8,
                          color: _teal,
                          backgroundColor: const Color(0xFFE5EFF1),
                        ),
                      ),
                      Text(
                        '${(progress * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: _dark,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 18),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${consumed.toStringAsFixed(0)} kcal consumed',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _dark,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Daily target: ${data.targetCalories} kcal',
                        style: const TextStyle(color: Colors.blueGrey),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        remaining >= 0
                            ? '${remaining.toStringAsFixed(0)} kcal remaining'
                            : '${(-remaining).toStringAsFixed(0)} kcal over target',
                        style: TextStyle(
                          color: remaining >= 0 ? _teal : Colors.deepOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            const Divider(),

            const SizedBox(height: 8),

            Text(
              'This food represents '
              '${foodPercentage.toStringAsFixed(1)}% '
              'of your daily calorie target.',
              style: const TextStyle(color: _dark, fontWeight: FontWeight.w500),
            ),

            const SizedBox(height: 6),

            const Text(
              'Daily totals already include this logged food.',
              style: TextStyle(color: Colors.blueGrey, fontSize: 12),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart, color: _teal),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Impact on Daily Budget',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: _dark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _content(),
        ],
      ),
    );
  }
}
