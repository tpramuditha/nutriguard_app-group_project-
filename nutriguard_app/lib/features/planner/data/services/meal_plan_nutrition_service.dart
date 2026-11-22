import '../../../pantry/data/catalog/recipe_catalog.dart';
import '../../../pantry/data/models/recipe_model.dart';
import '../models/planned_meal_model.dart';

class MealPlanNutritionTotals {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  const MealPlanNutritionTotals({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  static const zero = MealPlanNutritionTotals(
    calories: 0,
    protein: 0,
    carbs: 0,
    fat: 0,
  );

  MealPlanNutritionTotals operator +(MealPlanNutritionTotals other) {
    return MealPlanNutritionTotals(
      calories: calories + other.calories,
      protein: protein + other.protein,
      carbs: carbs + other.carbs,
      fat: fat + other.fat,
    );
  }
}

class MealPlanNutritionService {
  const MealPlanNutritionService();

  RecipeModel getRecipe(String recipeId) {
    final recipe = RecipeCatalog.getRecipeById(recipeId);

    if (recipe == null) {
      throw StateError('Recipe not found in catalog: $recipeId');
    }

    return recipe;
  }

  MealPlanNutritionTotals calculateMeal(PlannedMealModel plannedMeal) {
    plannedMeal.validate();

    final recipe = getRecipe(plannedMeal.recipeId);
    final servings = plannedMeal.servings;

    return MealPlanNutritionTotals(
      calories: (recipe.caloriesPerServing * servings).toDouble(),
      protein: (recipe.proteinPerServing * servings).toDouble(),
      carbs: (recipe.carbsPerServing * servings).toDouble(),
      fat: (recipe.fatPerServing * servings).toDouble(),
    );
  }

  MealPlanNutritionTotals calculateTotal(List<PlannedMealModel> plannedMeals) {
    var total = MealPlanNutritionTotals.zero;

    for (final meal in plannedMeals) {
      total = total + calculateMeal(meal);
    }

    return total;
  }

  MealPlanNutritionTotals calculateDailyTotal({
    required String date,
    required List<PlannedMealModel> plannedMeals,
  }) {
    final mealsForDate = plannedMeals
        .where((meal) => meal.date == date)
        .toList();

    return calculateTotal(mealsForDate);
  }

  Map<String, MealPlanNutritionTotals> calculateByMealType({
    required String date,
    required List<PlannedMealModel> plannedMeals,
  }) {
    final totals = <String, MealPlanNutritionTotals>{
      for (final type in PlannedMealModel.validMealTypes)
        type: MealPlanNutritionTotals.zero,
    };

    for (final meal in plannedMeals) {
      if (meal.date != date) continue;

      final nutrition = calculateMeal(meal);

      totals[meal.mealType] = totals[meal.mealType]! + nutrition;
    }

    return totals;
  }
}
