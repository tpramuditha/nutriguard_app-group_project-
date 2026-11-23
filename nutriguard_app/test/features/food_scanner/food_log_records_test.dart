import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/food_scanner/data/models/food_log_model.dart';
import 'package:nutriguard_app/features/food_scanner/data/repositories/food_log_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FoodLogRepository repository;

  const userId = 'test_user_001';

  FoodLogModel createFoodLog({required String name, required DateTime date}) {
    return FoodLogModel(
      foodId: name.toLowerCase().replaceAll(' ', '_'),
      foodName: name,
      source: 'Manual',
      grams: 100,
      mealType: 'Breakfast',
      calories: 200,
      protein: 5,
      carbs: 35,
      fat: 4,
      loggedAt: date,
    );
  }

  setUp(() {
    firestore = FakeFirebaseFirestore();

    repository = FoodLogRepository(firestore: firestore);
  });

  group('FoodLogRepository - FoodLogRecord', () {
    test('returns document ID with food details', () async {
      final log = createFoodLog(
        name: 'Rice and Curry',
        date: DateTime.utc(2026, 11, 3, 8),
      );

      await firestore
          .collection('users')
          .doc(userId)
          .collection('foodLogs')
          .doc('food_log_001')
          .set(log.toMap());

      final records = await repository.getFoodLogRecords(userId: userId);

      expect(records.length, 1);
      expect(records.first.documentId, 'food_log_001');
      expect(records.first.foodLog.foodName, 'Rice and Curry');
      expect(records.first.foodLog.calories, 200);
    });

    test('returns food logs in newest-first order', () async {
      final olderLog = createFoodLog(
        name: 'Breakfast',
        date: DateTime.utc(2026, 11, 2, 8),
      );

      final newerLog = createFoodLog(
        name: 'Lunch',
        date: DateTime.utc(2026, 11, 3, 12),
      );

      final collection = firestore
          .collection('users')
          .doc(userId)
          .collection('foodLogs');

      await collection.doc('older_id').set(olderLog.toMap());
      await collection.doc('newer_id').set(newerLog.toMap());

      final records = await repository.getFoodLogRecords(userId: userId);

      expect(records.length, 2);
      expect(records.first.documentId, 'newer_id');
      expect(records.last.documentId, 'older_id');
    });

    test('returns empty list when no logs exist', () async {
      final records = await repository.getFoodLogRecords(userId: userId);

      expect(records, isEmpty);
    });

    test('does not return another user food logs', () async {
      final log = createFoodLog(
        name: 'Private Meal',
        date: DateTime.utc(2026, 11, 3, 9),
      );

      await firestore
          .collection('users')
          .doc('another_user')
          .collection('foodLogs')
          .doc('private_food')
          .set(log.toMap());

      final records = await repository.getFoodLogRecords(userId: userId);

      expect(records, isEmpty);
    });

    test('preserves existing getFoodLogs behavior', () async {
      final log = createFoodLog(
        name: 'Rice and Dhal',
        date: DateTime.utc(2026, 11, 3, 10),
      );

      await firestore
          .collection('users')
          .doc(userId)
          .collection('foodLogs')
          .doc('existing_food')
          .set(log.toMap());

      final foodLogs = await repository.getFoodLogs(userId: userId);

      expect(foodLogs.length, 1);
      expect(foodLogs.first.foodName, 'Rice and Dhal');
    });
  });
}
