import 'package:flutter/material.dart';

import '../../data/models/exercise_recommendation_model.dart';
import '../../domain/services/exercise_recommendation_service.dart';
import '../../domain/services/exercise_swap_service.dart';
import '../../domain/services/weekly_exercise_schedule_service.dart';

class ExerciseSwapAction extends StatelessWidget {
  final WeeklyExerciseSchedule schedule;
  final int weekday;
  final ExerciseRecommendationRequest request;
  final ValueChanged<WeeklyExerciseSchedule> onSwapped;

  const ExerciseSwapAction({
    super.key,
    required this.schedule,
    required this.weekday,
    required this.request,
    required this.onSwapped,
  });

  Future<void> _showAlternatives(BuildContext context) async {
    const swapService = ExerciseSwapService();

    final alternatives = swapService.getAlternatives(
      schedule: schedule,
      weekday: weekday,
      request: request,
    );

    if (alternatives.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No alternative exercises available.')),
      );
      return;
    }

    final selected = await showModalBottomSheet<ExerciseRecommendationModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.75,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Column(
                  children: [
                    Text(
                      'Swap Exercise',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF086F67),
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Select an alternative exercise '
                      'for this day.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: alternatives.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final exercise = alternatives[index];

                    return Card(
                      color: const Color(0xFFF5FAFC),
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE0F4ED),
                          child: Icon(
                            Icons.fitness_center,
                            color: Color(0xFF086F67),
                          ),
                        ),
                        title: Text(
                          exercise.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF086F67),
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${exercise.type} · '
                            '${exercise.intensity} intensity · '
                            '${exercise.durationMinutes} min',
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.pop(sheetContext, exercise);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!context.mounted || selected == null) {
      return;
    }

    try {
      final updatedSchedule = swapService.swapExercise(
        schedule: schedule,
        weekday: weekday,
        request: request,
        replacementExerciseId: selected.id,
      );

      onSwapped(updatedSchedule);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exercise changed to ${selected.name}.')),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to swap exercise. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final day = schedule.forWeekday(weekday);

    if (day.isRestDay) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        key: ValueKey('swap-exercise-$weekday'),
        onPressed: () => _showAlternatives(context),
        icon: const Icon(Icons.swap_horiz),
        label: const Text('Swap Exercise'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF086F67),
          side: const BorderSide(color: Color(0xFF086F67)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
