import '../../../nutrition/data/models/nutrition_goal_model.dart';
import '../models/recipe_model.dart';
import 'recipe_matching_service.dart';

class PersonalizedRecipeResult {
  final RecipeMatchResult matchResult;
  final double estimatedMealCalorieGuide;
  final double calorieDifference;

  const PersonalizedRecipeResult({
    required this.matchResult,
    required this.estimatedMealCalorieGuide,
    required this.calorieDifference,
  });

  RecipeModel get recipe => matchResult.recipe;

  bool get isReadyToCook => matchResult.isReadyToCook;

  double get matchPercentage => matchResult.matchPercentage;

  // This is an informational comparison, not a medical
  // suitability or safety assessment.
  String get calorieInsight {
    if (calorieDifference <= 100) {
      return 'Close to your estimated meal calorie guide';
    }

    if (recipe.calories < estimatedMealCalorieGuide) {
      return 'Below your estimated meal calorie guide';
    }

    return 'Above your estimated meal calorie guide';
  }
}

class RecipeGoalRankingService {
  const RecipeGoalRankingService();

  // Simple starting assumption: one main meal represents
  // approximately one third of the daily calorie target.
  //
  // This is NOT a prescribed meal plan. Actual needs and
  // meal distribution vary between people.
  static const double mealCalorieFraction = 1 / 3;

  double estimatedMealCalorieGuide(NutritionGoalModel goal) {
    return goal.dailyCalorieTarget * mealCalorieFraction;
  }

  PersonalizedRecipeResult evaluateRecipe({
    required RecipeMatchResult matchResult,
    required NutritionGoalModel nutritionGoal,
  }) {
    final mealGuide = estimatedMealCalorieGuide(nutritionGoal);

    final difference = (matchResult.recipe.calories - mealGuide).abs();

    return PersonalizedRecipeResult(
      matchResult: matchResult,
      estimatedMealCalorieGuide: mealGuide,
      calorieDifference: difference,
    );
  }

  List<PersonalizedRecipeResult> rankRecipes({
    required List<RecipeMatchResult> recipeMatches,
    required NutritionGoalModel nutritionGoal,
  }) {
    final results = recipeMatches.map((match) {
      return evaluateRecipe(matchResult: match, nutritionGoal: nutritionGoal);
    }).toList();

    results.sort((a, b) {
      // Priority 1: Recipes that are ready to cook.
      if (a.isReadyToCook != b.isReadyToCook) {
        return a.isReadyToCook ? -1 : 1;
      }

      // Priority 2: More available ingredients.
      final matchComparison = b.matchPercentage.compareTo(a.matchPercentage);

      if (matchComparison != 0) {
        return matchComparison;
      }

      // Priority 3: Closer to the meal calorie guide.
      final calorieComparison = a.calorieDifference.compareTo(
        b.calorieDifference,
      );

      if (calorieComparison != 0) {
        return calorieComparison;
      }

      // Priority 4: Faster preparation.
      final timeComparison = a.recipe.totalMinutes.compareTo(
        b.recipe.totalMinutes,
      );

      if (timeComparison != 0) {
        return timeComparison;
      }

      // Final deterministic ordering.
      return a.recipe.id.compareTo(b.recipe.id);
    });

    return results;
  }
}
