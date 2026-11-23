import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/pantry/data/catalog/recipe_catalog.dart';
import 'package:nutriguard_app/features/pantry/data/models/pantry_item_model.dart';
import 'package:nutriguard_app/features/pantry/data/services/recipe_matching_service.dart';

void main() {
  const matchingService = RecipeMatchingService();

  PantryItemModel createPantryItem({
    required String name,
    required double quantity,
    required String unit,
  }) {
    return PantryItemModel(
      id: name.toLowerCase().replaceAll(' ', '_'),
      name: name,
      quantity: quantity,
      unit: unit,
      category: 'Other',
      createdAt: DateTime(2026, 11, 4),
    );
  }

  group('RecipeCatalog', () {
    test('contains five initial recipes', () {
      final recipes = RecipeCatalog.getAllRecipes();

      expect(recipes.length, 5);
    });

    test('all recipe IDs are unique', () {
      final recipes = RecipeCatalog.getAllRecipes();

      final ids = recipes.map((recipe) => recipe.id).toSet();

      expect(ids.length, recipes.length);
    });

    test('every recipe has required information', () {
      final recipes = RecipeCatalog.getAllRecipes();

      for (final recipe in recipes) {
        expect(recipe.id.trim(), isNotEmpty);
        expect(recipe.name.trim(), isNotEmpty);
        expect(recipe.description.trim(), isNotEmpty);
        expect(recipe.servings, greaterThan(0));
        expect(recipe.totalMinutes, greaterThan(0));
        expect(recipe.ingredients, isNotEmpty);
        expect(recipe.instructions, isNotEmpty);
      }
    });

    test('every recipe ingredient has a valid quantity', () {
      final recipes = RecipeCatalog.getAllRecipes();

      for (final recipe in recipes) {
        for (final ingredient in recipe.ingredients) {
          expect(ingredient.name.trim(), isNotEmpty);
          expect(ingredient.unit.trim(), isNotEmpty);
          expect(ingredient.quantity.isFinite, isTrue);
          expect(ingredient.quantity, greaterThan(0));
        }
      }
    });

    test('nutrition estimates are non-negative', () {
      final recipes = RecipeCatalog.getAllRecipes();

      for (final recipe in recipes) {
        expect(recipe.calories, greaterThanOrEqualTo(0));
        expect(recipe.protein, greaterThanOrEqualTo(0));
        expect(recipe.carbs, greaterThanOrEqualTo(0));
        expect(recipe.fat, greaterThanOrEqualTo(0));
      }
    });

    test('can find a recipe by its ID', () {
      final recipe = RecipeCatalog.getRecipeById('egg_fried_rice');

      expect(recipe, isNotNull);
      expect(recipe!.name, 'Egg Fried Rice');
      expect(recipe.servings, 2);
      expect(recipe.totalMinutes, 25);
    });

    test('returns null for an unknown recipe ID', () {
      final recipe = RecipeCatalog.getRecipeById('unknown_recipe');

      expect(recipe, isNull);
    });

    test('catalog list cannot be modified', () {
      final recipes = RecipeCatalog.getAllRecipes();

      expect(() => recipes.clear(), throwsUnsupportedError);
    });

    test('boiled eggs is ready with two pantry eggs', () {
      final recipe = RecipeCatalog.getRecipeById('boiled_eggs')!;

      final result = matchingService.matchRecipe(
        recipe: recipe,
        pantryItems: [createPantryItem(name: 'Eggs', quantity: 2, unit: 'pcs')],
      );

      expect(result.isReadyToCook, isTrue);
      expect(result.matchPercentage, 100);
      expect(result.missingIngredients, 0);
    });

    test('egg fried rice identifies missing ingredients', () {
      final recipe = RecipeCatalog.getRecipeById('egg_fried_rice')!;

      final result = matchingService.matchRecipe(
        recipe: recipe,
        pantryItems: [
          createPantryItem(name: 'Rice', quantity: 1, unit: 'kg'),
          createPantryItem(name: 'Eggs', quantity: 4, unit: 'pcs'),
        ],
      );

      expect(result.isReadyToCook, isFalse);
      expect(result.matchedIngredients, 2);
      expect(result.missingIngredients, 3);
      expect(result.matchPercentage, 40);
      expect(result.isMissingAFew, isTrue);
    });

    test('all catalog recipes can be matched and ranked', () {
      final pantryItems = [
        createPantryItem(name: 'Eggs', quantity: 6, unit: 'pcs'),
        createPantryItem(name: 'Rice', quantity: 1, unit: 'kg'),
      ];

      final results = matchingService.matchRecipes(
        recipes: RecipeCatalog.getAllRecipes(),
        pantryItems: pantryItems,
      );

      expect(results.length, 5);
      expect(results.first.recipe.id, 'boiled_eggs');
      expect(results.first.isReadyToCook, isTrue);
    });
  });
}
