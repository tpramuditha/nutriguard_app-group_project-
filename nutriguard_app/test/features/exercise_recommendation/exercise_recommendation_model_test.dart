import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/exercise_recommendation/data/models/exercise_recommendation_model.dart';

void main() {
  ExerciseRecommendationModel createRecommendation() {
    return const ExerciseRecommendationModel(
      id: 'walking_01',
      name: 'Walking',
      type: 'Cardio',
      intensity: 'Low',
      durationMinutes: 20,
      description: 'A gentle walking session.',
      benefits: ['Supports general fitness', 'Helps maintain daily activity'],
      safetyNotes: ['Start at a comfortable pace', 'Stop if you feel unwell'],
    );
  }

  group('ExerciseRecommendationModel', () {
    test('creates a model with the correct values', () {
      final model = createRecommendation();

      expect(model.id, 'walking_01');
      expect(model.name, 'Walking');
      expect(model.type, 'Cardio');
      expect(model.intensity, 'Low');
      expect(model.durationMinutes, 20);
      expect(model.description, 'A gentle walking session.');
    });

    test('stores benefits and safety notes', () {
      final model = createRecommendation();

      expect(model.benefits.length, 2);
      expect(model.benefits.first, 'Supports general fitness');
      expect(model.safetyNotes.length, 2);
      expect(model.safetyNotes.first, 'Start at a comfortable pace');
    });

    test('converts model to map correctly', () {
      final model = createRecommendation();

      final map = model.toMap();

      expect(map['id'], 'walking_01');
      expect(map['name'], 'Walking');
      expect(map['type'], 'Cardio');
      expect(map['intensity'], 'Low');
      expect(map['durationMinutes'], 20);
      expect(map['benefits'], contains('Supports general fitness'));
      expect(map['safetyNotes'], contains('Stop if you feel unwell'));
    });

    test('creates model from a valid map', () {
      final map = {
        'id': 'cycling_01',
        'name': 'Cycling',
        'type': 'Cardio',
        'intensity': 'Moderate',
        'durationMinutes': 30,
        'description': 'A comfortable cycling session.',
        'benefits': ['Supports cardiovascular fitness'],
        'safetyNotes': ['Use appropriate safety equipment'],
      };

      final model = ExerciseRecommendationModel.fromMap(map);

      expect(model.id, 'cycling_01');
      expect(model.name, 'Cycling');
      expect(model.intensity, 'Moderate');
      expect(model.durationMinutes, 30);
      expect(model.benefits.length, 1);
      expect(model.safetyNotes.length, 1);
    });

    test('supports map round-trip conversion', () {
      final original = createRecommendation();

      final restored = ExerciseRecommendationModel.fromMap(original.toMap());

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.type, original.type);
      expect(restored.intensity, original.intensity);
      expect(restored.durationMinutes, original.durationMinutes);
      expect(restored.description, original.description);
      expect(restored.benefits, original.benefits);
      expect(restored.safetyNotes, original.safetyNotes);
    });

    test('copyWith updates a selected field', () {
      final original = createRecommendation();

      final updated = original.copyWith(durationMinutes: 35);

      expect(updated.durationMinutes, 35);
      expect(updated.name, original.name);
      expect(updated.id, original.id);
    });

    test('copyWith updates multiple fields', () {
      final original = createRecommendation();

      final updated = original.copyWith(
        name: 'Brisk Walking',
        intensity: 'Moderate',
        durationMinutes: 25,
      );

      expect(updated.name, 'Brisk Walking');
      expect(updated.intensity, 'Moderate');
      expect(updated.durationMinutes, 25);
      expect(updated.id, original.id);
    });

    test('copyWith preserves fields when no values supplied', () {
      final original = createRecommendation();

      final copied = original.copyWith();

      expect(copied.id, original.id);
      expect(copied.name, original.name);
      expect(copied.type, original.type);
      expect(copied.intensity, original.intensity);
      expect(copied.durationMinutes, original.durationMinutes);
      expect(copied.description, original.description);
      expect(copied.benefits, original.benefits);
      expect(copied.safetyNotes, original.safetyNotes);
    });

    test('copyWith can replace benefits and safety notes', () {
      final original = createRecommendation();

      final updated = original.copyWith(
        benefits: ['New benefit'],
        safetyNotes: ['New safety note'],
      );

      expect(updated.benefits, ['New benefit']);
      expect(updated.safetyNotes, ['New safety note']);
      expect(original.benefits.length, 2);
      expect(original.safetyNotes.length, 2);
    });

    test('supports empty benefits and safety notes', () {
      final model = createRecommendation().copyWith(
        benefits: [],
        safetyNotes: [],
      );

      final restored = ExerciseRecommendationModel.fromMap(model.toMap());

      expect(restored.benefits, isEmpty);
      expect(restored.safetyNotes, isEmpty);
    });
  });
}
