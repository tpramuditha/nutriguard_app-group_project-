import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class CalorieProgressCard extends StatelessWidget {
  final int consumedCalories;
  final int targetCalories;
  final int burnedCalories;

  const CalorieProgressCard({
    super.key,
    required this.consumedCalories,
    required this.targetCalories,
    required this.burnedCalories,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = (targetCalories - consumedCalories).clamp(
      0,
      targetCalories,
    );

    final progress = targetCalories > 0
        ? (consumedCalories / targetCalories).clamp(0.0, 1.0)
        : 0.0;

    final percentage = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Calories',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'Stay on track with your goals',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),

          const SizedBox(height: 20),

          Center(
            child: SizedBox(
              width: 170,
              height: 170,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 13,
                      strokeCap: StrokeCap.round,
                      backgroundColor: const Color(0xFFE4ECEF),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),

                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$consumedCalories',
                        style: const TextStyle(
                          fontSize: 31,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      Text(
                        '/ $targetCalories kcal',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '$percentage%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const Text(
                        'of daily goal',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 22),

          const Divider(),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _calorieStat(
                  'Eaten',
                  '$consumedCalories',
                  AppColors.primary,
                ),
              ),
              Expanded(
                child: _calorieStat(
                  'Remaining',
                  '$remaining',
                  AppColors.accent,
                ),
              ),
              Expanded(
                child: _calorieStat(
                  'Burned',
                  '$burnedCalories',
                  AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _calorieStat(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const Text(
          'kcal',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
