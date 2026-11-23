import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/pantry/data/catalog/recipe_catalog.dart';
import 'package:nutriguard_app/features/pantry/data/models/recipe_model.dart';

void main() {
  RecipeModel createRecipe({int servings = 2}) {
    return RecipeModel(
      id: 'test_recipe',
      name: 'Test Fried Rice',
      description: 'Test recipe for nutrition calculations',
      preparationMinutes: 10,
      cookingMinutes: 15,
      servings: servings,
      calories: 420,
      protein: 15,
      carbs: 58,
      fat: 14,
      ingredients: const [
        RecipeIngredient(name: 'Rice', quantity: 150, unit: 'g'),
        RecipeIngredient(name: 'Eggs', quantity: 2, unit: 'pcs'),
      ],
      instructions: const ['Prepare ingredients', 'Cook and serve'],
    );
  }

  group('Recipe nutrition calculations', () {
    test('returns estimated calories per serving', () {
      final recipe = createRecipe();

      expect(recipe.caloriesPerServing, 420);
    });

    test('returns estimated macros per serving', () {
      final recipe = createRecipe();

      expect(recipe.proteinPerServing, 15);
      expect(recipe.carbsPerServing, 58);
      expect(recipe.fatPerServing, 14);
    });

    test('calculates total recipe calories', () {
      final recipe = createRecipe();

      expect(recipe.totalRecipeCalories, 840);
    });

    test('calculates total recipe protein', () {
      final recipe = createRecipe();

      expect(recipe.totalRecipeProtein, 30);
    });

    test('calculates total recipe carbohydrates', () {
      final recipe = createRecipe();

      expect(recipe.totalRecipeCarbs, 116);
    });

    test('calculates total recipe fat', () {
      final recipe = createRecipe();

      expect(recipe.totalRecipeFat, 28);
    });

    test('calculates ingredient quantity per serving', () {
      final recipe = createRecipe();

      final rice = recipe.ingredients.first;

      expect(recipe.ingredientQuantityPerServing(rice), 75);
    });

    test('calculates egg quantity per serving', () {
      final recipe = createRecipe();

      final eggs = recipe.ingredients.last;

      expect(recipe.ingredientQuantityPerServing(eggs), 1);
    });

    test('handles a single-serving recipe', () {
      final recipe = createRecipe(servings: 1);

      expect(recipe.totalRecipeCalories, 420);
      expect(recipe.totalRecipeProtein, 15);
      expect(
        recipe.ingredientQuantityPerServing(recipe.ingredients.first),
        150,
      );
    });

    test('rejects ingredient calculation with zero servings', () {
      final recipe = createRecipe(servings: 0);

      expect(
        () => recipe.ingredientQuantityPerServing(recipe.ingredients.first),
        throwsStateError,
      );
    });

    test('catalog recipe totals use serving count', () {
      final recipe = RecipeCatalog.getRecipeById('egg_fried_rice')!;

      expect(recipe.servings, 2);
      expect(recipe.caloriesPerServing, 420);
      expect(recipe.totalRecipeCalories, 840);
    });

    test('all catalog recipes have positive serving counts', () {
      for (final recipe in RecipeCatalog.getAllRecipes()) {
        expect(recipe.servings, greaterThan(0));
        expect(recipe.caloriesPerServing, greaterThanOrEqualTo(0));

        expect(
          recipe.totalRecipeCalories,
          closeTo(recipe.caloriesPerServing * recipe.servings, 0.001),
        );
      }
    });
  });
}
