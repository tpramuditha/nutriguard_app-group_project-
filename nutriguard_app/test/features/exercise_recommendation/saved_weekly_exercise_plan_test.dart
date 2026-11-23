import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/exercise_recommendation/data/models/saved_weekly_exercise_plan.dart';
import 'package:nutriguard_app/features/exercise_recommendation/domain/services/exercise_recommendation_service.dart';
import 'package:nutriguard_app/features/exercise_recommendation/domain/services/exercise_swap_service.dart';
import 'package:nutriguard_app/features/exercise_recommendation/domain/services/weekly_exercise_schedule_service.dart';

void main() {
  const scheduleService = WeeklyExerciseScheduleService();
  const swapService = ExerciseSwapService();

  const request = ExerciseRecommendationRequest(
    goal: FitnessGoal.generalFitness,
    activityLevel: ActivityLevel.beginner,
    preference: ExercisePreference.any,
  );

  SavedWeeklyExercisePlan createPlan({DateTime? referenceDate}) {
    final schedule = scheduleService.generate(request: request);

    return SavedWeeklyExercisePlan.fromSchedule(
      referenceDate: referenceDate ?? DateTime(2026, 11, 11),
      request: request,
      schedule: schedule,
    );
  }

  group('SavedWeeklyExercisePlan', () {
    test('calculates Monday as the week start', () {
      final plan = createPlan();

      expect(plan.weekStart, DateTime(2026, 11, 9));
      expect(plan.weekId, '2026-11-09');
    });

    test('serializes plan preferences', () {
      final plan = createPlan();

      final map = plan.toMap();

      expect(map['goal'], 'generalFitness');
      expect(map['activityLevel'], 'beginner');
      expect(map['preference'], 'any');
      expect(map['weekStart'], '2026-11-09');
    });

    test('serializes seven days', () {
      final plan = createPlan();

      final map = plan.toMap();
      final days = map['days'] as List;

      expect(days.length, 7);
    });

    test('preserves Sunday as a rest day', () {
      final plan = createPlan();

      final map = plan.toMap();

      final restored = SavedWeeklyExercisePlan.fromMap(map);

      expect(restored.schedule.forWeekday(7).isRestDay, isTrue);

      expect(restored.schedule.forWeekday(7).exercise, isNull);
    });

    test('restores exercise details correctly', () {
      final plan = createPlan();

      final restored = SavedWeeklyExercisePlan.fromMap(plan.toMap());

      for (var weekday = 1; weekday <= 7; weekday++) {
        final original = plan.schedule.forWeekday(weekday).exercise;

        final recovered = restored.schedule.forWeekday(weekday).exercise;

        expect(recovered?.id, original?.id);
        expect(recovered?.name, original?.name);
        expect(recovered?.type, original?.type);
        expect(recovered?.durationMinutes, original?.durationMinutes);
        expect(recovered?.benefits, original?.benefits);
        expect(recovered?.safetyNotes, original?.safetyNotes);
      }
    });

    test('preserves swapped exercises', () {
      final originalSchedule = scheduleService.generate(request: request);

      final alternatives = swapService.getAlternatives(
        schedule: originalSchedule,
        weekday: 1,
        request: request,
      );

      final swappedSchedule = swapService.swapExercise(
        schedule: originalSchedule,
        weekday: 1,
        request: request,
        replacementExerciseId: alternatives.first.id,
      );

      final plan = SavedWeeklyExercisePlan.fromSchedule(
        referenceDate: DateTime(2026, 11, 11),
        request: request,
        schedule: swappedSchedule,
      );

      final restored = SavedWeeklyExercisePlan.fromMap(plan.toMap());

      expect(
        restored.schedule.forWeekday(1).exercise!.id,
        alternatives.first.id,
      );

      expect(restored.schedule.plannedMinutes, swappedSchedule.plannedMinutes);
    });

    test('handles a week crossing two months', () {
      final plan = createPlan(referenceDate: DateTime(2026, 12, 1));

      expect(plan.weekId, '2026-11-30');
    });
  });
}
