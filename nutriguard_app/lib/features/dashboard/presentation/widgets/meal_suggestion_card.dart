import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/routes/route_names.dart';

class MealSuggestionCard extends StatelessWidget {
  const MealSuggestionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF3E8FF), Color(0xFFE5EBFF), Color(0xFFD9E5FF)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFF6941E8), size: 24),
              SizedBox(width: 8),
              Text(
                'AI Suggestion',
                style: TextStyle(
                  color: Color(0xFF6941E8),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              const Expanded(
                flex: 3,
                child: Text(
                  'Try grilled fish with vegetables for dinner tonight',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                flex: 2,
                child: Image.asset(
                  'assets/images/dashboard/suggested_dinner.png',
                  height: 105,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.restaurant_menu,
                      size: 60,
                      color: AppColors.primary,
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, RouteNames.mealRecommendation);
              },
              label: const Text('View Details'),
              icon: const Icon(Icons.arrow_forward, size: 18),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6941E8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
