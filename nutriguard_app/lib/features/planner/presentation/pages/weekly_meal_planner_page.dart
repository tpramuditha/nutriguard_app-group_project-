import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/models/planned_meal_model.dart';
import '../../data/repositories/meal_plan_repository.dart';
import '../../data/services/meal_plan_nutrition_service.dart';

import '../widgets/weekly_meal_day_card.dart';
import 'daily_meal_planner_page.dart';

class WeeklyMealPlannerPage extends StatefulWidget {
  const WeeklyMealPlannerPage({super.key});

  @override
  State<WeeklyMealPlannerPage> createState() => _WeeklyMealPlannerPageState();
}

class _WeeklyMealPlannerPageState extends State<WeeklyMealPlannerPage> {
  final MealPlanRepository _repository = MealPlanRepository();

  final MealPlanNutritionService _nutritionService =
      const MealPlanNutritionService();

  late DateTime _weekStart;

  Stream<List<PlannedMealModel>>? _mealsStream;

  String? _loadedUserId;

  static const List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();

    final today = DateTime.now();

    final dateOnly = DateTime(today.year, today.month, today.day);

    _weekStart = dateOnly.subtract(Duration(days: dateOnly.weekday - 1));

    _loadWeeklyMeals();
  }

  DateTime get _weekEnd => _weekStart.add(const Duration(days: 6));

  String _dateId(DateTime date) {
    return PlannedMealModel.formatDate(date);
  }

  void _loadWeeklyMeals() {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    _loadedUserId = userId;

    if (userId == null) {
      _mealsStream = null;
      return;
    }

    _mealsStream = _repository.watchMealsForRange(
      userId: userId,
      startDate: _dateId(_weekStart),
      endDate: _dateId(_weekEnd),
    );
  }

  void _changeWeek(int offset) {
    setState(() {
      _weekStart = _weekStart.add(Duration(days: offset * 7));

      _loadWeeklyMeals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != _loadedUserId) {
      _loadWeeklyMeals();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFC),
      appBar: AppBar(
        title: const Text('Weekly Meal Planner'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF5FAFC),
      ),
      body: userId == null
          ? const Center(child: Text('Please log in to view your meal plans.'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Previous week',
                        onPressed: () => _changeWeek(-1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              'Selected Week',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '${_dateId(_weekStart)}'
                              ' to ${_dateId(_weekEnd)}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF086F67),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Next week',
                        onPressed: () => _changeWeek(1),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<PlannedMealModel>>(
                    stream: _mealsStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Unable to load weekly meals.'),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final meals = snapshot.data!;

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: 7,
                        itemBuilder: (context, index) {
                          final date = _weekStart.add(Duration(days: index));

                          final dateKey = PlannedMealModel.formatDate(date);

                          final dayMeals = meals
                              .where((meal) => meal.date == dateKey)
                              .toList();

                          final totals = _nutritionService.calculateDailyTotal(
                            date: dateKey,
                            plannedMeals: dayMeals,
                          );

                          final descriptions = dayMeals.map((meal) {
                            final recipe = _nutritionService.getRecipe(
                              meal.recipeId,
                            );

                            return '${meal.mealType}: ${recipe.name} '
                                '(${meal.servings} serving(s))';
                          }).toList();

                          return WeeklyMealDayCard(
                            dayName: _weekdays[date.weekday - 1],
                            date: dateKey,
                            mealCount: dayMeals.length,
                            estimatedCalories: totals.calories,
                            mealDescriptions: descriptions,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      DailyMealPlannerPage(initialDate: date),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
