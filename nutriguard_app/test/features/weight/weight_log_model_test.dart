import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/weight/data/models/weight_log_model.dart';

void main() {
  final measuredAt = DateTime(2026, 11, 9, 8, 30);

  WeightLogModel createWeight({
    String id = 'weight_001',
    double weightKg = 65.5,
    DateTime? date,
  }) {
    return WeightLogModel(
      id: id,
      weightKg: weightKg,
      measuredAt: date ?? measuredAt,
    );
  }

  group('WeightLogModel', () {
    test('stores all weight properties correctly', () {
      final weight = createWeight();

      expect(weight.id, 'weight_001');
      expect(weight.weightKg, 65.5);
      expect(weight.measuredAt, measuredAt);
    });

    test('converts weight log to Firestore map', () {
      final weight = createWeight();

      final map = weight.toMap();

      expect(map['weightKg'], 65.5);
      expect(map['measuredAt'], isA<Timestamp>());

      expect((map['measuredAt'] as Timestamp).toDate(), measuredAt);

      // Document ID is stored in the Firestore path.
      expect(map.containsKey('id'), false);
    });

    test('creates model from Firestore map', () {
      final map = {
        'weightKg': 68.2,
        'measuredAt': Timestamp.fromDate(measuredAt),
      };

      final weight = WeightLogModel.fromMap(id: 'weight_002', map: map);

      expect(weight.id, 'weight_002');
      expect(weight.weightKg, 68.2);
      expect(weight.measuredAt, measuredAt);
    });

    test('preserves values during serialization round trip', () {
      final original = createWeight();

      final restored = WeightLogModel.fromMap(
        id: original.id,
        map: original.toMap(),
      );

      expect(restored.id, original.id);
      expect(restored.weightKg, original.weightKg);
      expect(restored.measuredAt, original.measuredAt);
    });

    test('copyWith updates only the weight value', () {
      final original = createWeight();

      final updated = original.copyWith(weightKg: 64.8);

      expect(updated.weightKg, 64.8);
      expect(updated.id, original.id);
      expect(updated.measuredAt, original.measuredAt);
    });

    test('copyWith updates measurement date', () {
      final original = createWeight();
      final newDate = DateTime(2026, 11, 10);

      final updated = original.copyWith(measuredAt: newDate);

      expect(updated.measuredAt, newDate);
      expect(updated.weightKg, original.weightKg);
    });

    test('copyWith without arguments preserves all fields', () {
      final original = createWeight();
      final copied = original.copyWith();

      expect(copied.id, original.id);
      expect(copied.weightKg, original.weightKg);
      expect(copied.measuredAt, original.measuredAt);
    });

    test('supports decimal weight measurements', () {
      final original = createWeight(weightKg: 72.35);

      final restored = WeightLogModel.fromMap(
        id: original.id,
        map: original.toMap(),
      );

      expect(restored.weightKg, closeTo(72.35, 0.0001));
    });

    test('converts integer Firestore weight to double', () {
      final weight = WeightLogModel.fromMap(
        id: 'weight_003',
        map: {'weightKg': 70, 'measuredAt': Timestamp.fromDate(measuredAt)},
      );

      expect(weight.weightKg, 70.0);
    });
  });
}
