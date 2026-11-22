import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../nutrition/data/models/nutrition_goal_model.dart';
import '../../../pantry/data/models/pantry_item_model.dart';
import '../../../pantry/data/repositories/pantry_repository.dart';
import '../../../pantry/data/services/recipe_goal_ranking_service.dart';
import '../../../pantry/data/services/recipe_nutrition_goal_loader.dart';
import '../../../pantry/presentation/pages/recipe_details_page.dart';
import '../../../planner/presentation/pages/daily_meal_planner_page.dart';
import '../../data/services/meal_recommendation_service.dart';
import '../widgets/meal_type_selector.dart';

class MealRecommendationPage extends StatefulWidget {
  const MealRecommendationPage({super.key});

  @override
  State<MealRecommendationPage> createState() => _MealRecommendationPageState();
}

class _MealRecommendationPageState extends State<MealRecommendationPage> {
  final PantryRepository _pantryRepository = PantryRepository();

  final RecipeNutritionGoalLoader _goalLoader = RecipeNutritionGoalLoader();

  final MealRecommendationService _recommendationService =
      const MealRecommendationService();

  String _selectedMeal = 'Lunch';

  String? _loadedUserId;
  Future<NutritionGoalModel>? _goalFuture;
  Stream<List<PantryItemModel>>? _pantryStream;

  @override
  void initState() {
    super.initState();
    _initializeForCurrentUser();
  }

  void _initializeForCurrentUser() {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == _loadedUserId) return;

    _loadedUserId = userId;

    if (userId == null) {
      _goalFuture = null;
      _pantryStream = null;
      return;
    }

    _goalFuture = _goalLoader.loadGoal(userId: userId);

    _pantryStream = _pantryRepository.watchPantryItems(userId: userId);
  }

  void _refreshGoal() {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) return;

    setState(() {
      _loadedUserId = userId;
      _goalFuture = _goalLoader.loadGoal(userId: userId);
    });
  }

  IconData _recipeIcon(String recipeId) {
    switch (recipeId) {
      case 'egg_fried_rice':
        return Icons.rice_bowl;
      case 'vegetable_omelette':
        return Icons.egg_alt;
      case 'rice_and_dhal':
        return Icons.soup_kitchen;
      case 'vegetable_stir_fry':
        return Icons.eco;
      case 'boiled_eggs':
        return Icons.egg;
      default:
        return Icons.restaurant;
    }
  }

  Widget _buildGoalCard(NutritionGoalModel goal) {
    final mealGuide = goal.dailyCalorieTarget / 3;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCEAE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.track_changes, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Your Nutrition Goal',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${goal.goalType} · '
            '${goal.dailyCalorieTarget} kcal/day',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Illustrative meal calorie guide: '
            '${mealGuide.round()} kcal',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Color(0xFF4B83B6)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Suggestions are based on pantry ingredients '
              'and estimated calories. They are not '
              'medical recommendations or health-safety '
              'assessments.',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: Color(0xFF4B83B6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(
    PersonalizedRecipeResult recommendation, {
    required bool isFeatured,
  }) {
    final recipe = recommendation.recipe;
    final match = recommendation.matchResult;

    final ready = recommendation.isReadyToCook;

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isFeatured ? AppColors.primary : const Color(0xFFE3ECEC),
          width: isFeatured ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isFeatured) ...[
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
                SizedBox(width: 7),
                Text(
                  'Top Match',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 76,
                width: 76,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  _recipeIcon(recipe.id),
                  size: 37,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${recipe.totalMinutes} min · '
                      '${recipe.caloriesPerServing.round()} '
                      'kcal/serving',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ready ? 'Ready to Cook' : 'Ingredients needed',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: ready
                            ? const Color(0xFF18865A)
                            : const Color(0xFFB47625),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            recipe.description,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${match.matchedIngredients}/'
                '${match.totalIngredients} ingredients',
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                '${match.matchPercentage.round()}% match',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          LinearProgressIndicator(
            value: match.matchPercentage / 100,
            minHeight: 7,
            borderRadius: BorderRadius.circular(10),
            backgroundColor: const Color(0xFFE4EFED),
            color: ready ? AppColors.primary : const Color(0xFFE6A34B),
          ),

          if (!ready) ...[
            const SizedBox(height: 8),
            Text(
              '${match.unavailableIngredients.length} '
              'ingredient(s) missing or insufficient',
              style: const TextStyle(fontSize: 12, color: Color(0xFFB47625)),
            ),
          ],

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FAF9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Why this recommendation?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Pantry match: '
                  '${match.matchPercentage.round()}%. '
                  '${recommendation.calorieInsight}.',
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => RecipeDetailsPage(result: match),
                  ),
                );
              },
              icon: const Icon(Icons.menu_book_outlined, size: 18),
              label: const Text('View Recipe'),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => DailyMealPlannerPage(
                      initialMealType: _selectedMeal,
                      initialRecipeId: recipe.id,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.calendar_month_outlined, size: 18),
              label: const Text('Add to Planner'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(
    List<PantryItemModel> pantryItems,
    NutritionGoalModel goal,
  ) {
    final recommendations = _recommendationService.getRecommendations(
      mealType: _selectedMeal,
      pantryItems: pantryItems,
      nutritionGoal: goal,
    );

    final readyCount = recommendations
        .where((item) => item.isReadyToCook)
        .length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        MealTypeSelector(
          selectedMeal: _selectedMeal,
          onMealSelected: (meal) {
            setState(() {
              _selectedMeal = meal;
            });
          },
        ),

        const SizedBox(height: 18),

        _buildGoalCard(goal),

        const SizedBox(height: 14),

        _buildInfoBanner(),

        const SizedBox(height: 22),

        Text(
          '$_selectedMeal Recommendations',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          '${recommendations.length} recipes · '
          '$readyCount ready to cook',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),

        const SizedBox(height: 16),

        if (recommendations.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 36),
            child: Center(
              child: Text(
                'No recommendations available '
                'for this meal type.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          for (var index = 0; index < recommendations.length; index++)
            _buildRecipeCard(recommendations[index], isFeatured: index == 0),

        const SizedBox(height: 15),

        const Text(
          'Nutrition values are illustrative estimates. '
          'Check ingredient availability and follow '
          'appropriate dietary advice for your needs.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildError(String message, {VoidCallback? retry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 42, color: Colors.orange),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (retry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: retry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user?.uid != _loadedUserId) {
      _initializeForCurrentUser();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        centerTitle: true,
        title: const Text(
          'Meal Recommendations',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
        actions: [
          if (user != null)
            IconButton(
              tooltip: 'Refresh nutrition goal',
              onPressed: _refreshGoal,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: user == null
          ? const Center(
              child: Text('Please log in to view meal recommendations.'),
            )
          : FutureBuilder<NutritionGoalModel>(
              future: _goalFuture,
              builder: (context, goalSnapshot) {
                if (goalSnapshot.hasError) {
                  return _buildError(
                    'Unable to load your nutrition goal.',
                    retry: _refreshGoal,
                  );
                }

                if (!goalSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return StreamBuilder<List<PantryItemModel>>(
                  stream: _pantryStream,
                  builder: (context, pantrySnapshot) {
                    if (pantrySnapshot.hasError) {
                      return _buildError(
                        'Unable to load pantry ingredients. '
                        'Please check your connection.',
                      );
                    }

                    if (!pantrySnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return _buildRecommendations(
                      pantrySnapshot.data!,
                      goalSnapshot.data!,
                    );
                  },
                );
              },
            ),
    );
  }
}
