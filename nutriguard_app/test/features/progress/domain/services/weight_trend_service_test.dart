import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/weight/data/models/weight_log_model.dart';
import 'package:nutriguard_app/features/progress/domain/services/weight_trend_service.dart';

void main() {
  const service = WeightTrendService();

  WeightLogModel createWeight({
    required String id,
    required double kg,
    required DateTime date,
  }) {
    return WeightLogModel(id: id, weightKg: kg, measuredAt: date);
  }

  group('WeightTrendService', () {
    test('returns empty result when no weight records exist', () {
      final result = service.calculate(
        weightLogs: [],
        startDate: DateTime(2026, 11, 1),
        endDate: DateTime(2026, 11, 9),
      );

      expect(result.hasData, false);
      expect(result.points, isEmpty);
      expect(result.firstWeight, isNull);
      expect(result.latestWeight, isNull);
      expect(result.weightChangeKg, isNull);
    });

    test('sorts weight records chronologically', () {
      final logs = [
        createWeight(id: '3', kg: 65.5, date: DateTime(2026, 11, 9)),
        createWeight(id: '1', kg: 67, date: DateTime(2026, 11, 1)),
        createWeight(id: '2', kg: 66, date: DateTime(2026, 11, 5)),
      ];

      final result = service.calculate(
        weightLogs: logs,
        startDate: DateTime(2026, 11, 1),
        endDate: DateTime(2026, 11, 9),
      );

      expect(result.points.length, 3);
      expect(result.points[0].weightKg, 67);
      expect(result.points[1].weightKg, 66);
      expect(result.points[2].weightKg, 65.5);
    });

    test('calculates weight change correctly', () {
      final logs = [
        createWeight(id: '1', kg: 67, date: DateTime(2026, 11, 1)),
        createWeight(id: '2', kg: 65.5, date: DateTime(2026, 11, 9)),
      ];

      final result = service.calculate(
        weightLogs: logs,
        startDate: DateTime(2026, 11, 1),
        endDate: DateTime(2026, 11, 9),
      );

      expect(result.firstWeight, 67);
      expect(result.latestWeight, 65.5);
      expect(result.weightChangeKg, closeTo(-1.5, 0.0001));
    });

    test('calculates weight gain as positive change', () {
      final logs = [
        createWeight(id: '1', kg: 60, date: DateTime(2026, 11, 1)),
        createWeight(id: '2', kg: 62.5, date: DateTime(2026, 11, 9)),
      ];

      final result = service.calculate(
        weightLogs: logs,
        startDate: DateTime(2026, 11, 1),
        endDate: DateTime(2026, 11, 9),
      );

      expect(result.weightChangeKg, closeTo(2.5, 0.0001));
    });

    test('returns null change for only one measurement', () {
      final result = service.calculate(
        weightLogs: [
          createWeight(id: '1', kg: 65.5, date: DateTime(2026, 11, 9)),
        ],
        startDate: DateTime(2026, 11, 1),
        endDate: DateTime(2026, 11, 9),
      );

      expect(result.hasData, true);
      expect(result.firstWeight, 65.5);
      expect(result.latestWeight, 65.5);
      expect(result.weightChangeKg, isNull);
    });

    test('excludes weight records outside selected period', () {
      final logs = [
        createWeight(id: 'before', kg: 70, date: DateTime(2026, 10, 31)),
        createWeight(id: 'inside', kg: 68, date: DateTime(2026, 11, 5)),
        createWeight(id: 'after', kg: 66, date: DateTime(2026, 11, 10)),
      ];

      final result = service.calculate(
        weightLogs: logs,
        startDate: DateTime(2026, 11, 1),
        endDate: DateTime(2026, 11, 9),
      );

      expect(result.points.length, 1);
      expect(result.points.first.weightKg, 68);
    });

    test('includes start and end calendar dates', () {
      final logs = [
        createWeight(id: 'start', kg: 69, date: DateTime(2026, 11, 1, 0, 0)),
        createWeight(id: 'end', kg: 68, date: DateTime(2026, 11, 9, 23, 59)),
      ];

      final result = service.calculate(
        weightLogs: logs,
        startDate: DateTime(2026, 11, 1),
        endDate: DateTime(2026, 11, 9),
      );

      expect(result.points.length, 2);
      expect(result.latestWeight, 68);
    });

    test('keeps latest measurement for duplicate day', () {
      final logs = [
        createWeight(
          id: 'morning',
          kg: 66.5,
          date: DateTime(2026, 11, 9, 8, 0),
        ),
        createWeight(
          id: 'evening',
          kg: 66.1,
          date: DateTime(2026, 11, 9, 19, 0),
        ),
      ];

      final result = service.calculate(
        weightLogs: logs,
        startDate: DateTime(2026, 11, 9),
        endDate: DateTime(2026, 11, 9),
      );

      expect(result.points.length, 1);
      expect(result.points.first.weightKg, 66.1);
    });

    test('filters invalid weight values', () {
      final logs = [
        createWeight(
          id: 'invalid',
          kg: double.nan,
          date: DateTime(2026, 11, 1),
        ),
        createWeight(id: 'tooHigh', kg: 600, date: DateTime(2026, 11, 2)),
        createWeight(id: 'valid', kg: 65.5, date: DateTime(2026, 11, 3)),
      ];

      final result = service.calculate(
        weightLogs: logs,
        startDate: DateTime(2026, 11, 1),
        endDate: DateTime(2026, 11, 9),
      );

      expect(result.points.length, 1);
      expect(result.latestWeight, 65.5);
    });

    test('rejects invalid date range', () {
      expect(
        () => service.calculate(
          weightLogs: [],
          startDate: DateTime(2026, 11, 10),
          endDate: DateTime(2026, 11, 1),
        ),
        throwsArgumentError,
      );
    });

    test('supports single-day date range', () {
      final logs = [
        createWeight(id: 'today', kg: 65.5, date: DateTime(2026, 11, 9, 10, 0)),
      ];

      final result = service.calculate(
        weightLogs: logs,
        startDate: DateTime(2026, 11, 9),
        endDate: DateTime(2026, 11, 9),
      );

      expect(result.points.length, 1);
      expect(result.latestWeight, 65.5);
    });
  });
}
