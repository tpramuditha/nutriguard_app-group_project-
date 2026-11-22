class RecipeIngredient {
  final String name;
  final double quantity;
  final String unit;

  const RecipeIngredient({
    required this.name,
    required this.quantity,
    required this.unit,
  });
}

class RecipeModel {
  final String id;
  final String name;
  final String description;

  final int preparationMinutes;
  final int cookingMinutes;
  final int servings;

  // Estimated nutritional values PER SERVING.
  //
  // These are illustrative catalog values, not
  // independently validated nutritional measurements.
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  // Ingredient quantities are for the FULL recipe,
  // not for an individual serving.
  final List<RecipeIngredient> ingredients;

  final List<String> instructions;
  final String? imageUrl;

  const RecipeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.preparationMinutes,
    required this.cookingMinutes,
    required this.servings,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.ingredients,
    required this.instructions,
    this.imageUrl,
  });

  int get totalMinutes {
    return preparationMinutes + cookingMinutes;
  }

  // Explicit per-serving nutrition getters.
  double get caloriesPerServing => calories;

  double get proteinPerServing => protein;

  double get carbsPerServing => carbs;

  double get fatPerServing => fat;

  // Estimated nutrition for the entire prepared recipe.
  double get totalRecipeCalories => calories * servings;

  double get totalRecipeProtein => protein * servings;

  double get totalRecipeCarbs => carbs * servings;

  double get totalRecipeFat => fat * servings;

  // Ingredient quantities are defined for the full recipe.
  // Divide by servings to obtain the approximate quantity
  // needed for one serving.
  double ingredientQuantityPerServing(RecipeIngredient ingredient) {
    if (servings <= 0) {
      throw StateError('Recipe servings must be greater than zero.');
    }

    return ingredient.quantity / servings;
  }
}
