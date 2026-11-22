import 'package:flutter/material.dart';

class WeeklyMealDayCard extends StatelessWidget {
  final String dayName;
  final String date;
  final int mealCount;
  final double estimatedCalories;
  final List<String> mealDescriptions;
  final VoidCallback? onTap;

  const WeeklyMealDayCard({
    super.key,
    required this.dayName,
    required this.date,
    required this.mealCount,
    required this.estimatedCalories,
    required this.mealDescriptions,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$dayName · $date',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF086F67),
                      ),
                    ),
                  ),
                  Text(
                    '${estimatedCalories.round()} kcal',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right, size: 20),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              if (mealCount == 0)
                const Text(
                  'No meals planned.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                )
              else ...[
                Text(
                  '$mealCount planned meal(s)',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                for (final description in mealDescriptions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(
                      description,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
