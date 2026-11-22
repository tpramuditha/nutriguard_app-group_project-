import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/nutrition_goal_model.dart';

class NutritionGoalRepository {
  final FirebaseFirestore _firestore;

  NutritionGoalRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _goalDocument(String userId) {
    if (userId.trim().isEmpty) {
      throw ArgumentError('A valid user ID is required.');
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('preferences')
        .doc('nutrition');
  }

  Future<NutritionGoalModel> getNutritionGoal({required String userId}) async {
    final snapshot = await _goalDocument(userId).get();

    if (!snapshot.exists || snapshot.data() == null) {
      return NutritionGoalModel.defaultGoal;
    }

    return NutritionGoalModel.fromMap(snapshot.data()!);
  }

  Future<void> saveNutritionGoal({
    required String userId,
    required NutritionGoalModel goal,
  }) async {
    if (goal.dailyCalorieTarget <= 0 || goal.dailyCalorieTarget > 10000) {
      throw ArgumentError('Daily calorie target must be between 1 and 10000.');
    }

    if (!const [
      'Weight Loss',
      'Maintain Weight',
      'Weight Gain',
    ].contains(goal.goalType)) {
      throw ArgumentError('Invalid goal type.');
    }

    await _goalDocument(userId).set(goal.toMap());
  }
}
