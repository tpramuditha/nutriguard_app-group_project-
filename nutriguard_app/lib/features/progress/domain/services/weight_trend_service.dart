import '../../../weight/data/models/weight_log_model.dart';

class WeightTrendPoint {
  final DateTime date;
  final double weightKg;

  const WeightTrendPoint({required this.date, required this.weightKg});
}

class WeightTrendResult {
  final List<WeightTrendPoint> points;

  const WeightTrendResult({required this.points});

  bool get hasData => points.isNotEmpty;

  double? get firstWeight => hasData ? points.first.weightKg : null;

  double? get latestWeight => hasData ? points.last.weightKg : null;

  double? get weightChangeKg {
    if (points.length < 2) {
      return null;
    }

    return points.last.weightKg - points.first.weightKg;
  }
}

class WeightTrendService {
  const WeightTrendService();

  WeightTrendResult calculate({
    required List<WeightLogModel> weightLogs,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);

    final end = DateTime(endDate.year, endDate.month, endDate.day);

    if (end.isBefore(start)) {
      throw ArgumentError('End date cannot be before start date.');
    }

    final endExclusive = DateTime(end.year, end.month, end.day + 1);

    // Only include valid measurements within
    // the selected calendar-date range.
    final filtered = weightLogs.where((log) {
      return log.weightKg.isFinite &&
          log.weightKg >= 2 &&
          log.weightKg <= 500 &&
          !log.measuredAt.isBefore(start) &&
          log.measuredAt.isBefore(endExclusive);
    }).toList();

    // Sort oldest to newest.
    filtered.sort((a, b) {
      final dateComparison = a.measuredAt.compareTo(b.measuredAt);

      if (dateComparison != 0) {
        return dateComparison;
      }

      // Deterministic ordering for identical timestamps.
      return a.id.compareTo(b.id);
    });

    // Keep the latest measurement for each day.
    // This prevents duplicate daily points in the chart.
    final latestByDay = <DateTime, WeightTrendPoint>{};

    for (final log in filtered) {
      final day = DateTime(
        log.measuredAt.year,
        log.measuredAt.month,
        log.measuredAt.day,
      );

      latestByDay[day] = WeightTrendPoint(date: day, weightKg: log.weightKg);
    }

    final points = latestByDay.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return WeightTrendResult(points: points);
  }
}
