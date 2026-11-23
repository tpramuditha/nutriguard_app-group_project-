import 'package:cloud_firestore/cloud_firestore.dart';

class FoodLogModel {
  final String foodId;
  final String foodName;
  final String? brand;
  final String source;

  final double grams;
  final String mealType;

  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  final DateTime loggedAt;

  // Optional device-local image path.
  // Null means the food log has no saved photo.
  final String? localImagePath;

  const FoodLogModel({
    required this.foodId,
    required this.foodName,
    this.brand,
    required this.source,
    required this.grams,
    required this.mealType,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.loggedAt,
    this.localImagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'foodId': foodId,
      'foodName': foodName,
      'brand': brand,
      'source': source,
      'grams': grams,
      'mealType': mealType,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'loggedAt': Timestamp.fromDate(loggedAt),
    };
  }

  factory FoodLogModel.fromMap(Map<String, dynamic> map) {
    final imageValue = map['localImagePath'];

    final String? imagePath =
        imageValue is String && imageValue.trim().isNotEmpty
        ? imageValue
        : null;

    return FoodLogModel(
      foodId: map['foodId'] as String,
      foodName: map['foodName'] as String,
      brand: map['brand'] as String?,
      source: map['source'] as String,
      grams: (map['grams'] as num).toDouble(),
      mealType: map['mealType'] as String,
      calories: (map['calories'] as num).toDouble(),
      protein: (map['protein'] as num).toDouble(),
      carbs: (map['carbs'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
      loggedAt: (map['loggedAt'] as Timestamp).toDate(),
      localImagePath: imagePath,
    );
  }
}
