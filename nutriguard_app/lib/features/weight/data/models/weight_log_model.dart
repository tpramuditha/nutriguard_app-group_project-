import 'package:cloud_firestore/cloud_firestore.dart';

class WeightLogModel {
  final String id;
  final double weightKg;
  final DateTime measuredAt;

  const WeightLogModel({
    required this.id,
    required this.weightKg,
    required this.measuredAt,
  });

  Map<String, dynamic> toMap() {
    return {'weightKg': weightKg, 'measuredAt': Timestamp.fromDate(measuredAt)};
  }

  factory WeightLogModel.fromMap({
    required String id,
    required Map<String, dynamic> map,
  }) {
    return WeightLogModel(
      id: id,
      weightKg: (map['weightKg'] as num).toDouble(),
      measuredAt: (map['measuredAt'] as Timestamp).toDate(),
    );
  }

  WeightLogModel copyWith({
    String? id,
    double? weightKg,
    DateTime? measuredAt,
  }) {
    return WeightLogModel(
      id: id ?? this.id,
      weightKg: weightKg ?? this.weightKg,
      measuredAt: measuredAt ?? this.measuredAt,
    );
  }
}
