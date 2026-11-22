import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/saved_weekly_exercise_plan.dart';
import '../../domain/services/exercise_plan_date_service.dart';

class WeeklyExercisePlanRepository {
  // Lazy initialization keeps UI-only widget tests
  // independent of Firebase initialization.
  late final FirebaseAuth _auth = FirebaseAuth.instance;

  late final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _requireUserId() {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError(
        'You must be signed in to access weekly exercise plans.',
      );
    }

    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> _plans() {
    final userId = _requireUserId();

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('weeklyExercisePlans');
  }

  String _weekId(DateTime referenceDate) {
    const dateService = ExercisePlanDateService();

    final monday = dateService.dateForWeekday(
      referenceDate: referenceDate,
      weekday: DateTime.monday,
    );

    final year = monday.year;
    final month = monday.month.toString().padLeft(2, '0');
    final day = monday.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  // Save a weekly plan.
  // Saving the same week again replaces that week's data.
  Future<void> savePlan(SavedWeeklyExercisePlan plan) async {
    await _plans().doc(plan.weekId).set(plan.toMap());
  }

  // Load a saved plan for the week containing referenceDate.
  // Returns null when no plan exists.
  Future<SavedWeeklyExercisePlan?> loadPlan({
    required DateTime referenceDate,
  }) async {
    final weekId = _weekId(referenceDate);

    final snapshot = await _plans().doc(weekId).get();

    if (!snapshot.exists) {
      return null;
    }

    final data = snapshot.data();

    if (data == null) {
      return null;
    }

    return SavedWeeklyExercisePlan.fromMap(data);
  }

  // Delete a saved plan for a specific week.
  Future<void> deletePlan({required DateTime referenceDate}) async {
    final weekId = _weekId(referenceDate);

    await _plans().doc(weekId).delete();
  }
}
