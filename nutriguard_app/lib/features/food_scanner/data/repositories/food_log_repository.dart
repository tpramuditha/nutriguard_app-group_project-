import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/food_log_model.dart';

class FoodLogRecord {
  final String documentId;
  final FoodLogModel foodLog;

  const FoodLogRecord({required this.documentId, required this.foodLog});
}

class FoodLogRepository {
  final FirebaseFirestore _firestore;

  FoodLogRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _foodLogs(String userId) {
    if (userId.trim().isEmpty) {
      throw ArgumentError('A valid user ID is required.');
    }

    return _firestore.collection('users').doc(userId).collection('foodLogs');
  }

  // Compare the user-confirmed food details.
  // foodId and loggedAt are excluded because the current
  // Manual Entry screen recreates them on each save attempt.

  bool _matchesExistingLog(
    Map<String, dynamic> existing,
    Map<String, dynamic> incoming,
  ) {
    const fields = [
      'foodId',
      'foodName',
      'brand',
      'source',
      'grams',
      'mealType',
      'calories',
      'protein',
      'carbs',
      'fat',
    ];

    for (final field in fields) {
      final oldValue = existing[field];
      final newValue = incoming[field];

      if (oldValue is num && newValue is num) {
        if (oldValue.toDouble() != newValue.toDouble()) {
          return false;
        }
      } else if (oldValue != newValue) {
        return false;
      }
    }

    // Firestore may return a Timestamp even if the original
    // food log was created using a Dart DateTime.
    DateTime? asDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }

      if (value is DateTime) {
        return value;
      }

      return null;
    }

    final oldLoggedAt = asDateTime(existing['loggedAt']);
    final newLoggedAt = asDateTime(incoming['loggedAt']);

    if (oldLoggedAt == null || newLoggedAt == null) {
      return false;
    }

    return oldLoggedAt.millisecondsSinceEpoch ==
        newLoggedAt.millisecondsSinceEpoch;
  }

  Future<String> saveFoodLog({
    required String userId,
    required FoodLogModel foodLog,
    String? submissionId,
  }) async {
    final collection = _foodLogs(userId);

    // Preserve the original behavior for existing screens.
    if (submissionId == null) {
      final document = await collection.add(foodLog.toMap());
      return document.id;
    }

    final id = submissionId.trim();

    if (id.isEmpty ||
        id.contains('/') ||
        id == '.' ||
        id == '..' ||
        id.length > 200) {
      throw ArgumentError('Invalid food log submission ID.');
    }

    final document = collection.doc(id);
    final incomingData = foodLog.toMap();

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(document);

      if (snapshot.exists) {
        final existingData = snapshot.data();

        if (existingData == null ||
            !_matchesExistingLog(existingData, incomingData)) {
          throw StateError(
            'This submission ID already belongs to '
            'a different food log.',
          );
        }

        // Already saved: no second write is needed.
        return;
      }

      // First submission: create the document.
      transaction.set(document, incomingData);
    });

    return document.id;
  }

  Future<List<FoodLogModel>> getFoodLogs({required String userId}) async {
    final snapshot = await _foodLogs(userId)
        .orderBy('loggedAt', descending: true)
        .get();

    return snapshot.docs.map((document) {
      return FoodLogModel.fromMap(document.data());
    }).toList();
  }

  Future<List<FoodLogRecord>> getFoodLogRecords({
    required String userId,
  }) async {
    final snapshot = await _foodLogs(userId)
        .orderBy('loggedAt', descending: true)
        .get();

    return snapshot.docs.map((document) {
      return FoodLogRecord(
        documentId: document.id,
        foodLog: FoodLogModel.fromMap(document.data()),
      );
    }).toList();
  }
}
