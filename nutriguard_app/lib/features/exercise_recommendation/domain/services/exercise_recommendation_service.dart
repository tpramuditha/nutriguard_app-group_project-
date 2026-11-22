import '../../data/models/exercise_recommendation_model.dart';

enum FitnessGoal {
  generalFitness,
  buildConsistency,
  improveEndurance,
  buildStrength,
}

enum ActivityLevel { beginner, intermediate }

enum ExercisePreference { any, cardio, strength, flexibility }

class ExerciseRecommendationRequest {
  final FitnessGoal goal;
  final ActivityLevel activityLevel;
  final ExercisePreference preference;

  const ExerciseRecommendationRequest({
    required this.goal,
    required this.activityLevel,
    this.preference = ExercisePreference.any,
  });
}

class ExerciseRecommendationService {
  const ExerciseRecommendationService();

  static const List<ExerciseRecommendationModel> _catalog = [
    ExerciseRecommendationModel(
      id: 'walking',
      name: 'Walking',
      type: 'Cardio',
      intensity: 'Low',
      durationMinutes: 20,
      description:
          'Walk at a comfortable pace on a safe, '
          'level surface.',
      benefits: ['Supports general fitness', 'Encourages regular movement'],
      safetyNotes: [
        'Start at a comfortable pace.',
        'Stop if you experience pain or feel unwell.',
      ],
    ),
    ExerciseRecommendationModel(
      id: 'gentle_stretching',
      name: 'Gentle Stretching',
      type: 'Flexibility',
      intensity: 'Low',
      durationMinutes: 10,
      description:
          'Perform slow and comfortable stretches '
          'without forcing any movement.',
      benefits: ['Supports flexibility', 'Encourages gentle daily movement'],
      safetyNotes: [
        'Avoid bouncing or forcing stretches.',
        'Stop movements that cause pain.',
      ],
    ),
    ExerciseRecommendationModel(
      id: 'chair_exercises',
      name: 'Chair Exercises',
      type: 'Strength',
      intensity: 'Low',
      durationMinutes: 15,
      description:
          'Perform simple seated movements using '
          'a stable chair.',
      benefits: [
        'Supports basic muscle activity',
        'Offers a low-intensity movement option',
      ],
      safetyNotes: [
        'Use a stable chair without wheels.',
        'Move slowly and within a comfortable range.',
      ],
    ),
    ExerciseRecommendationModel(
      id: 'easy_cycling',
      name: 'Easy Cycling',
      type: 'Cardio',
      intensity: 'Low',
      durationMinutes: 20,
      description:
          'Cycle at an easy pace on a safe route '
          'or a stationary bicycle.',
      benefits: [
        'Supports general cardiovascular fitness',
        'Provides another option for regular activity',
      ],
      safetyNotes: [
        'Use suitable safety equipment.',
        'Choose a safe route and comfortable pace.',
      ],
    ),
    ExerciseRecommendationModel(
      id: 'brisk_walking',
      name: 'Brisk Walking',
      type: 'Cardio',
      intensity: 'Moderate',
      durationMinutes: 25,
      description:
          'Walk at a moderately brisk pace while '
          'remaining comfortable.',
      benefits: [
        'Supports endurance',
        'Encourages consistent physical activity',
      ],
      safetyNotes: [
        'Warm up gradually.',
        'Reduce the pace or stop if you feel unwell.',
      ],
    ),
    ExerciseRecommendationModel(
      id: 'bodyweight_exercises',
      name: 'Basic Bodyweight Exercises',
      type: 'Strength',
      intensity: 'Moderate',
      durationMinutes: 20,
      description:
          'Practice basic controlled strength movements '
          'appropriate to your ability.',
      benefits: ['Supports muscle strength', 'Encourages movement control'],
      safetyNotes: [
        'Prioritize correct technique.',
        'Avoid movements that cause pain.',
      ],
    ),
    ExerciseRecommendationModel(
      id: 'moderate_cycling',
      name: 'Moderate Cycling',
      type: 'Cardio',
      intensity: 'Moderate',
      durationMinutes: 30,
      description:
          'Cycle at a steady, moderate pace on '
          'a safe route or stationary bicycle.',
      benefits: ['Supports endurance', 'Provides regular aerobic activity'],
      safetyNotes: [
        'Wear appropriate safety equipment.',
        'Slow down or stop if symptoms occur.',
      ],
    ),
    ExerciseRecommendationModel(
      id: 'mobility_routine',
      name: 'Mobility Routine',
      type: 'Flexibility',
      intensity: 'Low',
      durationMinutes: 15,
      description:
          'Perform controlled, gentle movements '
          'through a comfortable range of motion.',
      benefits: ['Supports joint mobility', 'Encourages regular movement'],
      safetyNotes: [
        'Do not force a joint beyond comfort.',
        'Stop if a movement causes pain.',
      ],
    ),
  ];

  List<ExerciseRecommendationModel> recommend({
    required ExerciseRecommendationRequest request,
    int maxResults = 3,
  }) {
    if (maxResults <= 0) {
      return [];
    }

    // This is preference-based selection.
    // It does not assess medical exercise safety.
    final eligible = _catalog.where((exercise) {
      if (request.activityLevel == ActivityLevel.beginner &&
          exercise.intensity != 'Low') {
        return false;
      }

      return true;
    }).toList();

    final ranked = eligible.map((exercise) {
      final score = _score(exercise, request);
      return _ScoredExercise(exercise, score);
    }).toList();

    ranked.sort((a, b) {
      final scoreComparison = b.score.compareTo(a.score);

      if (scoreComparison != 0) {
        return scoreComparison;
      }

      return a.exercise.id.compareTo(b.exercise.id);
    });

    return ranked.take(maxResults).map((item) => item.exercise).toList();
  }

  int _score(
    ExerciseRecommendationModel exercise,
    ExerciseRecommendationRequest request,
  ) {
    var score = 0;

    // User's preferred exercise category.
    switch (request.preference) {
      case ExercisePreference.any:
        break;
      case ExercisePreference.cardio:
        if (exercise.type == 'Cardio') score += 10;
        break;
      case ExercisePreference.strength:
        if (exercise.type == 'Strength') score += 10;
        break;
      case ExercisePreference.flexibility:
        if (exercise.type == 'Flexibility') score += 10;
        break;
    }

    // Fitness-goal matching.
    switch (request.goal) {
      case FitnessGoal.generalFitness:
        if (exercise.type == 'Cardio') score += 4;
        if (exercise.type == 'Flexibility') score += 3;
        if (exercise.type == 'Strength') score += 2;
        break;

      case FitnessGoal.buildConsistency:
        if (exercise.intensity == 'Low') score += 6;
        if (exercise.durationMinutes <= 20) score += 3;
        break;

      case FitnessGoal.improveEndurance:
        if (exercise.type == 'Cardio') score += 8;
        break;

      case FitnessGoal.buildStrength:
        if (exercise.type == 'Strength') score += 8;
        break;
    }

    // Prefer lower intensity for beginners.
    if (request.activityLevel == ActivityLevel.beginner &&
        exercise.intensity == 'Low') {
      score += 5;
    }

    // Give intermediate users a modest preference
    // for moderate-intensity options.
    if (request.activityLevel == ActivityLevel.intermediate &&
        exercise.intensity == 'Moderate') {
      score += 3;
    }

    return score;
  }
}

class _ScoredExercise {
  final ExerciseRecommendationModel exercise;
  final int score;

  const _ScoredExercise(this.exercise, this.score);
}
