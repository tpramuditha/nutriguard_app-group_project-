import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/meals/data/services/meal_recommendation_service.dart';
import 'package:nutriguard_app/features/nutrition/data/models/nutrition_goal_model.dart';
import 'package:nutriguard_app/features/pantry/data/models/pantry_item_model.dart';

void main() {
  const service = MealRecommendationService();

  const nutritionGoal = NutritionGoalModel(
    dailyCalorieTarget: 2400,
    goalType: 'Maintain Weight',
  );

  final emptyPantry = <PantryItemModel>[];

  group('MealRecommendationService', () {
    test('returns two breakfast recommendations', () {
      final results = service.getRecommendations(
        mealType: 'Breakfast',
        pantryItems: emptyPantry,
        nutritionGoal: nutritionGoal,
      );

      expect(results.length, 2);

      expect(
        results.map((result) => result.recipe.id),
        containsAll(['vegetable_omelette', 'boiled_eggs']),
      );
    });

    test('returns four lunch recommendations', () {
      final results = service.getRecommendations(
        mealType: 'Lunch',
        pantryItems: emptyPantry,
        nutritionGoal: nutritionGoal,
      );

      expect(results.length, 4);
    });

    test('returns three dinner recommendations', () {
      final results = service.getRecommendations(
        mealType: 'Dinner',
        pantryItems: emptyPantry,
        nutritionGoal: nutritionGoal,
      );

      expect(results.length, 3);
    });

    test('returns one snack recommendation', () {
      final results = service.getRecommendations(
        mealType: 'Snack',
        pantryItems: emptyPantry,
        nutritionGoal: nutritionGoal,
      );

      expect(results.length, 1);
      expect(results.first.recipe.id, 'boiled_eggs');
    });

    test('returns a top breakfast recommendation', () {
      final result = service.getTopRecommendation(
        mealType: 'Breakfast',
        pantryItems: emptyPantry,
        nutritionGoal: nutritionGoal,
      );

      expect(result, isNotNull);
      expect([
        'vegetable_omelette',
        'boiled_eggs',
      ], contains(result!.recipe.id));
    });

    test('top recommendation matches first ranked result', () {
      final results = service.getRecommendations(
        mealType: 'Lunch',
        pantryItems: emptyPantry,
        nutritionGoal: nutritionGoal,
      );

      final top = service.getTopRecommendation(
        mealType: 'Lunch',
        pantryItems: emptyPantry,
        nutritionGoal: nutritionGoal,
      );

      expect(top, isNotNull);
      expect(top!.recipe.id, results.first.recipe.id);
    });

    test('empty pantry does not mark recipes ready to cook', () {
      final results = service.getRecommendations(
        mealType: 'Breakfast',
        pantryItems: emptyPantry,
        nutritionGoal: nutritionGoal,
      );

      expect(results.every((result) => !result.isReadyToCook), isTrue);
    });

    test('ready-to-cook count is zero for empty pantry', () {
      final count = service.getReadyToCookCount(
        mealType: 'Dinner',
        pantryItems: emptyPantry,
        nutritionGoal: nutritionGoal,
      );

      expect(count, 0);
    });

    test('each recommendation includes a calorie comparison', () {
      final results = service.getRecommendations(
        mealType: 'Lunch',
        pantryItems: emptyPantry,
        nutritionGoal: nutritionGoal,
      );

      expect(
        results.every(
          (result) =>
              result.estimatedMealCalorieGuide == 800 &&
              result.calorieDifference >= 0,
        ),
        isTrue,
      );
    });

    test('recommendations contain pantry match information', () {
      final results = service.getRecommendations(
        mealType: 'Lunch',
        pantryItems: emptyPantry,
        nutritionGoal: nutritionGoal,
      );

      expect(
        results.every(
          (result) =>
              result.matchResult.totalIngredients > 0 &&
              result.matchPercentage == 0,
        ),
        isTrue,
      );
    });

    test('rejects an invalid meal type', () {
      expect(
        () => service.getRecommendations(
          mealType: 'Brunch',
          pantryItems: emptyPantry,
          nutritionGoal: nutritionGoal,
        ),
        throwsArgumentError,
      );
    });

    test('rejects an empty meal type', () {
      expect(
        () => service.getRecommendations(
          mealType: '',
          pantryItems: emptyPantry,
          nutritionGoal: nutritionGoal,
        ),
        throwsArgumentError,
      );
    });
  });
}
