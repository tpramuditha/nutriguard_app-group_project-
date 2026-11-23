import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/nutrition/data/models/nutrition_goal_model.dart';
import 'package:nutriguard_app/features/pantry/data/models/pantry_item_model.dart';
import 'package:nutriguard_app/features/pantry/data/models/recipe_model.dart';
import 'package:nutriguard_app/features/pantry/data/services/recipe_goal_ranking_service.dart';
import 'package:nutriguard_app/features/pantry/data/services/recipe_matching_service.dart';

void main() {
  const matchingService = RecipeMatchingService();
  const rankingService = RecipeGoalRankingService();

  const defaultGoal = NutritionGoalModel(
    dailyCalorieTarget: 2100,
    goalType: 'Maintain Weight',
  );

  RecipeModel makeRecipe({
    required String id,
    required double calories,
    int preparationMinutes = 10,
    int cookingMinutes = 10,
    List<RecipeIngredient> ingredients = const [
      RecipeIngredient(name: 'Rice', quantity: 200, unit: 'g'),
    ],
  }) {
    return RecipeModel(
      id: id,
      name: id,
      description: 'Test recipe',
      preparationMinutes: preparationMinutes,
      cookingMinutes: cookingMinutes,
      servings: 1,
      calories: calories,
      protein: 10,
      carbs: 30,
      fat: 5,
      ingredients: ingredients,
      instructions: const ['Cook and serve.'],
    );
  }

  PantryItemModel makePantryItem({
    required String name,
    required double quantity,
    required String unit,
  }) {
    return PantryItemModel(
      id: name,
      name: name,
      quantity: quantity,
      unit: unit,
      category: 'Other',
      createdAt: DateTime(2026, 11, 6),
    );
  }

  RecipeMatchResult match(
    RecipeModel recipe,
    List<PantryItemModel> pantryItems,
  ) {
    return matchingService.matchRecipe(
      recipe: recipe,
      pantryItems: pantryItems,
    );
  }

  List<PantryItemModel> ricePantry() => [
    makePantryItem(name: 'Rice', quantity: 1, unit: 'kg'),
  ];

  group('RecipeGoalRankingService', () {
    test('calculates one-third daily calorie guide', () {
      final guide = rankingService.estimatedMealCalorieGuide(defaultGoal);

      expect(guide, closeTo(700, 0.001));
    });

    test('evaluates calorie difference correctly', () {
      final recipe = makeRecipe(id: 'rice_bowl', calories: 650);

      final result = rankingService.evaluateRecipe(
        matchResult: match(recipe, ricePantry()),
        nutritionGoal: defaultGoal,
      );

      expect(result.estimatedMealCalorieGuide, closeTo(700, 0.001));
      expect(result.calorieDifference, closeTo(50, 0.001));
      expect(result.isReadyToCook, isTrue);
    });

    test('describes recipe close to calorie guide', () {
      final result = rankingService.evaluateRecipe(
        matchResult: match(
          makeRecipe(id: 'close', calories: 650),
          ricePantry(),
        ),
        nutritionGoal: defaultGoal,
      );

      expect(
        result.calorieInsight,
        'Close to your estimated meal calorie guide',
      );
    });

    test('describes recipe below calorie guide', () {
      final result = rankingService.evaluateRecipe(
        matchResult: match(
          makeRecipe(id: 'below', calories: 400),
          ricePantry(),
        ),
        nutritionGoal: defaultGoal,
      );

      expect(result.calorieInsight, 'Below your estimated meal calorie guide');
    });

    test('describes recipe above calorie guide', () {
      final result = rankingService.evaluateRecipe(
        matchResult: match(
          makeRecipe(id: 'above', calories: 950),
          ricePantry(),
        ),
        nutritionGoal: defaultGoal,
      );

      expect(result.calorieInsight, 'Above your estimated meal calorie guide');
    });

    test('prioritizes ready-to-cook recipes', () {
      final ready = makeRecipe(id: 'ready', calories: 300);

      final notReady = makeRecipe(
        id: 'not_ready',
        calories: 700,
        ingredients: const [
          RecipeIngredient(name: 'Eggs', quantity: 2, unit: 'pcs'),
        ],
      );

      final results = rankingService.rankRecipes(
        recipeMatches: [
          match(notReady, ricePantry()),
          match(ready, ricePantry()),
        ],
        nutritionGoal: defaultGoal,
      );

      expect(results.first.recipe.id, 'ready');
      expect(results.first.isReadyToCook, isTrue);
    });

    test('prioritizes higher ingredient match percentage', () {
      final higherMatch = makeRecipe(
        id: 'higher_match',
        calories: 300,
        ingredients: const [
          RecipeIngredient(name: 'Rice', quantity: 200, unit: 'g'),
          RecipeIngredient(name: 'Eggs', quantity: 2, unit: 'pcs'),
        ],
      );

      final lowerMatch = makeRecipe(
        id: 'lower_match',
        calories: 700,
        ingredients: const [
          RecipeIngredient(name: 'Rice', quantity: 200, unit: 'g'),
          RecipeIngredient(name: 'Eggs', quantity: 2, unit: 'pcs'),
          RecipeIngredient(name: 'Milk', quantity: 100, unit: 'ml'),
        ],
      );

      final results = rankingService.rankRecipes(
        recipeMatches: [
          match(lowerMatch, ricePantry()),
          match(higherMatch, ricePantry()),
        ],
        nutritionGoal: defaultGoal,
      );

      expect(results.first.recipe.id, 'higher_match');
      expect(results.first.matchPercentage, 50);
    });

    test('uses calorie closeness when match levels are equal', () {
      final farRecipe = makeRecipe(id: 'far', calories: 300);

      final closeRecipe = makeRecipe(id: 'close', calories: 680);

      final results = rankingService.rankRecipes(
        recipeMatches: [
          match(farRecipe, ricePantry()),
          match(closeRecipe, ricePantry()),
        ],
        nutritionGoal: defaultGoal,
      );

      expect(results.first.recipe.id, 'close');
      expect(results.first.calorieDifference, closeTo(20, 0.001));
    });

    test('uses shorter cooking time when calorie differences tie', () {
      final slow = makeRecipe(
        id: 'slow',
        calories: 650,
        preparationMinutes: 15,
        cookingMinutes: 30,
      );

      final fast = makeRecipe(
        id: 'fast',
        calories: 650,
        preparationMinutes: 5,
        cookingMinutes: 10,
      );

      final results = rankingService.rankRecipes(
        recipeMatches: [match(slow, ricePantry()), match(fast, ricePantry())],
        nutritionGoal: defaultGoal,
      );

      expect(results.first.recipe.id, 'fast');
      expect(results.first.recipe.totalMinutes, 15);
    });

    test('uses recipe ID to break complete ranking ties', () {
      final recipeB = makeRecipe(id: 'recipe_b', calories: 650);

      final recipeA = makeRecipe(id: 'recipe_a', calories: 650);

      final results = rankingService.rankRecipes(
        recipeMatches: [
          match(recipeB, ricePantry()),
          match(recipeA, ricePantry()),
        ],
        nutritionGoal: defaultGoal,
      );

      expect(results.first.recipe.id, 'recipe_a');
    });

    test('does not modify the original match list', () {
      final matches = [
        match(makeRecipe(id: 'first', calories: 350), ricePantry()),
        match(makeRecipe(id: 'second', calories: 690), ricePantry()),
      ];

      rankingService.rankRecipes(
        recipeMatches: matches,
        nutritionGoal: defaultGoal,
      );

      expect(matches.first.recipe.id, 'first');
      expect(matches.last.recipe.id, 'second');
    });

    test('returns an empty list for no recipes', () {
      final results = rankingService.rankRecipes(
        recipeMatches: [],
        nutritionGoal: defaultGoal,
      );

      expect(results, isEmpty);
    });
  });
}
