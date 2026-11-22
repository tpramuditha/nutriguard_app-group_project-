import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class MacroChart extends StatelessWidget {
  final double consumedProtein;
  final double consumedCarbs;
  final double consumedFat;

  final double targetProtein;
  final double targetCarbs;
  final double targetFat;

  const MacroChart({
    super.key,
    required this.consumedProtein,
    required this.consumedCarbs,
    required this.consumedFat,
    this.targetProtein = 90,
    this.targetCarbs = 250,
    this.targetFat = 65,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
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
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Macronutrients',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Daily intake',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 22),

          _macroItem(
            title: 'Protein',
            icon: Icons.fitness_center,
            consumed: consumedProtein,
            target: targetProtein,
            color: const Color(0xFF4196EA),
          ),

          const SizedBox(height: 20),

          _macroItem(
            title: 'Carbs',
            icon: Icons.grain,
            consumed: consumedCarbs,
            target: targetCarbs,
            color: const Color(0xFFFFB62F),
          ),

          const SizedBox(height: 20),

          _macroItem(
            title: 'Fat',
            icon: Icons.water_drop,
            consumed: consumedFat,
            target: targetFat,
            color: const Color(0xFF9A70ED),
          ),
        ],
      ),
    );
  }

  Widget _macroItem({
    required String title,
    required IconData icon,
    required double consumed,
    required double target,
    required Color color,
  }) {
    final progress = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              '${consumed.toStringAsFixed(1)}g / '
              '${target.toStringAsFixed(0)}g',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: const Color(0xFFE4EAF0),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
