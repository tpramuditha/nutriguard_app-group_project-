import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/exercise_recommendation/domain/services/exercise_recommendation_service.dart';
import 'package:nutriguard_app/features/exercise_recommendation/domain/services/weekly_exercise_schedule_service.dart';
import 'package:nutriguard_app/features/exercise_recommendation/domain/services/exercise_swap_service.dart';

void main() {
  const swapService = ExerciseSwapService();
  const scheduleService = WeeklyExerciseScheduleService();

  const beginnerRequest = ExerciseRecommendationRequest(
    goal: FitnessGoal.generalFitness,
    activityLevel: ActivityLevel.beginner,
  );

  const intermediateRequest = ExerciseRecommendationRequest(
    goal: FitnessGoal.improveEndurance,
    activityLevel: ActivityLevel.intermediate,
  );

  group('ExerciseSwapService', () {
    test('returns alternatives for an exercise day', () {
      final schedule = scheduleService.generate(request: beginnerRequest);

      final alternatives = swapService.getAlternatives(
        schedule: schedule,
        weekday: 1,
        request: beginnerRequest,
      );

      expect(alternatives, isNotEmpty);
    });

    test('excludes the currently selected exercise', () {
      final schedule = scheduleService.generate(request: beginnerRequest);

      final currentExercise = schedule.forWeekday(1).exercise!;

      final alternatives = swapService.getAlternatives(
        schedule: schedule,
        weekday: 1,
        request: beginnerRequest,
      );

      expect(
        alternatives.any((exercise) => exercise.id == currentExercise.id),
        isFalse,
      );
    });

    test('returns only low-intensity alternatives for beginners', () {
      final schedule = scheduleService.generate(request: beginnerRequest);

      final alternatives = swapService.getAlternatives(
        schedule: schedule,
        weekday: 1,
        request: beginnerRequest,
      );

      expect(alternatives, isNotEmpty);

      for (final exercise in alternatives) {
        expect(exercise.intensity, 'Low');
      }
    });

    test('allows moderate alternatives for intermediate users', () {
      final schedule = scheduleService.generate(request: intermediateRequest);

      final alternatives = swapService.getAlternatives(
        schedule: schedule,
        weekday: 1,
        request: intermediateRequest,
      );

      expect(
        alternatives.any((exercise) => exercise.intensity == 'Moderate'),
        isTrue,
      );
    });

    test('returns no alternatives for Sunday rest day', () {
      final schedule = scheduleService.generate(request: beginnerRequest);

      final alternatives = swapService.getAlternatives(
        schedule: schedule,
        weekday: DateTime.sunday,
        request: beginnerRequest,
      );

      expect(alternatives, isEmpty);
    });

    test('successfully swaps Monday exercise', () {
      final schedule = scheduleService.generate(request: beginnerRequest);

      final original = schedule.forWeekday(1).exercise!;

      final alternatives = swapService.getAlternatives(
        schedule: schedule,
        weekday: 1,
        request: beginnerRequest,
      );

      final replacement = alternatives.first;

      final updatedSchedule = swapService.swapExercise(
        schedule: schedule,
        weekday: 1,
        request: beginnerRequest,
        replacementExerciseId: replacement.id,
      );

      expect(updatedSchedule.forWeekday(1).exercise!.id, replacement.id);

      expect(updatedSchedule.forWeekday(1).exercise!.id, isNot(original.id));
    });

    test('does not modify the original schedule', () {
      final schedule = scheduleService.generate(request: beginnerRequest);

      final originalId = schedule.forWeekday(1).exercise!.id;

      final alternatives = swapService.getAlternatives(
        schedule: schedule,
        weekday: 1,
        request: beginnerRequest,
      );

      final updatedSchedule = swapService.swapExercise(
        schedule: schedule,
        weekday: 1,
        request: beginnerRequest,
        replacementExerciseId: alternatives.first.id,
      );

      expect(schedule.forWeekday(1).exercise!.id, originalId);

      expect(updatedSchedule.forWeekday(1).exercise!.id, isNot(originalId));

      expect(identical(schedule, updatedSchedule), isFalse);
    });

    test('preserves exercises on other days', () {
      final schedule = scheduleService.generate(request: beginnerRequest);

      final alternatives = swapService.getAlternatives(
        schedule: schedule,
        weekday: 1,
        request: beginnerRequest,
      );

      final updatedSchedule = swapService.swapExercise(
        schedule: schedule,
        weekday: 1,
        request: beginnerRequest,
        replacementExerciseId: alternatives.first.id,
      );

      for (var weekday = 2; weekday <= 7; weekday++) {
        expect(
          updatedSchedule.forWeekday(weekday).exercise?.id,
          schedule.forWeekday(weekday).exercise?.id,
        );
      }
    });

    test('rejects swapping exercise on Sunday', () {
      final schedule = scheduleService.generate(request: beginnerRequest);

      expect(
        () => swapService.swapExercise(
          schedule: schedule,
          weekday: DateTime.sunday,
          request: beginnerRequest,
          replacementExerciseId: 'walking',
        ),
        throwsStateError,
      );
    });

    test('rejects an unknown replacement exercise', () {
      final schedule = scheduleService.generate(request: beginnerRequest);

      expect(
        () => swapService.swapExercise(
          schedule: schedule,
          weekday: 1,
          request: beginnerRequest,
          replacementExerciseId: 'unknown_exercise',
        ),
        throwsArgumentError,
      );
    });

    test('rejects replacing an exercise with itself', () {
      final schedule = scheduleService.generate(request: beginnerRequest);

      final currentId = schedule.forWeekday(1).exercise!.id;

      expect(
        () => swapService.swapExercise(
          schedule: schedule,
          weekday: 1,
          request: beginnerRequest,
          replacementExerciseId: currentId,
        ),
        throwsArgumentError,
      );
    });

    test('rejects invalid weekday values', () {
      final schedule = scheduleService.generate(request: beginnerRequest);

      expect(
        () => swapService.getAlternatives(
          schedule: schedule,
          weekday: 0,
          request: beginnerRequest,
        ),
        throwsArgumentError,
      );

      expect(
        () => swapService.getAlternatives(
          schedule: schedule,
          weekday: 8,
          request: beginnerRequest,
        ),
        throwsArgumentError,
      );
    });

    test('updates planned minutes after a swap', () {
      final schedule = scheduleService.generate(request: beginnerRequest);

      final originalMinutes = schedule.forWeekday(1).exercise!.durationMinutes;

      final alternatives = swapService.getAlternatives(
        schedule: schedule,
        weekday: 1,
        request: beginnerRequest,
      );

      final replacement = alternatives.first;

      final updatedSchedule = swapService.swapExercise(
        schedule: schedule,
        weekday: 1,
        request: beginnerRequest,
        replacementExerciseId: replacement.id,
      );

      final expectedMinutes =
          schedule.plannedMinutes -
          originalMinutes +
          replacement.durationMinutes;

      expect(updatedSchedule.plannedMinutes, expectedMinutes);

      expect(updatedSchedule.plannedSessions, schedule.plannedSessions);
    });

    test('keeps Sunday as a rest day after swapping', () {
      final schedule = scheduleService.generate(request: intermediateRequest);

      final alternatives = swapService.getAlternatives(
        schedule: schedule,
        weekday: 3,
        request: intermediateRequest,
      );

      final updatedSchedule = swapService.swapExercise(
        schedule: schedule,
        weekday: 3,
        request: intermediateRequest,
        replacementExerciseId: alternatives.first.id,
      );

      expect(updatedSchedule.forWeekday(7).isRestDay, isTrue);

      expect(updatedSchedule.forWeekday(7).exercise, isNull);
    });

    test('returns deterministic alternative ordering', () {
      final schedule = scheduleService.generate(request: beginnerRequest);

      final first = swapService.getAlternatives(
        schedule: schedule,
        weekday: 1,
        request: beginnerRequest,
      );

      final second = swapService.getAlternatives(
        schedule: schedule,
        weekday: 1,
        request: beginnerRequest,
      );

      expect(
        first.map((exercise) => exercise.id).toList(),
        second.map((exercise) => exercise.id).toList(),
      );
    });
  });
}
