import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'dart:io';

import '../../../../app/theme/app_colors.dart';
import '../../../food_scanner/data/models/food_log_model.dart';
import '../../../food_scanner/data/services/food_log_photo_service.dart';
import '../../../meals/presentation/pages/meal_recommendation_page.dart';

import '../widgets/nutrition_budget_card.dart';

class NutritionAnalysisPage extends StatelessWidget {
  final FoodLogModel foodLog;
  final String? foodLogDocumentId;

  const NutritionAnalysisPage({
    super.key,
    required this.foodLog,
    this.foodLogDocumentId,
  });

  static const Color _teal = Color(0xFF009B8E);
  static const Color _dark = Color(0xFF073D58);
  static const Color _background = AppColors.background;

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _macroRow({
    required String title,
    required double grams,
    required IconData icon,
    required Color color,
    required double energyKcal,
    required double totalMacroEnergy,
  }) {
    final percentage = totalMacroEnergy > 0
        ? (energyKcal / totalMacroEnergy * 100).clamp(0.0, 100.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _dark,
                        ),
                      ),
                    ),
                    Text(
                      '${grams.toStringAsFixed(1)} g',
                      style: const TextStyle(color: Colors.blueGrey),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: _dark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    minHeight: 9,
                    color: color,
                    backgroundColor: const Color(0xFFEAF1F5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodPhoto() {
    final user = FirebaseAuth.instance.currentUser;
    final documentId = foodLogDocumentId;

    if (user == null || documentId == null || documentId.isEmpty) {
      return const SizedBox.shrink();
    }

    final photoService = FoodLogPhotoService();

    return FutureBuilder<String?>(
      future: photoService.getPhotoPath(
        userId: user.uid,
        documentId: documentId,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final imagePath = snapshot.data!;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.file(
              File(imagePath),
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final proteinEnergy = foodLog.protein * 4;
    final carbsEnergy = foodLog.carbs * 4;
    final fatEnergy = foodLog.fat * 9;

    final totalMacroEnergy = proteinEnergy + carbsEnergy + fatEnergy;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        centerTitle: true,
        title: const Text(
          'Nutrition Analysis',
          style: TextStyle(color: _dark, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFoodPhoto(),
          // Food information card

          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE1F5ED),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.restaurant,
                        color: _teal,
                        size: 42,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            foodLog.foodName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _dark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${foodLog.grams.toStringAsFixed(0)} g'
                            ' · ${foodLog.mealType}',
                            style: const TextStyle(color: Colors.blueGrey),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 15,
                                color: Colors.blueGrey,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Logged at '
                                '${TimeOfDay.fromDateTime(foodLog.loggedAt.toLocal()).format(context)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.blueGrey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Chip(
                        avatar: const Icon(
                          Icons.verified_outlined,
                          size: 16,
                          color: _teal,
                        ),
                        label: Text(
                          foodLog.source,
                          overflow: TextOverflow.ellipsis,
                        ),
                        backgroundColor: const Color(0xFFEAF8F5),
                        side: BorderSide.none,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${foodLog.calories.toStringAsFixed(0)} kcal',
                      style: const TextStyle(
                        color: _teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Calories and macronutrients
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.local_fire_department, color: _teal),
                    SizedBox(width: 8),
                    Text(
                      'Calories & Macros',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: _dark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  '${foodLog.calories.toStringAsFixed(0)} kcal',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: _dark,
                  ),
                ),

                _macroRow(
                  title: 'Protein',
                  grams: foodLog.protein,
                  icon: Icons.fitness_center,
                  color: const Color(0xFF439DFF),
                  energyKcal: proteinEnergy,
                  totalMacroEnergy: totalMacroEnergy,
                ),
                _macroRow(
                  title: 'Carbs',
                  grams: foodLog.carbs,
                  icon: Icons.grain,
                  color: const Color(0xFFFFAE39),
                  energyKcal: carbsEnergy,
                  totalMacroEnergy: totalMacroEnergy,
                ),
                _macroRow(
                  title: 'Fat',
                  grams: foodLog.fat,
                  icon: Icons.water_drop,
                  color: const Color(0xFF9B6AFF),
                  energyKcal: fatEnergy,
                  totalMacroEnergy: totalMacroEnergy,
                ),

                const SizedBox(height: 12),

                const Text(
                  'Percentages show each macronutrient\'s estimated '
                  'share of total macro energy, not daily requirements.',
                  style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Daily budget section
          NutritionBudgetCard(foodLog: foodLog),

          const SizedBox(height: 20),

          // Navigate to meal recommendations
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const MealRecommendationPage(),
                  ),
                );
              },
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('Explore Meal Recommendations'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Vitamins and minerals section
          _card(
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.eco, color: _teal),
                    SizedBox(width: 8),
                    Text(
                      'Vitamins & Minerals',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: _dark,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  'Micronutrient data is not available for '
                  'this food log yet.',
                  style: TextStyle(color: Colors.blueGrey),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
