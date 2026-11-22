import 'package:flutter/material.dart';

import '../../domain/services/progress_calculation_service.dart';

class CalorieIntakeChart extends StatelessWidget {
  final List<DailyProgressSummary> summaries;
  final int dailyCalorieTarget;

  const CalorieIntakeChart({
    super.key,
    required this.summaries,
    required this.dailyCalorieTarget,
  });

  static const Color _primary = Color(0xFF2F9B85);

  String _dayLabel(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return days[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('No calorie data available.'),
        ),
      );
    }

    final maxLoggedCalories = summaries.fold<double>(
      0,
      (maxValue, day) => day.calories > maxValue ? day.calories : maxValue,
    );

    final maxCalories =
        (maxLoggedCalories > dailyCalorieTarget
                ? maxLoggedCalories
                : dailyCalorieTarget.toDouble())
            .clamp(1.0, double.infinity)
            .toDouble();

    final isWeekly = summaries.length <= 7;

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Calorie Intake Trend',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF086F67),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Daily logged calories • Target: '
              '$dailyCalorieTarget kcal',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 190,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;

                  final barWidth = isWeekly
                      ? (availableWidth / summaries.length)
                            .clamp(32.0, 70.0)
                            .toDouble()
                      : 38.0;

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final day in summaries)
                          SizedBox(
                            width: barWidth,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: FractionallySizedBox(
                                      heightFactor: (day.calories / maxCalories)
                                          .clamp(0.0, 1.0),
                                      child: Container(
                                        width: barWidth * 0.55,
                                        decoration: BoxDecoration(
                                          color: _primary,
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(5),
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isWeekly
                                      ? _dayLabel(day.date)
                                      : '${day.date.day}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.circle, size: 10, color: _primary),
                SizedBox(width: 6),
                Text('Logged Calories', style: TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Days without food logs are shown as zero. '
              'This does not confirm zero food consumption.',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
