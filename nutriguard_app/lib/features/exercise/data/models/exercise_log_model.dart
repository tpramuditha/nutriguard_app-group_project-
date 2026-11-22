import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseLogModel {
  final String id;
  final String exerciseName;
  final String exerciseType;
  final int durationMinutes;
  final bool isCompleted;
  final DateTime performedAt;

  const ExerciseLogModel({
    required this.id,
    required this.exerciseName,
    required this.exerciseType,
    required this.durationMinutes,
    required this.isCompleted,
    required this.performedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'exerciseName': exerciseName,
      'exerciseType': exerciseType,
      'durationMinutes': durationMinutes,
      'isCompleted': isCompleted,
      'performedAt': Timestamp.fromDate(performedAt),
    };
  }

  factory ExerciseLogModel.fromMap({
    required String id,
    required Map<String, dynamic> map,
  }) {
    return ExerciseLogModel(
      id: id,
      exerciseName: map['exerciseName'] as String,
      exerciseType: map['exerciseType'] as String,
      durationMinutes: (map['durationMinutes'] as num).toInt(),
      isCompleted: map['isCompleted'] as bool,
      performedAt: (map['performedAt'] as Timestamp).toDate(),
    );
  }

  ExerciseLogModel copyWith({
    String? id,
    String? exerciseName,
    String? exerciseType,
    int? durationMinutes,
    bool? isCompleted,
    DateTime? performedAt,
  }) {
    return ExerciseLogModel(
      id: id ?? this.id,
      exerciseName: exerciseName ?? this.exerciseName,
      exerciseType: exerciseType ?? this.exerciseType,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
      performedAt: performedAt ?? this.performedAt,
    );
  }
}
