class PlannedMealModel {
  final String id;
  final String date;
  final String mealType;
  final String recipeId;
  final int servings;

  const PlannedMealModel({
    required this.id,
    required this.date,
    required this.mealType,
    required this.recipeId,
    required this.servings,
  });

  static const List<String> validMealTypes = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
  ];

  void validate() {
    if (id.trim().isEmpty) {
      throw ArgumentError('Meal ID cannot be empty.');
    }

    final datePattern = RegExp(
      r'^\d{4}-(0[1-9]|1[0-2])-'
      r'(0[1-9]|[12][0-9]|3[01])$',
    );

    if (!datePattern.hasMatch(date)) {
      throw ArgumentError('Date must use yyyy-MM-dd format.');
    }

    final parsedDate = DateTime.tryParse(date);

    if (parsedDate == null || formatDate(parsedDate) != date) {
      throw ArgumentError('Date must be a valid calendar date.');
    }

    if (!validMealTypes.contains(mealType)) {
      throw ArgumentError('Invalid meal type: $mealType');
    }

    if (recipeId.trim().isEmpty) {
      throw ArgumentError('Recipe ID cannot be empty.');
    }

    if (servings < 1 || servings > 20) {
      throw ArgumentError('Servings must be between 1 and 20.');
    }
  }

  static String formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  Map<String, dynamic> toMap() {
    validate();

    return {
      'id': id,
      'date': date,
      'mealType': mealType,
      'recipeId': recipeId,
      'servings': servings,
    };
  }

  factory PlannedMealModel.fromMap(Map<String, dynamic> map) {
    final model = PlannedMealModel(
      id: map['id'] as String,
      date: map['date'] as String,
      mealType: map['mealType'] as String,
      recipeId: map['recipeId'] as String,
      servings: (map['servings'] as num).toInt(),
    );

    model.validate();

    return model;
  }

  PlannedMealModel copyWith({
    String? id,
    String? date,
    String? mealType,
    String? recipeId,
    int? servings,
  }) {
    final updated = PlannedMealModel(
      id: id ?? this.id,
      date: date ?? this.date,
      mealType: mealType ?? this.mealType,
      recipeId: recipeId ?? this.recipeId,
      servings: servings ?? this.servings,
    );

    updated.validate();

    return updated;
  }
}
