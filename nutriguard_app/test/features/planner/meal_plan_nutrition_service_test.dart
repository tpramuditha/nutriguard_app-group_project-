import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/planner/data/models/planned_meal_model.dart';
import 'package:nutriguard_app/features/planner/data/services/meal_plan_nutrition_service.dart';

void main() {
  const service = MealPlanNutritionService();

  const breakfast = PlannedMealModel(
    id: 'meal_001',
    date: '2026-11-08',
    mealType: 'Breakfast',
    recipeId: 'boiled_eggs',
    servings: 1,
  );

  const lunch = PlannedMealModel(
    id: 'meal_002',
    date: '2026-11-08',
    mealType: 'Lunch',
    recipeId: 'egg_fried_rice',
    servings: 2,
  );

  const dinner = PlannedMealModel(
    id: 'meal_003',
    date: '2026-11-08',
    mealType: 'Dinner',
    recipeId: 'rice_and_dhal',
    servings: 1,
  );

  const nextDay = PlannedMealModel(
    id: 'meal_004',
    date: '2026-11-09',
    mealType: 'Breakfast',
    recipeId: 'vegetable_omelette',
    servings: 1,
  );

  group('MealPlanNutritionService', () {
    test('calculates nutrition for one serving', () {
      final totals = service.calculateMeal(breakfast);

      expect(totals.calories, 155);
      expect(totals.protein, 13);
      expect(totals.carbs, 1);
      expect(totals.fat, 11);
    });

    test('multiplies nutrition by planned servings', () {
      final totals = service.calculateMeal(lunch);

      expect(totals.calories, 840);
      expect(totals.protein, 30);
      expect(totals.carbs, 116);
      expect(totals.fat, 28);
    });

    test('calculates one serving of rice and dhal', () {
      final totals = service.calculateMeal(dinner);

      expect(totals.calories, 450);
      expect(totals.protein, 17);
      expect(totals.carbs, 78);
      expect(totals.fat, 8);
    });

    test('calculates combined nutrition for three meals', () {
      final totals = service.calculateTotal([breakfast, lunch, dinner]);

      expect(totals.calories, 1445);
      expect(totals.protein, 60);
      expect(totals.carbs, 195);
      expect(totals.fat, 47);
    });

    test('returns zero nutrition for empty meal list', () {
      final totals = service.calculateTotal([]);

      expect(totals.calories, 0);
      expect(totals.protein, 0);
      expect(totals.carbs, 0);
      expect(totals.fat, 0);
    });

    test('filters daily totals by selected date', () {
      final totals = service.calculateDailyTotal(
        date: '2026-11-08',
        plannedMeals: [breakfast, lunch, dinner, nextDay],
      );

      expect(totals.calories, 1445);
    });

    test('returns zero for a day with no planned meals', () {
      final totals = service.calculateDailyTotal(
        date: '2026-11-10',
        plannedMeals: [breakfast, lunch, dinner],
      );

      expect(totals.calories, 0);
      expect(totals.protein, 0);
    });

    test('calculates totals for each meal type', () {
      final totals = service.calculateByMealType(
        date: '2026-11-08',
        plannedMeals: [breakfast, lunch, dinner, nextDay],
      );

      expect(totals['Breakfast']!.calories, 155);
      expect(totals['Lunch']!.calories, 840);
      expect(totals['Dinner']!.calories, 450);
      expect(totals['Snack']!.calories, 0);
    });

    test('keeps calculations separate by date', () {
      final totals = service.calculateDailyTotal(
        date: '2026-11-09',
        plannedMeals: [breakfast, lunch, dinner, nextDay],
      );

      expect(totals.calories, 260);
    });

    test('throws when recipe does not exist', () {
      const unknownMeal = PlannedMealModel(
        id: 'meal_unknown',
        date: '2026-11-08',
        mealType: 'Lunch',
        recipeId: 'missing_recipe',
        servings: 1,
      );

      expect(() => service.calculateMeal(unknownMeal), throwsStateError);
    });

    test('rejects invalid planned servings', () {
      const invalidMeal = PlannedMealModel(
        id: 'invalid_meal',
        date: '2026-11-08',
        mealType: 'Lunch',
        recipeId: 'egg_fried_rice',
        servings: 0,
      );

      expect(() => service.calculateMeal(invalidMeal), throwsArgumentError);
    });

    test('adds nutrition totals correctly', () {
      const a = MealPlanNutritionTotals(
        calories: 100,
        protein: 10,
        carbs: 20,
        fat: 5,
      );

      const b = MealPlanNutritionTotals(
        calories: 200,
        protein: 15,
        carbs: 30,
        fat: 8,
      );

      final result = a + b;

      expect(result.calories, 300);
      expect(result.protein, 25);
      expect(result.carbs, 50);
      expect(result.fat, 13);
    });
  });
}
