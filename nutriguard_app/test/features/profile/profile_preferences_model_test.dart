import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguard_app/features/profile/data/models/profile_preferences_model.dart';

void main() {
  group('ProfilePreferencesModel', () {
    test('creates model with correct values', () {
      final model = ProfilePreferencesModel(
        dietaryRestrictions: ['Halal', 'Vegetarian'],
        allergies: ['Peanuts', 'Shellfish'],
        unitSystem: 'Metric',
      );

      expect(model.dietaryRestrictions, ['Halal', 'Vegetarian']);
      expect(model.allergies, ['Peanuts', 'Shellfish']);
      expect(model.unitSystem, 'Metric');
    });

    test('returns correct default preferences', () {
      final model = ProfilePreferencesModel.defaultPreferences;

      expect(model.dietaryRestrictions, ['None']);
      expect(model.allergies, isEmpty);
      expect(model.unitSystem, 'Metric');
    });

    test('converts model to Firestore map', () {
      final model = ProfilePreferencesModel(
        dietaryRestrictions: ['Vegan'],
        allergies: ['Peanuts'],
        unitSystem: 'Imperial',
      );

      final result = model.toMap();

      expect(result['dietaryRestrictions'], ['Vegan']);
      expect(result['allergies'], ['Peanuts']);
      expect(result['unitSystem'], 'Imperial');
    });

    test('creates model from valid map', () {
      final model = ProfilePreferencesModel.fromMap({
        'dietaryRestrictions': ['Halal'],
        'allergies': ['Peanuts'],
        'unitSystem': 'Metric',
      });

      expect(model.dietaryRestrictions, ['Halal']);
      expect(model.allergies, ['Peanuts']);
      expect(model.unitSystem, 'Metric');
    });

    test('uses default values for invalid restrictions', () {
      final model = ProfilePreferencesModel.fromMap({
        'dietaryRestrictions': ['Keto'],
        'allergies': [],
        'unitSystem': 'Metric',
      });

      expect(model.dietaryRestrictions, ['None']);
    });

    test('rejects None combined with another restriction', () {
      final model = ProfilePreferencesModel.fromMap({
        'dietaryRestrictions': ['None', 'Vegan'],
        'allergies': [],
        'unitSystem': 'Metric',
      });

      expect(model.dietaryRestrictions, ['None']);
    });

    test('uses default unit system for invalid values', () {
      final model = ProfilePreferencesModel.fromMap({
        'dietaryRestrictions': ['Halal'],
        'allergies': [],
        'unitSystem': 'Other',
      });

      expect(model.unitSystem, 'Metric');
    });

    test('handles missing fields safely', () {
      final model = ProfilePreferencesModel.fromMap({});

      expect(model.dietaryRestrictions, ['None']);
      expect(model.allergies, isEmpty);
      expect(model.unitSystem, 'Metric');
    });

    test('does not allow more than 30 allergies', () {
      final model = ProfilePreferencesModel.fromMap({
        'dietaryRestrictions': ['Halal'],
        'allergies': List.generate(31, (index) => 'Allergy $index'),
        'unitSystem': 'Metric',
      });

      expect(model.allergies, isEmpty);
    });

    test('does not allow modifying model lists', () {
      final model = ProfilePreferencesModel(
        dietaryRestrictions: ['Halal'],
        allergies: ['Peanuts'],
        unitSystem: 'Metric',
      );

      expect(() => model.allergies.add('Milk'), throwsUnsupportedError);
    });
  });
}
