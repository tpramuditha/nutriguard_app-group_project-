import '../../../nutrition/data/models/nutrition_goal_model.dart';
import '../../../pantry/data/catalog/recipe_catalog.dart';
import '../../../pantry/data/models/pantry_item_model.dart';
import '../../../pantry/data/services/recipe_goal_ranking_service.dart';
import '../../../pantry/data/services/recipe_matching_service.dart';

import 'meal_category_service.dart';

class MealRecommendationService {
  final MealCategoryService _categoryService;
  final RecipeMatchingService _matchingService;
  final RecipeGoalRankingService _rankingService;

  const MealRecommendationService({
    this._categoryService = const MealCategoryService(),
    this._matchingService = const RecipeMatchingService(),
    this._rankingService = const RecipeGoalRankingService(),
  });

  List<PersonalizedRecipeResult> getRecommendations({
    required String mealType,
    required List<PantryItemModel> pantryItems,
    required NutritionGoalModel nutritionGoal,
  }) {
    // Step 1: Select recipes for the requested meal type.
    //
    // Invalid meal types are rejected by the category service.
    final categoryRecipes = _categoryService.filterRecipes(
      recipes: RecipeCatalog.getAllRecipes(),
      mealType: mealType,
    );

    // Step 2: Match the selected recipes against pantry stock.
    //
    // The existing matching service handles ingredient names,
    // quantity, compatible units, and expired pantry items.
    final matches = _matchingService.matchRecipes(
      recipes: categoryRecipes,
      pantryItems: pantryItems,
    );

    // Step 3: Rank using pantry availability and
    // estimated calorie-guide proximity.
    return _rankingService.rankRecipes(
      recipeMatches: matches,
      nutritionGoal: nutritionGoal,
    );
  }

  PersonalizedRecipeResult? getTopRecommendation({
    required String mealType,
    required List<PantryItemModel> pantryItems,
    required NutritionGoalModel nutritionGoal,
  }) {
    final recommendations = getRecommendations(
      mealType: mealType,
      pantryItems: pantryItems,
      nutritionGoal: nutritionGoal,
    );

    if (recommendations.isEmpty) {
      return null;
    }

    return recommendations.first;
  }

  int getReadyToCookCount({
    required String mealType,
    required List<PantryItemModel> pantryItems,
    required NutritionGoalModel nutritionGoal,
  }) {
    final recommendations = getRecommendations(
      mealType: mealType,
      pantryItems: pantryItems,
      nutritionGoal: nutritionGoal,
    );

    return recommendations.where((result) => result.isReadyToCook).length;
  }
}
