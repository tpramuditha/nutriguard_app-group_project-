import '../../../pantry/data/models/recipe_model.dart';

class MealCategoryService {
  const MealCategoryService();

  static const List<String> mealTypes = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
  ];

  // Initial editorial meal classifications.
  //
  // These categories describe when a recipe could be eaten.
  // They do not imply medical or nutritional suitability.
  //
  // Each recipe may belong to more than one meal type.
  static const Map<String, List<String>> _recipeMealTypes = {
    'egg_fried_rice': ['Lunch', 'Dinner'],
    'vegetable_omelette': ['Breakfast', 'Lunch'],
    'rice_and_dhal': ['Lunch', 'Dinner'],
    'vegetable_stir_fry': ['Lunch', 'Dinner'],
    'boiled_eggs': ['Breakfast', 'Snack'],
  };

  bool isValidMealType(String mealType) {
    return mealTypes.contains(mealType);
  }

  List<String> getMealTypesForRecipe(String recipeId) {
    return List<String>.unmodifiable(_recipeMealTypes[recipeId] ?? const []);
  }

  bool isRecipeSuitableForMealType({
    required RecipeModel recipe,
    required String mealType,
  }) {
    if (!isValidMealType(mealType)) {
      return false;
    }

    return getMealTypesForRecipe(recipe.id).contains(mealType);
  }

  List<RecipeModel> filterRecipes({
    required List<RecipeModel> recipes,
    required String mealType,
  }) {
    if (!isValidMealType(mealType)) {
      throw ArgumentError('Invalid meal type: $mealType');
    }

    return recipes.where((recipe) {
      return isRecipeSuitableForMealType(recipe: recipe, mealType: mealType);
    }).toList();
  }

  int countRecipes({
    required List<RecipeModel> recipes,
    required String mealType,
  }) {
    return filterRecipes(recipes: recipes, mealType: mealType).length;
  }
}
