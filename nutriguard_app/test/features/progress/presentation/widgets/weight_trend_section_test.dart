import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:nutriguard_app/features/weight/data/models/weight_log_model.dart';
import 'package:nutriguard_app/features/weight/data/repositories/weight_log_repository.dart';
import 'package:nutriguard_app/features/progress/presentation/widgets/weight_trend_section.dart';

class MockWeightLogRepository extends Mock implements WeightLogRepository {}

void main() {
  late MockWeightLogRepository repository;

  final startDate = DateTime(2026, 11, 1);
  final endDate = DateTime(2026, 11, 9);

  WeightLogModel createWeight({
    required String id,
    required double kg,
    required DateTime date,
  }) {
    return WeightLogModel(id: id, weightKg: kg, measuredAt: date);
  }

  Widget buildTestWidget({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: WeightTrendSection(
            startDate: startDate,
            endDate: endDate,
            repository: repository,
          ),
        ),
      ),
    );
  }

  void stubWeights(List<WeightLogModel> logs) {
    when(
      () => repository.getWeightLogsForRange(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      ),
    ).thenAnswer((_) async => logs);
  }

  setUpAll(() {
    registerFallbackValue(DateTime(2026, 1, 1));
  });

  setUp(() {
    repository = MockWeightLogRepository();
  });

  group('WeightTrendSection', () {
    testWidgets('displays Weight Tracking heading', (tester) async {
      stubWeights([]);

      await tester.pumpWidget(
        buildTestWidget(startDate: startDate, endDate: endDate),
      );

      await tester.pumpAndSettle();

      expect(find.text('Weight Tracking'), findsOneWidget);
    });

    testWidgets('shows empty state without measurements', (tester) async {
      stubWeights([]);

      await tester.pumpWidget(
        buildTestWidget(startDate: startDate, endDate: endDate),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('No weight measurements for this period.'),
        findsOneWidget,
      );
    });

    testWidgets('displays saved weight measurement', (tester) async {
      stubWeights([
        createWeight(id: 'weight_001', kg: 65.5, date: DateTime(2026, 11, 9)),
      ]);

      await tester.pumpWidget(
        buildTestWidget(startDate: startDate, endDate: endDate),
      );

      await tester.pumpAndSettle();

      expect(find.text('Weight Trend'), findsOneWidget);

      expect(find.text('65.5 kg'), findsOneWidget);

      expect(find.text('Not enough data'), findsOneWidget);
    });

    testWidgets('calculates weight change from records', (tester) async {
      stubWeights([
        createWeight(id: 'weight_002', kg: 65.5, date: DateTime(2026, 11, 9)),
        createWeight(id: 'weight_001', kg: 67.0, date: DateTime(2026, 11, 1)),
      ]);

      await tester.pumpWidget(
        buildTestWidget(startDate: startDate, endDate: endDate),
      );

      await tester.pumpAndSettle();

      expect(find.text('65.5 kg'), findsOneWidget);
      expect(find.text('-1.5 kg'), findsOneWidget);
      expect(find.text('Latest Weight'), findsOneWidget);
      expect(find.text('Weight Change'), findsOneWidget);
    });

    testWidgets('refresh button reloads weight records', (tester) async {
      stubWeights([]);

      await tester.pumpWidget(
        buildTestWidget(startDate: startDate, endDate: endDate),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Refresh weight trend'));

      await tester.pumpAndSettle();

      verify(
        () => repository.getWeightLogsForRange(
          startDate: startDate,
          endDate: endDate,
        ),
      ).called(2);
    });

    testWidgets('reloads on selected period change', (tester) async {
      stubWeights([]);

      await tester.pumpWidget(
        buildTestWidget(startDate: startDate, endDate: endDate),
      );

      await tester.pumpAndSettle();

      final sixMonthsStart = DateTime(2026, 6, 1);

      await tester.pumpWidget(
        buildTestWidget(startDate: sixMonthsStart, endDate: endDate),
      );

      await tester.pumpAndSettle();

      verify(
        () => repository.getWeightLogsForRange(
          startDate: startDate,
          endDate: endDate,
        ),
      ).called(1);

      verify(
        () => repository.getWeightLogsForRange(
          startDate: sixMonthsStart,
          endDate: endDate,
        ),
      ).called(1);
    });

    testWidgets('shows loading indicator while fetching', (tester) async {
      final completer = Completer<List<WeightLogModel>>();

      when(
        () => repository.getWeightLogsForRange(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenAnswer((_) => completer.future);

      await tester.pumpWidget(
        buildTestWidget(startDate: startDate, endDate: endDate),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete([]);

      await tester.pumpAndSettle();

      expect(
        find.text('No weight measurements for this period.'),
        findsOneWidget,
      );
    });

    testWidgets('shows error and retries successfully', (tester) async {
      var callCount = 0;

      when(
        () => repository.getWeightLogsForRange(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenAnswer((_) async {
        callCount++;

        if (callCount == 1) {
          throw Exception('Firestore unavailable');
        }

        return [
          createWeight(id: 'weight_001', kg: 65.5, date: DateTime(2026, 11, 9)),
        ];
      });

      await tester.pumpWidget(
        buildTestWidget(startDate: startDate, endDate: endDate),
      );

      await tester.pumpAndSettle();

      expect(find.text('Unable to load weight history.'), findsOneWidget);

      await tester.tap(find.text('Try Again'));

      await tester.pumpAndSettle();

      expect(find.text('65.5 kg'), findsOneWidget);
      expect(callCount, 2);
    });
  });
}
