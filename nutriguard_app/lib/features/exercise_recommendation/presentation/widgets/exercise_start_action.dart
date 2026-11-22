import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../data/models/exercise_recommendation_model.dart';
import '../../domain/models/exercise_session_arguments.dart';
import '../../domain/services/exercise_plan_date_service.dart';

class ExerciseStartAction extends StatelessWidget {
  final ExerciseRecommendationModel exercise;
  final int? weekday;

  const ExerciseStartAction({super.key, required this.exercise, this.weekday});

  Future<void> _openSession(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Start Exercise Session'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exercise.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text('Type: ${exercise.type}'),
              Text('Intensity: ${exercise.intensity}'),
              Text(
                'Suggested duration: '
                '${exercise.durationMinutes} minutes',
              ),
              const SizedBox(height: 12),
              const Text(
                'You can record your exercise using '
                'Exercise Tracking. Opening tracking '
                'will not automatically mark this '
                'session as completed.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Open Tracking'),
            ),
          ],
        );
      },
    );

    if (!context.mounted || confirmed != true) {
      return;
    }

    final selectedWeekday = weekday;

    final Object routeArguments;

    if (selectedWeekday == null) {
      // Preserve existing navigation behavior.
      routeArguments = exercise;
    } else {
      const dateService = ExercisePlanDateService();

      final plannedDate = dateService.dateForWeekday(
        referenceDate: DateTime.now(),
        weekday: selectedWeekday,
      );

      routeArguments = ExerciseSessionArguments(
        recommendation: exercise,
        plannedDate: plannedDate,
      );
    }

    await Navigator.pushNamed(
      context,
      RouteNames.exercise,
      arguments: routeArguments,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        key: const ValueKey('start-exercise-session'),
        onPressed: () => _openSession(context),
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start Session'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF086F67),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
