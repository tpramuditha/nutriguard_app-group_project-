import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/meals/data/services/meal_category_service.dart';
import 'package:nutriguard_app/features/pantry/data/models/recipe_model.dart';
import 'package:nutriguard_app/features/pantry/data/catalog/recipe_catalog.dart';

void main() {
  const service = MealCategoryService();

  // Use the existing recipe catalog so tests match actual recipes.
  final recipes = RecipeCatalog.recipes;

  RecipeModel recipeById(String id) {
    return recipes.firstWhere((recipe) => recipe.id == id);
  }

  group('MealCategoryService', () {
    test('supports four meal types', () {
      expect(MealCategoryService.mealTypes, [
        'Breakfast',
        'Lunch',
        'Dinner',
        'Snack',
      ]);
    });

    test('recognizes valid meal types', () {
      expect(service.isValidMealType('Breakfast'), isTrue);
      expect(service.isValidMealType('Lunch'), isTrue);
      expect(service.isValidMealType('Dinner'), isTrue);
      expect(service.isValidMealType('Snack'), isTrue);
    });

    test('rejects invalid meal type', () {
      expect(service.isValidMealType('Brunch'), isFalse);
    });

    test('returns breakfast recipes', () {
      final results = service.filterRecipes(
        recipes: recipes,
        mealType: 'Breakfast',
      );

      expect(
        results.map((recipe) => recipe.id),
        containsAll(['vegetable_omelette', 'boiled_eggs']),
      );

      expect(results.length, 2);
    });

    test('returns lunch recipes', () {
      final results = service.filterRecipes(
        recipes: recipes,
        mealType: 'Lunch',
      );

      expect(results.length, 4);

      expect(results.map((recipe) => recipe.id), contains('egg_fried_rice'));
    });

    test('returns dinner recipes', () {
      final results = service.filterRecipes(
        recipes: recipes,
        mealType: 'Dinner',
      );

      expect(results.length, 3);

      expect(results.map((recipe) => recipe.id), contains('rice_and_dhal'));
    });

    test('returns snack recipes', () {
      final results = service.filterRecipes(
        recipes: recipes,
        mealType: 'Snack',
      );

      expect(results.length, 1);
      expect(results.first.id, 'boiled_eggs');
    });

    test('recipe can belong to multiple meal types', () {
      final omelette = recipeById('vegetable_omelette');

      expect(
        service.isRecipeSuitableForMealType(
          recipe: omelette,
          mealType: 'Breakfast',
        ),
        isTrue,
      );

      expect(
        service.isRecipeSuitableForMealType(
          recipe: omelette,
          mealType: 'Lunch',
        ),
        isTrue,
      );
    });

    test('recipe is excluded from unrelated meal types', () {
      final eggs = recipeById('boiled_eggs');

      expect(
        service.isRecipeSuitableForMealType(recipe: eggs, mealType: 'Dinner'),
        isFalse,
      );
    });

    test('unknown recipe ID has no meal categories', () {
      expect(service.getMealTypesForRecipe('unknown_recipe'), isEmpty);
    });

    test('invalid meal type throws ArgumentError', () {
      expect(
        () => service.filterRecipes(recipes: recipes, mealType: 'Brunch'),
        throwsArgumentError,
      );
    });

    test('counts recipes correctly', () {
      expect(service.countRecipes(recipes: recipes, mealType: 'Breakfast'), 2);

      expect(service.countRecipes(recipes: recipes, mealType: 'Lunch'), 4);

      expect(service.countRecipes(recipes: recipes, mealType: 'Dinner'), 3);

      expect(service.countRecipes(recipes: recipes, mealType: 'Snack'), 1);
    });

    test('returns empty list for empty recipe catalog', () {
      final results = service.filterRecipes(
        recipes: <RecipeModel>[],
        mealType: 'Breakfast',
      );

      expect(results, isEmpty);
    });
  });
}
