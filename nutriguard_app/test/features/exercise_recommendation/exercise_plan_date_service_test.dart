import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/exercise_recommendation/domain/services/exercise_plan_date_service.dart';

void main() {
  const service = ExercisePlanDateService();

  group('ExercisePlanDateService', () {
    test('returns Monday of the current week', () {
      final result = service.dateForWeekday(
        referenceDate: DateTime(2026, 11, 11),
        weekday: DateTime.monday,
      );

      expect(result, DateTime(2026, 11, 9));
    });

    test('returns Wednesday of the current week', () {
      final result = service.dateForWeekday(
        referenceDate: DateTime(2026, 11, 9),
        weekday: DateTime.wednesday,
      );

      expect(result, DateTime(2026, 11, 11));
    });

    test('returns Sunday of the current week', () {
      final result = service.dateForWeekday(
        referenceDate: DateTime(2026, 11, 9),
        weekday: DateTime.sunday,
      );

      expect(result, DateTime(2026, 11, 15));
    });

    test('handles a week crossing two months', () {
      final result = service.dateForWeekday(
        referenceDate: DateTime(2026, 12, 1),
        weekday: DateTime.monday,
      );

      expect(result, DateTime(2026, 11, 30));
    });

    test('removes time information', () {
      final result = service.dateForWeekday(
        referenceDate: DateTime(2026, 11, 11, 18, 45),
        weekday: DateTime.wednesday,
      );

      expect(result, DateTime(2026, 11, 11));
      expect(result.hour, 0);
      expect(result.minute, 0);
    });

    test('rejects invalid weekdays', () {
      expect(
        () => service.dateForWeekday(
          referenceDate: DateTime(2026, 11, 9),
          weekday: 0,
        ),
        throwsArgumentError,
      );

      expect(
        () => service.dateForWeekday(
          referenceDate: DateTime(2026, 11, 9),
          weekday: 8,
        ),
        throwsArgumentError,
      );
    });
  });
}
