import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class MoreMealOptions extends StatelessWidget {
  const MoreMealOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'More Options',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                _showMessage(context, 'More meals coming soon');
              },
              child: const Text('See All →'),
            ),
          ],
        ),

        const SizedBox(height: 12),

        _mealOption(
          context,
          title: 'Grilled Chicken Bowl',
          calories: 310,
          imagePath: 'assets/images/meals/chicken_bowl.png',
        ),

        const SizedBox(height: 12),

        _mealOption(
          context,
          title: 'Lentil Soup with Whole Grain Bread',
          calories: 280,
          imagePath: 'assets/images/meals/lentil_soup.png',
        ),

        const SizedBox(height: 12),

        _mealOption(
          context,
          title: 'Tofu Stir-Fry with Quinoa',
          calories: 340,
          imagePath: 'assets/images/meals/tofu_quinoa.png',
        ),
      ],
    );
  }

  Widget _mealOption(
    BuildContext context, {
    required String title,
    required int calories,
    required String imagePath,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              imagePath,
              width: 86,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 86,
                  height: 90,
                  color: AppColors.primaryLight,
                  child: const Icon(Icons.restaurant, color: AppColors.primary),
                );
              },
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  '$calories kcal',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 8),

                InkWell(
                  onTap: () {
                    _showMessage(context, 'Explanation for $title coming soon');
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 15,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Why This?',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),

          IconButton(
            onPressed: () {
              _showMessage(context, 'Add $title to Planner coming soon');
            },
            icon: const Icon(Icons.add_circle),
            color: AppColors.primary,
            iconSize: 30,
            tooltip: 'Add to Planner',
          ),
        ],
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
