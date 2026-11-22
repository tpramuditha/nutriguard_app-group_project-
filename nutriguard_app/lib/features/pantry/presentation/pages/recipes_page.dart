import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../nutrition/data/models/nutrition_goal_model.dart';
import '../../data/catalog/recipe_catalog.dart';
import '../../data/models/pantry_item_model.dart';
import '../../data/repositories/pantry_repository.dart';
import '../../data/services/recipe_goal_ranking_service.dart';
import '../../data/services/recipe_matching_service.dart';
import '../../data/services/recipe_nutrition_goal_loader.dart';
import 'recipe_details_page.dart';
import '../widgets/recipe_health_context_card.dart';

class RecipesPage extends StatefulWidget {
  const RecipesPage({super.key});

  @override
  State<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  static const Color primary = Color(0xFF0D9488);
  static const Color darkGreen = Color(0xFF086F67);
  static const Color background = Color(0xFFF7FAFA);

  final PantryRepository _pantryRepository = PantryRepository();

  final RecipeNutritionGoalLoader _goalLoader = RecipeNutritionGoalLoader();

  final RecipeMatchingService _matchingService = const RecipeMatchingService();

  final RecipeGoalRankingService _rankingService =
      const RecipeGoalRankingService();

  String _selectedFilter = 'All Recipes';

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

  void _retryGoalLoading() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() {
      _loadedUserId = userId;
      _goalFuture = _goalLoader.loadGoal(userId: userId);
    });
  }

  List<PersonalizedRecipeResult> _filterRecipes(
    List<PersonalizedRecipeResult> results,
  ) {
    switch (_selectedFilter) {
      case 'Ready to Cook':
        return results.where((r) => r.isReadyToCook).toList();

      case 'Missing a Few':
        return results.where((r) => r.matchResult.isMissingAFew).toList();

      default:
        return results;
    }
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

  Widget _buildHeader(List<PersonalizedRecipeResult> results) {
    final readyCount = results.where((r) => r.isReadyToCook).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D9488), Color(0xFF40BFA3)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Cook with what you have!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Explore ${results.length} recipes '
            'using ingredients from your pantry.',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 7),
                Text(
                  '$readyCount ready to cook',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionGoalCard(NutritionGoalModel goal) {
    final mealGuide = _rankingService.estimatedMealCalorieGuide(goal);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFDCEAE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.track_changes, color: primary),
              SizedBox(width: 8),
              Text(
                'Your Nutrition Goal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: darkGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _goalValue(
                  'Daily Target',
                  '${goal.dailyCalorieTarget} kcal',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _goalValue('Meal Guide', '${mealGuide.round()} kcal'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Goal: ${goal.goalType}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: darkGreen,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'The meal guide is an illustrative one-third '
            'of your daily target, not a prescribed '
            'meal allocation.',
            style: TextStyle(
              fontSize: 11,
              height: 1.4,
              color: Color(0xFF72878A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _goalValue(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF8F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF69868B), fontSize: 11),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: darkGreen,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(List<PersonalizedRecipeResult> results) {
    final readyCount = results.where((r) => r.isReadyToCook).length;

    final missingCount = results
        .where((r) => r.matchResult.isMissingAFew)
        .length;

    final filters = <String, int>{
      'All Recipes': results.length,
      'Ready to Cook': readyCount,
      'Missing a Few': missingCount,
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.entries.map((entry) {
          final selected = _selectedFilter == entry.key;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('${entry.key} (${entry.value})'),
              selected: selected,
              showCheckmark: false,
              selectedColor: primary,
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFD8E8E6)),
              labelStyle: TextStyle(
                color: selected ? Colors.white : darkGreen,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
              onSelected: (_) {
                setState(() {
                  _selectedFilter = entry.key;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusBadge(RecipeMatchResult result) {
    final ready = result.isReadyToCook;

    final label = ready
        ? 'Ready to Cook'
        : result.isMissingAFew
        ? 'Missing a Few'
        : 'Need More Ingredients';

    final textColor = ready ? const Color(0xFF18865A) : const Color(0xFFD98319);

    final fillColor = ready ? const Color(0xFFE3F6E9) : const Color(0xFFFFF0DD);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ready ? Icons.check_circle_outline : Icons.info_outline,
            color: textColor,
            size: 14,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(PersonalizedRecipeResult personalized) {
    final match = personalized.matchResult;
    final recipe = match.recipe;

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 86,
                width: 86,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFDDF6E9), Color(0xFFFFEBCD)],
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(_recipeIcon(recipe.id), color: primary, size: 39),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF183F43),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${recipe.totalMinutes} min  •  '
                      '${recipe.servings} '
                      '${recipe.servings == 1 ? 'serving' : 'servings'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF71858A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildStatusBadge(match),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            recipe.description,
            style: const TextStyle(fontSize: 12, color: Color(0xFF617B80)),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${match.matchedIngredients}/'
                '${match.totalIngredients} ingredients',
                style: const TextStyle(
                  color: darkGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${match.matchPercentage.round()}% match',
                style: const TextStyle(
                  color: darkGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: match.matchPercentage / 100,
              minHeight: 7,
              backgroundColor: const Color(0xFFE4EFED),
              valueColor: AlwaysStoppedAnimation<Color>(
                match.isReadyToCook ? primary : const Color(0xFFE6A34B),
              ),
            ),
          ),
          if (!match.isReadyToCook) ...[
            const SizedBox(height: 9),
            Text(
              '${match.unavailableIngredients.length} '
              'ingredient(s) missing or insufficient',
              style: const TextStyle(fontSize: 11, color: Color(0xFFB47625)),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.local_fire_department_outlined,
                size: 17,
                color: primary,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  '${recipe.calories.round()} kcal estimate',
                  style: const TextStyle(
                    fontSize: 12,
                    color: darkGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            personalized.calorieInsight,
            style: const TextStyle(fontSize: 11, color: Color(0xFF71858A)),
          ),
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => RecipeDetailsPage(result: match),
                  ),
                );
              },
              icon: const Icon(Icons.menu_book_outlined, size: 18),
              label: const Text('View Recipe'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primary,
                side: const BorderSide(color: primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 12),
      child: Column(
        children: [
          const Icon(Icons.no_food_outlined, size: 55, color: primary),
          const SizedBox(height: 12),
          const Text(
            'No recipes found',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try another filter or add more '
            'ingredients to your pantry.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedFilter = 'All Recipes';
              });
            },
            child: const Text('Show All Recipes'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    List<PantryItemModel> pantryItems,
    NutritionGoalModel nutritionGoal,
  ) {
    final matches = _matchingService.matchRecipes(
      recipes: RecipeCatalog.getAllRecipes(),
      pantryItems: pantryItems,
    );

    final rankedResults = _rankingService.rankRecipes(
      recipeMatches: matches,
      nutritionGoal: nutritionGoal,
    );

    final filteredResults = _filterRecipes(rankedResults);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _buildHeader(rankedResults),
        const SizedBox(height: 14),
        _buildNutritionGoalCard(nutritionGoal),
        const SizedBox(height: 14),
        const RecipeHealthContextCard(),
        const SizedBox(height: 18),
        _buildFilters(rankedResults),
        const SizedBox(height: 16),
        Text(
          _selectedFilter,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: darkGreen,
          ),
        ),
        const SizedBox(height: 11),
        if (filteredResults.isEmpty)
          _buildEmptyState()
        else
          for (final result in filteredResults) _buildRecipeCard(result),
        const SizedBox(height: 10),
        const Text(
          'Recipe calories are illustrative estimates. '
          'The calorie guide is not a medical recommendation. '
          'Recipe availability depends on pantry stock.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF7B9094), fontSize: 11),
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
            const Icon(Icons.error_outline, color: Colors.orange, size: 42),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (retry != null) ...[
              const SizedBox(height: 14),
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
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: darkGreen,
        centerTitle: true,
        title: const Text(
          'Recipes You Can Make',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (user != null)
            IconButton(
              tooltip: 'Refresh nutrition goal',
              onPressed: _retryGoalLoading,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: user == null
          ? const Center(
              child: Text('Please log in to view recipe suggestions.'),
            )
          : FutureBuilder<NutritionGoalModel>(
              future: _goalFuture,
              builder: (context, goalSnapshot) {
                if (goalSnapshot.hasError) {
                  return _buildError(
                    'Unable to load your nutrition goal. '
                    'Please check your connection.',
                    retry: _retryGoalLoading,
                  );
                }

                if (!goalSnapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: primary),
                  );
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
                      return const Center(
                        child: CircularProgressIndicator(color: primary),
                      );
                    }

                    return _buildContent(
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
