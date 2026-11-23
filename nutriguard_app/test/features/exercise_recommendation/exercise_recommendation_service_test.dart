import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/exercise_recommendation/data/models/exercise_recommendation_model.dart';
import 'package:nutriguard_app/features/exercise_recommendation/domain/services/exercise_recommendation_service.dart';

void main() {
  const service = ExerciseRecommendationService();

  const beginnerRequest = ExerciseRecommendationRequest(
    goal: FitnessGoal.generalFitness,
    activityLevel: ActivityLevel.beginner,
  );

  const intermediateRequest = ExerciseRecommendationRequest(
    goal: FitnessGoal.generalFitness,
    activityLevel: ActivityLevel.intermediate,
  );

  group('ExerciseRecommendationService', () {
    test('returns three recommendations by default', () {
      final result = service.recommend(request: beginnerRequest);

      expect(result.length, 3);
    });

    test('returns only low-intensity exercises for beginners', () {
      final result = service.recommend(
        request: beginnerRequest,
        maxResults: 20,
      );

      expect(result, isNotEmpty);

      for (final exercise in result) {
        expect(exercise.intensity, 'Low');
      }
    });

    test('allows moderate-intensity options for intermediate users', () {
      final result = service.recommend(
        request: intermediateRequest,
        maxResults: 20,
      );

      expect(
        result.any((exercise) => exercise.intensity == 'Moderate'),
        isTrue,
      );
    });

    test('returns no results when maxResults is zero', () {
      final result = service.recommend(request: beginnerRequest, maxResults: 0);

      expect(result, isEmpty);
    });

    test('returns no results when maxResults is negative', () {
      final result = service.recommend(
        request: beginnerRequest,
        maxResults: -3,
      );

      expect(result, isEmpty);
    });

    test('respects the maximum result count', () {
      final result = service.recommend(request: beginnerRequest, maxResults: 2);

      expect(result.length, 2);
    });

    test('does not repeat the same exercise', () {
      final result = service.recommend(
        request: intermediateRequest,
        maxResults: 20,
      );

      final ids = result.map((exercise) => exercise.id).toSet();

      expect(ids.length, result.length);
    });

    test('prioritizes cardio for endurance goal', () {
      const request = ExerciseRecommendationRequest(
        goal: FitnessGoal.improveEndurance,
        activityLevel: ActivityLevel.intermediate,
        preference: ExercisePreference.any,
      );

      final result = service.recommend(request: request);

      expect(result, isNotEmpty);
      expect(result.first.type, 'Cardio');
    });

    test('prioritizes strength for strength-building goal', () {
      const request = ExerciseRecommendationRequest(
        goal: FitnessGoal.buildStrength,
        activityLevel: ActivityLevel.intermediate,
        preference: ExercisePreference.any,
      );

      final result = service.recommend(request: request);

      expect(result, isNotEmpty);
      expect(result.first.type, 'Strength');
    });

    test('prioritizes flexibility preference', () {
      const request = ExerciseRecommendationRequest(
        goal: FitnessGoal.generalFitness,
        activityLevel: ActivityLevel.beginner,
        preference: ExercisePreference.flexibility,
      );

      final result = service.recommend(request: request);

      expect(result, isNotEmpty);
      expect(result.first.type, 'Flexibility');
    });

    test('prioritizes cardio preference', () {
      const request = ExerciseRecommendationRequest(
        goal: FitnessGoal.generalFitness,
        activityLevel: ActivityLevel.beginner,
        preference: ExercisePreference.cardio,
      );

      final result = service.recommend(request: request);

      expect(result, isNotEmpty);
      expect(result.first.type, 'Cardio');
    });

    test('prioritizes strength preference', () {
      const request = ExerciseRecommendationRequest(
        goal: FitnessGoal.generalFitness,
        activityLevel: ActivityLevel.beginner,
        preference: ExercisePreference.strength,
      );

      final result = service.recommend(request: request);

      expect(result, isNotEmpty);
      expect(result.first.type, 'Strength');
    });

    test('consistency goal favors accessible low-intensity options', () {
      const request = ExerciseRecommendationRequest(
        goal: FitnessGoal.buildConsistency,
        activityLevel: ActivityLevel.beginner,
      );

      final result = service.recommend(request: request);

      expect(result, isNotEmpty);
      expect(
        result.every(
          (exercise) =>
              exercise.intensity == 'Low' && exercise.durationMinutes <= 20,
        ),
        isTrue,
      );
    });

    test('returns deterministic ordering for the same request', () {
      final first = service.recommend(
        request: intermediateRequest,
        maxResults: 8,
      );

      final second = service.recommend(
        request: intermediateRequest,
        maxResults: 8,
      );

      expect(
        first.map((exercise) => exercise.id).toList(),
        second.map((exercise) => exercise.id).toList(),
      );
    });

    test('returns recommendation models with required display data', () {
      final result = service.recommend(
        request: intermediateRequest,
        maxResults: 8,
      );

      expect(result, isNotEmpty);

      for (final ExerciseRecommendationModel exercise in result) {
        expect(exercise.id, isNotEmpty);
        expect(exercise.name, isNotEmpty);
        expect(exercise.type, isNotEmpty);
        expect(exercise.description, isNotEmpty);
        expect(exercise.durationMinutes, greaterThan(0));
        expect(exercise.benefits, isNotEmpty);
        expect(exercise.safetyNotes, isNotEmpty);
      }
    });

    test('does not exceed the available catalog size', () {
      final result = service.recommend(
        request: intermediateRequest,
        maxResults: 100,
      );

      expect(result.length, 8);
    });
  });
}
