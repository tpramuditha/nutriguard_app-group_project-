import '../models/pantry_item_model.dart';
import '../models/recipe_model.dart';

class RecipeIngredientMatch {
  final RecipeIngredient ingredient;
  final double availableQuantity;
  final bool isAvailable;
  final bool hasEnough;
  final bool hasCompatibleUnit;

  const RecipeIngredientMatch({
    required this.ingredient,
    required this.availableQuantity,
    required this.isAvailable,
    required this.hasEnough,
    required this.hasCompatibleUnit,
  });

  bool get isMissing => !isAvailable;

  bool get isInsufficient => isAvailable && !hasEnough;
}

class RecipeMatchResult {
  final RecipeModel recipe;
  final List<RecipeIngredientMatch> ingredientMatches;

  const RecipeMatchResult({
    required this.recipe,
    required this.ingredientMatches,
  });

  int get totalIngredients => ingredientMatches.length;

  int get matchedIngredients =>
      ingredientMatches.where((item) => item.hasEnough).length;

  int get missingIngredients =>
      ingredientMatches.where((item) => item.isMissing).length;

  int get insufficientIngredients =>
      ingredientMatches.where((item) => item.isInsufficient).length;

  bool get isReadyToCook =>
      totalIngredients > 0 && ingredientMatches.every((item) => item.hasEnough);

  bool get isMissingAFew =>
      !isReadyToCook &&
      matchedIngredients > 0 &&
      missingIngredients + insufficientIngredients <= 3;

  double get matchPercentage {
    if (totalIngredients == 0) return 0;

    return matchedIngredients / totalIngredients * 100;
  }

  List<RecipeIngredientMatch> get unavailableIngredients =>
      ingredientMatches.where((item) => !item.hasEnough).toList();
}

class RecipeMatchingService {
  const RecipeMatchingService();

  // Basic ingredient-name normalization.
  String _normalizeName(String name) {
    final normalized = name.toLowerCase().trim().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );

    // Handle simple singular/plural differences.
    const aliases = {
      'egg': 'eggs',
      'carrot': 'carrots',
      'tomato': 'tomatoes',
      'potato': 'potatoes',
      'onion': 'onions',
    };

    return aliases[normalized] ?? normalized;
  }

  // Convert compatible units to a common base unit.
  String _unitGroup(String unit) {
    switch (unit.toLowerCase().trim()) {
      case 'kg':
      case 'g':
        return 'weight';

      case 'l':
      case 'ml':
        return 'volume';

      case 'pcs':
        return 'pieces';

      default:
        return unit.toLowerCase().trim();
    }
  }

  double _toBaseQuantity(double quantity, String unit) {
    switch (unit.toLowerCase().trim()) {
      case 'kg':
      case 'l':
        return quantity * 1000;

      default:
        return quantity;
    }
  }

  RecipeIngredientMatch _matchIngredient(
    RecipeIngredient required,
    List<PantryItemModel> pantryItems,
  ) {
    final requiredName = _normalizeName(required.name);
    final requiredUnitGroup = _unitGroup(required.unit);

    final requiredQuantity = _toBaseQuantity(required.quantity, required.unit);

    double availableQuantity = 0;
    bool foundIngredient = false;
    bool foundCompatibleUnit = false;

    for (final item in pantryItems) {
      // Do not recommend using expired ingredients.
      if (item.isExpired) continue;

      if (_normalizeName(item.name) != requiredName) {
        continue;
      }

      foundIngredient = true;

      if (_unitGroup(item.unit) != requiredUnitGroup) {
        continue;
      }

      foundCompatibleUnit = true;

      availableQuantity += _toBaseQuantity(item.quantity, item.unit);
    }

    final hasEnough =
        foundCompatibleUnit && availableQuantity >= requiredQuantity;

    // Convert the available amount to the recipe's unit.
    final conversionFactor = _toBaseQuantity(1, required.unit);

    return RecipeIngredientMatch(
      ingredient: required,
      availableQuantity: availableQuantity / conversionFactor,
      isAvailable: foundIngredient,
      hasEnough: hasEnough,
      hasCompatibleUnit: foundCompatibleUnit,
    );
  }

  RecipeMatchResult matchRecipe({
    required RecipeModel recipe,
    required List<PantryItemModel> pantryItems,
  }) {
    final matches = recipe.ingredients.map((ingredient) {
      return _matchIngredient(ingredient, pantryItems);
    }).toList();

    return RecipeMatchResult(recipe: recipe, ingredientMatches: matches);
  }

  List<RecipeMatchResult> matchRecipes({
    required List<RecipeModel> recipes,
    required List<PantryItemModel> pantryItems,
  }) {
    final results = recipes.map((recipe) {
      return matchRecipe(recipe: recipe, pantryItems: pantryItems);
    }).toList();

    // Show recipes with the most matching ingredients first.
    results.sort((a, b) {
      if (a.isReadyToCook != b.isReadyToCook) {
        return a.isReadyToCook ? -1 : 1;
      }

      final percentageComparison = b.matchPercentage.compareTo(
        a.matchPercentage,
      );

      if (percentageComparison != 0) {
        return percentageComparison;
      }

      return a.recipe.totalMinutes.compareTo(b.recipe.totalMinutes);
    });

    return results;
  }
}
