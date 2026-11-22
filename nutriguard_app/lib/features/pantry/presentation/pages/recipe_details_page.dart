import 'package:flutter/material.dart';

import '../../data/services/recipe_matching_service.dart';

class RecipeDetailsPage extends StatelessWidget {
  const RecipeDetailsPage({super.key, required this.result});

  final RecipeMatchResult result;

  static const Color primary = Color(0xFF0D9488);
  static const Color darkGreen = Color(0xFF086F67);
  static const Color background = Color(0xFFF7FAFA);

  String _formatQuantity(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: darkGreen,
        centerTitle: true,
        title: const Text(
          'Recipe Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _buildRecipeHeader(),
          const SizedBox(height: 18),
          _buildNutritionSection(),
          const SizedBox(height: 20),
          _buildIngredientsSection(),
          const SizedBox(height: 20),
          _buildInstructionsSection(),
          const SizedBox(height: 20),
          Text(
            'Nutrition information is an illustrative estimate. '
            'Ingredient availability reflects your pantry '
            'when you opened this recipe.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeHeader() {
    final recipe = result.recipe;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D9488), Color(0xFF45BDA6)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.restaurant_menu, color: Colors.white, size: 36),
          const SizedBox(height: 12),
          Text(
            recipe.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            recipe.description,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _headerInfo(Icons.schedule, '${recipe.totalMinutes} min'),
              _headerInfo(Icons.people_outline, '${recipe.servings} servings'),
              _headerInfo(
                Icons.check_circle_outline,
                '${result.matchPercentage.round()}% match',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerInfo(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildNutritionSection() {
    final recipe = result.recipe;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estimated Nutrition',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: darkGreen,
          ),
        ),
        const SizedBox(height: 6),
        const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF69868B), size: 15),
            SizedBox(width: 6),
            Text(
              'Values shown per serving',
              style: TextStyle(color: Color(0xFF69868B), fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Per-serving nutrition information.
        Row(
          children: [
            Expanded(
              child: _nutritionCard(
                'Calories',
                '${_formatQuantity(recipe.caloriesPerServing)} kcal',
                Icons.local_fire_department_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _nutritionCard(
                'Protein',
                '${_formatQuantity(recipe.proteinPerServing)} g',
                Icons.fitness_center_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _nutritionCard(
                'Carbs',
                '${_formatQuantity(recipe.carbsPerServing)} g',
                Icons.grain,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _nutritionCard(
                'Fat',
                '${_formatQuantity(recipe.fatPerServing)} g',
                Icons.water_drop_outlined,
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Nutrition information for the entire recipe.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEDF8F5),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xFFD4EAE3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.restaurant_menu, color: primary, size: 19),
                  SizedBox(width: 8),
                  Text(
                    'Full Recipe Nutrition',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Servings'),
                  Text(
                    '${recipe.servings}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                    ),
                  ),
                ],
              ),

              const Divider(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Calories'),
                  Text(
                    '${_formatQuantity(recipe.totalRecipeCalories)} kcal',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Protein'),
                  Text(
                    '${_formatQuantity(recipe.totalRecipeProtein)} g',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Carbs'),
                  Text(
                    '${_formatQuantity(recipe.totalRecipeCarbs)} g',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Fat'),
                  Text(
                    '${_formatQuantity(recipe.totalRecipeFat)} g',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _nutritionCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE2ECEB)),
      ),
      child: Column(
        children: [
          Icon(icon, color: primary, size: 24),
          const SizedBox(height: 7),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: darkGreen,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B8387)),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ingredients',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: darkGreen,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '${result.matchedIngredients} of '
          '${result.totalIngredients} ingredients available',
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B8387)),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2ECEB)),
          ),
          child: Column(
            children: [
              for (
                var index = 0;
                index < result.ingredientMatches.length;
                index++
              ) ...[
                _ingredientRow(result.ingredientMatches[index]),
                if (index < result.ingredientMatches.length - 1)
                  const Divider(height: 1, indent: 14, endIndent: 14),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _ingredientRow(RecipeIngredientMatch match) {
    final ingredient = match.ingredient;
    final available = match.hasEnough;

    final statusText = available
        ? 'Available'
        : match.isMissing
        ? 'Missing'
        : match.hasCompatibleUnit
        ? 'Not enough'
        : 'Unit mismatch';

    final statusColor = available
        ? const Color(0xFF168653)
        : const Color(0xFFD88122);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            available ? Icons.check_circle : Icons.warning_amber_rounded,
            color: statusColor,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ingredient.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF25464A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Required: '
                  '${_formatQuantity(ingredient.quantity)} '
                  '${ingredient.unit}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF617B80),
                  ),
                ),
                Text(
                  'Available: '
                  '${_formatQuantity(match.availableQuantity)} '
                  '${ingredient.unit}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF617B80),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsSection() {
    final instructions = result.recipe.instructions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cooking Instructions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: darkGreen,
          ),
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < instructions.length; index++)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2ECEB)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: const Color(0xFFE0F5EE),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      instructions[index],
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Color(0xFF34575B),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
