import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/exercise_recommendation/domain/services/exercise_recommendation_service.dart';
import 'package:nutriguard_app/features/exercise_recommendation/domain/services/weekly_exercise_schedule_service.dart';

void main() {
  const service = WeeklyExerciseScheduleService();

  const beginnerRequest = ExerciseRecommendationRequest(
    goal: FitnessGoal.generalFitness,
    activityLevel: ActivityLevel.beginner,
  );

  const intermediateRequest = ExerciseRecommendationRequest(
    goal: FitnessGoal.improveEndurance,
    activityLevel: ActivityLevel.intermediate,
  );

  group('WeeklyExerciseScheduleService', () {
    test('generates seven days', () {
      final schedule = service.generate(request: beginnerRequest);

      expect(schedule.days.length, 7);
    });

    test('generates Monday through Sunday in order', () {
      final schedule = service.generate(request: beginnerRequest);

      expect(schedule.days.map((day) => day.weekday).toList(), [
        1,
        2,
        3,
        4,
        5,
        6,
        7,
      ]);
    });

    test('assigns exercises from Monday to Saturday', () {
      final schedule = service.generate(request: beginnerRequest);

      for (var weekday = 1; weekday <= 6; weekday++) {
        final day = schedule.forWeekday(weekday);

        expect(day.isRestDay, false);
        expect(day.exercise, isNotNull);
      }
    });

    test('sets Sunday as a rest day', () {
      final schedule = service.generate(request: beginnerRequest);

      final sunday = schedule.forWeekday(DateTime.sunday);

      expect(sunday.isRestDay, true);
      expect(sunday.exercise, isNull);
      expect(sunday.dayName, 'Sunday');
    });

    test('uses only low-intensity exercises for beginners', () {
      final schedule = service.generate(request: beginnerRequest);

      final exercises = schedule.days
          .where((day) => !day.isRestDay)
          .map((day) => day.exercise!);

      expect(exercises, isNotEmpty);

      for (final exercise in exercises) {
        expect(exercise.intensity, 'Low');
      }
    });

    test('can include moderate exercises for intermediate users', () {
      final schedule = service.generate(request: intermediateRequest);

      expect(
        schedule.days.any((day) => day.exercise?.intensity == 'Moderate'),
        isTrue,
      );
    });

    test('calculates six planned sessions', () {
      final schedule = service.generate(request: beginnerRequest);

      expect(schedule.plannedSessions, 6);
    });

    test('calculates total planned minutes correctly', () {
      final schedule = service.generate(request: beginnerRequest);

      final expectedMinutes = schedule.days.fold<int>(
        0,
        (total, day) => total + (day.exercise?.durationMinutes ?? 0),
      );

      expect(schedule.plannedMinutes, expectedMinutes);
      expect(schedule.plannedMinutes, greaterThan(0));
    });

    test('returns correct day names', () {
      final schedule = service.generate(request: beginnerRequest);

      expect(schedule.forWeekday(1).dayName, 'Monday');
      expect(schedule.forWeekday(2).dayName, 'Tuesday');
      expect(schedule.forWeekday(3).dayName, 'Wednesday');
      expect(schedule.forWeekday(4).dayName, 'Thursday');
      expect(schedule.forWeekday(5).dayName, 'Friday');
      expect(schedule.forWeekday(6).dayName, 'Saturday');
      expect(schedule.forWeekday(7).dayName, 'Sunday');
    });

    test('rejects invalid weekday zero', () {
      final schedule = service.generate(request: beginnerRequest);

      expect(() => schedule.forWeekday(0), throwsArgumentError);
    });

    test('rejects invalid weekday eight', () {
      final schedule = service.generate(request: beginnerRequest);

      expect(() => schedule.forWeekday(8), throwsArgumentError);
    });

    test('generates deterministic weekly schedules', () {
      final first = service.generate(request: intermediateRequest);

      final second = service.generate(request: intermediateRequest);

      expect(
        first.days.map((day) => day.exercise?.id).toList(),
        second.days.map((day) => day.exercise?.id).toList(),
      );
    });

    test('does not assign an exercise to the rest day', () {
      final schedule = service.generate(request: intermediateRequest);

      expect(schedule.forWeekday(7).exercise, isNull);
      expect(schedule.forWeekday(7).isRestDay, true);
    });

    test('uses valid exercises with positive durations', () {
      final schedule = service.generate(request: beginnerRequest);

      for (final day in schedule.days) {
        if (day.isRestDay) continue;

        expect(day.exercise!.id, isNotEmpty);
        expect(day.exercise!.name, isNotEmpty);
        expect(day.exercise!.durationMinutes, greaterThan(0));
      }
    });

    test('respects exercise preference in ranking', () {
      const request = ExerciseRecommendationRequest(
        goal: FitnessGoal.buildStrength,
        activityLevel: ActivityLevel.intermediate,
        preference: ExercisePreference.strength,
      );

      final schedule = service.generate(request: request);

      expect(schedule.forWeekday(1).exercise!.type, 'Strength');
    });
  });
}
