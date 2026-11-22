import '../../../health/data/models/monthly_health_marker_model.dart';

class HealthMarkerTrendPoint {
  final String month;
  final String measurementName;
  final double value;
  final String unit;

  const HealthMarkerTrendPoint({
    required this.month,
    required this.measurementName,
    required this.value,
    required this.unit,
  });
}

class HealthMarkerTrendService {
  const HealthMarkerTrendService();

  List<HealthMarkerTrendPoint> getTrend({
    required List<MonthlyHealthMarkerModel> monthlyRecords,
    required String measurementName,
  }) {
    final points = <HealthMarkerTrendPoint>[];

    for (final record in monthlyRecords) {
      for (final measurement in record.measurements) {
        if (measurement.name != measurementName) {
          continue;
        }

        points.add(
          HealthMarkerTrendPoint(
            month: record.month,
            measurementName: measurement.name,
            value: measurement.value,
            unit: measurement.unit,
          ),
        );
      }
    }

    // Month IDs use YYYY-MM, so alphabetical
    // ordering is also chronological ordering.
    points.sort((a, b) => a.month.compareTo(b.month));

    return points;
  }

  List<HealthMarkerTrendPoint> getTotalCholesterolTrend(
    List<MonthlyHealthMarkerModel> records,
  ) {
    return getTrend(
      monthlyRecords: records,
      measurementName: 'Total Cholesterol',
    );
  }

  List<HealthMarkerTrendPoint> getFastingGlucoseTrend(
    List<MonthlyHealthMarkerModel> records,
  ) {
    return getTrend(
      monthlyRecords: records,
      measurementName: 'Fasting Blood Glucose',
    );
  }

  List<HealthMarkerTrendPoint> getSystolicPressureTrend(
    List<MonthlyHealthMarkerModel> records,
  ) {
    return getTrend(
      monthlyRecords: records,
      measurementName: 'Systolic Blood Pressure',
    );
  }

  List<HealthMarkerTrendPoint> getDiastolicPressureTrend(
    List<MonthlyHealthMarkerModel> records,
  ) {
    return getTrend(
      monthlyRecords: records,
      measurementName: 'Diastolic Blood Pressure',
    );
  }
}
