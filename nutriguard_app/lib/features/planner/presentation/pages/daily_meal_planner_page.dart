import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../meals/data/services/meal_category_service.dart';
import '../../../pantry/data/catalog/recipe_catalog.dart';
import '../../../pantry/data/models/recipe_model.dart';
import '../../data/models/planned_meal_model.dart';
import '../../data/repositories/meal_plan_repository.dart';
import '../../data/services/meal_plan_nutrition_service.dart';

import 'weekly_meal_planner_page.dart';

class DailyMealPlannerPage extends StatefulWidget {
  final DateTime? initialDate;
  final String? initialMealType;
  final String? initialRecipeId;

  const DailyMealPlannerPage({
    super.key,
    this.initialDate,
    this.initialMealType,
    this.initialRecipeId,
  });

  @override
  State<DailyMealPlannerPage> createState() => _DailyMealPlannerPageState();
}

class _DailyMealPlannerPageState extends State<DailyMealPlannerPage> {
  final MealPlanRepository _repository = MealPlanRepository();

  final MealPlanNutritionService _nutritionService =
      const MealPlanNutritionService();

  final MealCategoryService _categoryService = const MealCategoryService();

  late DateTime _selectedDate;

  String? _loadedUserId;
  Stream<List<PlannedMealModel>>? _mealsStream;

  bool _isSaving = false;

  String get _dateId => PlannedMealModel.formatDate(_selectedDate);

  @override
  void initState() {
    super.initState();

    final date = widget.initialDate ?? DateTime.now();

    _selectedDate = DateTime(date.year, date.month, date.day);

    _loadMeals();

    // Open the Add Meal dialog automatically when the user
    // navigates from a recipe recommendation.
    if (widget.initialRecipeId != null && widget.initialMealType != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        _showMealDialog();
      });
    }
  }

  void _loadMeals() {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    _loadedUserId = userId;

    if (userId == null) {
      _mealsStream = null;
      return;
    }

    _mealsStream = _repository.watchMealsForDate(userId: userId, date: _dateId);
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day + days,
      );

      _loadMeals();
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _selectedDate = picked;
      _loadMeals();
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  List<RecipeModel> _recipesForType(String mealType) {
    return _categoryService.filterRecipes(
      recipes: RecipeCatalog.getAllRecipes(),
      mealType: mealType,
    );
  }

  Future<void> _showMealDialog({PlannedMealModel? existingMeal}) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      _showMessage('Please log in first.');
      return;
    }

    String selectedType =
        existingMeal?.mealType ?? widget.initialMealType ?? 'Breakfast';

    String? selectedRecipeId = existingMeal?.recipeId ?? widget.initialRecipeId;

    int selectedServings = existingMeal?.servings ?? 1;

    final initialRecipes = _recipesForType(selectedType);

    if (!initialRecipes.any((recipe) => recipe.id == selectedRecipeId)) {
      selectedRecipeId = initialRecipes.isEmpty
          ? null
          : initialRecipes.first.id;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final recipes = _recipesForType(selectedType);

            return AlertDialog(
              title: Text(
                existingMeal == null ? 'Add Planned Meal' : 'Edit Planned Meal',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Date: ${existingMeal?.date ?? _dateId}'),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Meal Type',
                        border: OutlineInputBorder(),
                      ),
                      items: PlannedMealModel.validMealTypes
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                      onChanged: (type) {
                        if (type == null) return;

                        setDialogState(() {
                          selectedType = type;

                          final available = _recipesForType(type);

                          selectedRecipeId = available.isEmpty
                              ? null
                              : available.first.id;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      key: ValueKey(selectedType),
                      initialValue: selectedRecipeId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Recipe',
                        border: OutlineInputBorder(),
                      ),
                      items: recipes
                          .map(
                            (recipe) => DropdownMenuItem(
                              value: recipe.id,
                              child: Text(
                                recipe.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (recipeId) {
                        setDialogState(() {
                          selectedRecipeId = recipeId;
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Planned Servings',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Decrease servings',
                          onPressed: selectedServings > 1
                              ? () {
                                  setDialogState(() {
                                    selectedServings--;
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              '$selectedServings',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Increase servings',
                          onPressed: selectedServings < 20
                              ? () {
                                  setDialogState(() {
                                    selectedServings++;
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Nutrition values are estimates '
                      'per serving.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedRecipeId == null
                      ? null
                      : () {
                          Navigator.pop(dialogContext, true);
                        },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || selectedRecipeId == null) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _isSaving = true;
    });

    try {
      if (existingMeal == null) {
        await _repository.createMeal(
          userId: userId,
          date: _dateId,
          mealType: selectedType,
          recipeId: selectedRecipeId!,
          servings: selectedServings,
        );
      } else {
        final updated = existingMeal.copyWith(
          mealType: selectedType,
          recipeId: selectedRecipeId,
          servings: selectedServings,
        );

        await _repository.updateMeal(userId: userId, meal: updated);
      }

      _showMessage('Meal saved successfully.');
    } catch (error) {
      _showMessage('Failed to save meal: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteMeal(PlannedMealModel meal) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Meal?'),
          content: const Text('This planned meal will be removed.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _repository.deleteMeal(userId: userId, mealId: meal.id);

      _showMessage('Meal deleted.');
    } catch (error) {
      _showMessage('Failed to delete meal: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _nutritionCard(List<PlannedMealModel> meals) {
    final totals = _nutritionService.calculateDailyTotal(
      date: _dateId,
      plannedMeals: meals,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F7EF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estimated Daily Nutrition',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 18,
            runSpacing: 14,
            children: [
              _nutritionValue('Calories', '${totals.calories.round()} kcal'),
              _nutritionValue('Protein', '${totals.protein.round()} g'),
              _nutritionValue('Carbs', '${totals.carbs.round()} g'),
              _nutritionValue('Fat', '${totals.fat.round()} g'),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'These are planned intake estimates, '
            'not food consumption records.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _nutritionValue(String label, String value) {
    return SizedBox(
      width: 125,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mealSection(String mealType, List<PlannedMealModel> meals) {
    final sectionMeals = meals
        .where((meal) => meal.mealType == mealType)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          mealType,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 10),
        if (sectionMeals.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No meal planned yet.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          for (final meal in sectionMeals) _mealTile(meal),
      ],
    );
  }

  Widget _mealTile(PlannedMealModel meal) {
    final recipe = RecipeCatalog.getRecipeById(meal.recipeId);

    final nutrition = recipe == null
        ? null
        : _nutritionService.calculateMeal(meal);

    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.restaurant_menu, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe?.name ?? 'Unknown Recipe',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${meal.servings} serving(s)'
                    '${nutrition == null ? '' : ' · ${nutrition.calories.round()} kcal'}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Edit meal',
              onPressed: _isSaving
                  ? null
                  : () => _showMealDialog(existingMeal: meal),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Delete meal',
              onPressed: _isSaving ? null : () => _deleteMeal(meal),
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != _loadedUserId) {
      _loadMeals();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFC),

      appBar: AppBar(
        title: const Text('Meal Planner'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF5FAFC),
        actions: [
          IconButton(
            tooltip: 'Weekly Planner',
            icon: const Icon(Icons.calendar_view_week),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const WeeklyMealPlannerPage(),
                ),
              );
            },
          ),
        ],
      ),

      floatingActionButton: userId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _isSaving ? null : () => _showMealDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Meal'),
            ),
      body: userId == null
          ? const Center(
              child: Text('Please log in to manage your meal plans.'),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Previous day',
                        onPressed: () => _changeDate(-1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_month),
                          label: Text(_dateId),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Next day',
                        onPressed: () => _changeDate(1),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<PlannedMealModel>>(
                    stream: _mealsStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text(
                            'Unable to load meal plans. '
                            'Check your connection.',
                          ),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final meals = snapshot.data!;

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 95),
                        children: [
                          _nutritionCard(meals),
                          for (final type in PlannedMealModel.validMealTypes)
                            _mealSection(type, meals),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
