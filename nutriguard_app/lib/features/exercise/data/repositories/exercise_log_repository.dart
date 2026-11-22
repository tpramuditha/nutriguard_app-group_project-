import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/exercise_log_model.dart';

class ExerciseLogRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ExerciseLogRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _exerciseCollection() {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('You must be signed in to manage exercise logs.');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('exerciseLogs');
  }

  void _validateExercise(ExerciseLogModel exercise) {
    if (exercise.exerciseName.trim().isEmpty) {
      throw ArgumentError('Exercise name cannot be empty.');
    }

    if (exercise.exerciseType.trim().isEmpty) {
      throw ArgumentError('Exercise type cannot be empty.');
    }

    if (exercise.durationMinutes < 0 || exercise.durationMinutes > 1440) {
      throw ArgumentError(
        'Exercise duration must be between 0 and 1440 minutes.',
      );
    }
  }

  // Save a new exercise log.
  // Firestore generates a unique document ID.
  Future<String> addExercise(ExerciseLogModel exercise) async {
    _validateExercise(exercise);

    final collection = _exerciseCollection();

    final document = await collection.add(exercise.toMap());

    return document.id;
  }

  // Load all exercise records for the signed-in user.
  Future<List<ExerciseLogModel>> getExerciseLogs() async {
    final snapshot = await _exerciseCollection()
        .orderBy('performedAt', descending: true)
        .get();

    return snapshot.docs.map((document) {
      return ExerciseLogModel.fromMap(id: document.id, map: document.data());
    }).toList();
  }

  // Load records within the selected date range.
  Future<List<ExerciseLogModel>> getExerciseLogsForRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (endDate.isBefore(startDate)) {
      throw ArgumentError('End date cannot be before start date.');
    }

    final start = DateTime(startDate.year, startDate.month, startDate.day);

    // Exclusive end boundary includes the full end day.
    final endExclusive = DateTime(endDate.year, endDate.month, endDate.day + 1);

    final snapshot = await _exerciseCollection()
        .where('performedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('performedAt', isLessThan: Timestamp.fromDate(endExclusive))
        .orderBy('performedAt', descending: true)
        .get();

    return snapshot.docs.map((document) {
      return ExerciseLogModel.fromMap(id: document.id, map: document.data());
    }).toList();
  }

  // Update an existing exercise record.
  Future<void> updateExercise(ExerciseLogModel exercise) async {
    if (exercise.id.trim().isEmpty) {
      throw ArgumentError('Exercise ID cannot be empty.');
    }

    _validateExercise(exercise);

    await _exerciseCollection().doc(exercise.id).update(exercise.toMap());
  }

  // Delete an exercise record.
  Future<void> deleteExercise(String exerciseId) async {
    if (exerciseId.trim().isEmpty) {
      throw ArgumentError('Exercise ID cannot be empty.');
    }

    await _exerciseCollection().doc(exerciseId).delete();
  }
}
