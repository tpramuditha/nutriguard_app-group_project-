class NutritionGoalModel {
  final int dailyCalorieTarget;
  final String goalType;

  const NutritionGoalModel({
    required this.dailyCalorieTarget,
    required this.goalType,
  });

  static const NutritionGoalModel defaultGoal = NutritionGoalModel(
    dailyCalorieTarget: 2000,
    goalType: 'Maintain Weight',
  );

  Map<String, dynamic> toMap() {
    return {'dailyCalorieTarget': dailyCalorieTarget, 'goalType': goalType};
  }

  factory NutritionGoalModel.fromMap(Map<String, dynamic> map) {
    final calories = map['dailyCalorieTarget'];
    final goal = map['goalType'];

    return NutritionGoalModel(
      dailyCalorieTarget: calories is int && calories > 0 && calories <= 10000
          ? calories
          : defaultGoal.dailyCalorieTarget,
      goalType:
          goal == 'Weight Loss' ||
              goal == 'Maintain Weight' ||
              goal == 'Weight Gain'
          ? goal as String
          : defaultGoal.goalType,
    );
  }
}
