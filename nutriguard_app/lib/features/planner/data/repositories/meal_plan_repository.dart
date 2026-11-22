import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/planned_meal_model.dart';

class MealPlanRepository {
  final FirebaseFirestore _firestore;

  MealPlanRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _mealCollection(String userId) {
    if (userId.trim().isEmpty || userId.contains('/')) {
      throw ArgumentError('A valid user ID is required.');
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('plannedMeals');
  }

  // Create a new planned meal with an automatic Firestore ID.
  Future<PlannedMealModel> createMeal({
    required String userId,
    required String date,
    required String mealType,
    required String recipeId,
    required int servings,
  }) async {
    final collection = _mealCollection(userId);
    final document = collection.doc();

    final meal = PlannedMealModel(
      id: document.id,
      date: date,
      mealType: mealType,
      recipeId: recipeId,
      servings: servings,
    );

    meal.validate();

    await document.set(meal.toMap());

    return meal;
  }

  // Update an existing planned meal.
  Future<void> updateMeal({
    required String userId,
    required PlannedMealModel meal,
  }) async {
    meal.validate();

    await _mealCollection(userId).doc(meal.id).update(meal.toMap());
  }

  // Delete a planned meal by its ID.
  Future<void> deleteMeal({
    required String userId,
    required String mealId,
  }) async {
    if (mealId.trim().isEmpty || mealId.contains('/')) {
      throw ArgumentError('A valid meal ID is required.');
    }

    await _mealCollection(userId).doc(mealId).delete();
  }

  // Retrieve one planned meal.
  Future<PlannedMealModel?> getMeal({
    required String userId,
    required String mealId,
  }) async {
    if (mealId.trim().isEmpty || mealId.contains('/')) {
      throw ArgumentError('A valid meal ID is required.');
    }

    final snapshot = await _mealCollection(userId).doc(mealId).get();

    if (!snapshot.exists) {
      return null;
    }

    final data = snapshot.data();

    if (data == null) {
      return null;
    }

    return PlannedMealModel.fromMap({...data, 'id': snapshot.id});
  }

  // Watch meals for a selected date.
  Stream<List<PlannedMealModel>> watchMealsForDate({
    required String userId,
    required String date,
  }) {
    _validateDate(date);

    return _mealCollection(userId)
        .where('date', isEqualTo: date)
        .snapshots()
        .map((snapshot) {
          return _parseMeals(snapshot.docs);
        });
  }

  // Watch meals for a date range, inclusive.
  // Useful for a weekly meal planner.
  Stream<List<PlannedMealModel>> watchMealsForRange({
    required String userId,
    required String startDate,
    required String endDate,
  }) {
    _validateDate(startDate);
    _validateDate(endDate);

    if (startDate.compareTo(endDate) > 0) {
      throw ArgumentError('Start date must be before or equal to end date.');
    }

    return _mealCollection(userId)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .snapshots()
        .map((snapshot) {
          return _parseMeals(snapshot.docs);
        });
  }

  List<PlannedMealModel> _parseMeals(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final meals = docs.map((doc) {
      return PlannedMealModel.fromMap({...doc.data(), 'id': doc.id});
    }).toList();

    meals.sort((a, b) {
      final dateComparison = a.date.compareTo(b.date);

      if (dateComparison != 0) {
        return dateComparison;
      }

      final mealTypeComparison = PlannedMealModel.validMealTypes
          .indexOf(a.mealType)
          .compareTo(PlannedMealModel.validMealTypes.indexOf(b.mealType));

      if (mealTypeComparison != 0) {
        return mealTypeComparison;
      }

      return a.id.compareTo(b.id);
    });

    return meals;
  }

  void _validateDate(String date) {
    final sample = PlannedMealModel(
      id: 'date_validation',
      date: date,
      mealType: 'Lunch',
      recipeId: 'date_validation',
      servings: 1,
    );

    sample.validate();
  }
}
