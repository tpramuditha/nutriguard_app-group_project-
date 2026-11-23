import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/pantry/data/models/pantry_item_model.dart';
import 'package:nutriguard_app/features/pantry/data/models/recipe_model.dart';
import 'package:nutriguard_app/features/pantry/data/services/recipe_matching_service.dart';

void main() {
  const service = RecipeMatchingService();

  PantryItemModel pantryItem({
    String name = 'Rice',
    double quantity = 1,
    String unit = 'kg',
    DateTime? expiryDate,
  }) {
    return PantryItemModel(
      id: '$name-$quantity-$unit',
      name: name,
      quantity: quantity,
      unit: unit,
      category: 'Other',
      expiryDate: expiryDate,
      createdAt: DateTime(2026, 11, 4),
    );
  }

  RecipeModel recipe({
    String id = 'recipe_001',
    String name = 'Test Recipe',
    int preparationMinutes = 10,
    int cookingMinutes = 15,
    List<RecipeIngredient> ingredients = const [],
  }) {
    return RecipeModel(
      id: id,
      name: name,
      description: 'Recipe for automated testing',
      preparationMinutes: preparationMinutes,
      cookingMinutes: cookingMinutes,
      servings: 2,
      calories: 350,
      protein: 12,
      carbs: 55,
      fat: 8,
      ingredients: ingredients,
      instructions: const ['Prepare ingredients', 'Cook ingredients', 'Serve'],
    );
  }

  RecipeIngredient ingredient(String name, double quantity, String unit) {
    return RecipeIngredient(name: name, quantity: quantity, unit: unit);
  }

  group('RecipeMatchingService', () {
    test('matches an available ingredient', () {
      final result = service.matchRecipe(
        recipe: recipe(ingredients: [ingredient('Rice', 500, 'g')]),
        pantryItems: [pantryItem(name: 'Rice', quantity: 1, unit: 'kg')],
      );

      expect(result.matchedIngredients, 1);
      expect(result.isReadyToCook, isTrue);
      expect(result.matchPercentage, 100);
    });

    test('identifies a missing ingredient', () {
      final result = service.matchRecipe(
        recipe: recipe(ingredients: [ingredient('Eggs', 2, 'pcs')]),
        pantryItems: [],
      );

      expect(result.missingIngredients, 1);
      expect(result.matchedIngredients, 0);
      expect(result.isReadyToCook, isFalse);
      expect(result.ingredientMatches.first.isMissing, isTrue);
    });

    test('identifies insufficient ingredient quantity', () {
      final result = service.matchRecipe(
        recipe: recipe(ingredients: [ingredient('Eggs', 4, 'pcs')]),
        pantryItems: [pantryItem(name: 'Eggs', quantity: 2, unit: 'pcs')],
      );

      expect(result.missingIngredients, 0);
      expect(result.insufficientIngredients, 1);
      expect(result.isReadyToCook, isFalse);
      expect(result.ingredientMatches.first.availableQuantity, 2);
    });

    test('converts kilograms to grams', () {
      final result = service.matchRecipe(
        recipe: recipe(ingredients: [ingredient('Rice', 750, 'g')]),
        pantryItems: [pantryItem(quantity: 1, unit: 'kg')],
      );

      expect(result.isReadyToCook, isTrue);
      expect(result.ingredientMatches.first.availableQuantity, 1000);
    });

    test('converts litres to millilitres', () {
      final result = service.matchRecipe(
        recipe: recipe(ingredients: [ingredient('Milk', 500, 'ml')]),
        pantryItems: [pantryItem(name: 'Milk', quantity: 1, unit: 'L')],
      );

      expect(result.isReadyToCook, isTrue);
      expect(result.ingredientMatches.first.availableQuantity, 1000);
    });

    test('combines quantities of matching pantry items', () {
      final result = service.matchRecipe(
        recipe: recipe(ingredients: [ingredient('Rice', 700, 'g')]),
        pantryItems: [
          pantryItem(quantity: 300, unit: 'g'),
          pantryItem(quantity: 500, unit: 'g'),
        ],
      );

      expect(result.isReadyToCook, isTrue);
      expect(result.ingredientMatches.first.availableQuantity, 800);
    });

    test('handles case differences and whitespace', () {
      final result = service.matchRecipe(
        recipe: recipe(ingredients: [ingredient('  RICE  ', 200, 'g')]),
        pantryItems: [pantryItem(name: 'rice', quantity: 1, unit: 'kg')],
      );

      expect(result.isReadyToCook, isTrue);
    });

    test('matches supported singular and plural aliases', () {
      final result = service.matchRecipe(
        recipe: recipe(ingredients: [ingredient('Egg', 2, 'pcs')]),
        pantryItems: [pantryItem(name: 'Eggs', quantity: 4, unit: 'pcs')],
      );

      expect(result.isReadyToCook, isTrue);
    });

    test('rejects incompatible measurement units', () {
      final result = service.matchRecipe(
        recipe: recipe(ingredients: [ingredient('Rice', 200, 'g')]),
        pantryItems: [pantryItem(quantity: 2, unit: 'pcs')],
      );

      expect(result.isReadyToCook, isFalse);
      expect(result.ingredientMatches.first.hasCompatibleUnit, isFalse);
      expect(result.ingredientMatches.first.hasEnough, isFalse);
    });

    test('excludes expired pantry ingredients', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 5));

      final result = service.matchRecipe(
        recipe: recipe(ingredients: [ingredient('Milk', 200, 'ml')]),
        pantryItems: [
          pantryItem(
            name: 'Milk',
            quantity: 1,
            unit: 'L',
            expiryDate: yesterday,
          ),
        ],
      );

      expect(result.isReadyToCook, isFalse);
      expect(result.missingIngredients, 1);
    });

    test('calculates match percentage correctly', () {
      final result = service.matchRecipe(
        recipe: recipe(
          ingredients: [
            ingredient('Rice', 200, 'g'),
            ingredient('Eggs', 2, 'pcs'),
            ingredient('Carrots', 100, 'g'),
            ingredient('Milk', 200, 'ml'),
          ],
        ),
        pantryItems: [
          pantryItem(quantity: 500, unit: 'g'),
          pantryItem(name: 'Eggs', quantity: 4, unit: 'pcs'),
          pantryItem(name: 'Carrots', quantity: 200, unit: 'g'),
        ],
      );

      expect(result.totalIngredients, 4);
      expect(result.matchedIngredients, 3);
      expect(result.missingIngredients, 1);
      expect(result.matchPercentage, 75);
      expect(result.isMissingAFew, isTrue);
    });

    test('does not mark empty recipes as ready to cook', () {
      final result = service.matchRecipe(recipe: recipe(), pantryItems: []);

      expect(result.totalIngredients, 0);
      expect(result.matchPercentage, 0);
      expect(result.isReadyToCook, isFalse);
      expect(result.isMissingAFew, isFalse);
    });

    test('ranks ready-to-cook recipes first', () {
      final readyRecipe = recipe(
        id: 'ready',
        name: 'Rice Bowl',
        ingredients: [ingredient('Rice', 200, 'g')],
      );

      final missingRecipe = recipe(
        id: 'missing',
        name: 'Egg Curry',
        ingredients: [
          ingredient('Eggs', 2, 'pcs'),
          ingredient('Onions', 100, 'g'),
        ],
      );

      final results = service.matchRecipes(
        recipes: [missingRecipe, readyRecipe],
        pantryItems: [pantryItem(name: 'Rice', quantity: 1, unit: 'kg')],
      );

      expect(results.length, 2);
      expect(results.first.recipe.id, 'ready');
      expect(results.first.isReadyToCook, isTrue);
      expect(results.last.recipe.id, 'missing');
    });

    test('ranks faster recipes first when matches are equal', () {
      final slowRecipe = recipe(
        id: 'slow',
        preparationMinutes: 15,
        cookingMinutes: 30,
        ingredients: [ingredient('Rice', 200, 'g')],
      );

      final fastRecipe = recipe(
        id: 'fast',
        preparationMinutes: 5,
        cookingMinutes: 10,
        ingredients: [ingredient('Rice', 200, 'g')],
      );

      final results = service.matchRecipes(
        recipes: [slowRecipe, fastRecipe],
        pantryItems: [pantryItem(quantity: 1, unit: 'kg')],
      );

      expect(results.first.recipe.id, 'fast');
      expect(results.first.recipe.totalMinutes, 15);
    });
  });
}
