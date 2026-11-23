import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/progress/domain/services/weight_trend_service.dart';
import 'package:nutriguard_app/features/progress/presentation/widgets/weight_trend_chart.dart';

void main() {
  WeightTrendPoint point(int day, double weightKg) {
    return WeightTrendPoint(date: DateTime(2026, 11, day), weightKg: weightKg);
  }

  Widget buildTestWidget(WeightTrendResult result) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: WeightTrendChart(result: result)),
      ),
    );
  }

  group('WeightTrendChart', () {
    testWidgets('displays chart title and description', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const WeightTrendResult(points: [])),
      );

      expect(find.text('Weight Trend'), findsOneWidget);

      expect(find.text('Recorded body weight (kg)'), findsOneWidget);
    });

    testWidgets('shows empty state when no records exist', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const WeightTrendResult(points: [])),
      );

      expect(
        find.text('No weight measurements for this period.'),
        findsOneWidget,
      );

      expect(find.text('Latest Weight'), findsNothing);
    });

    testWidgets('displays latest weight correctly', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          WeightTrendResult(points: [point(1, 67.0), point(9, 65.5)]),
        ),
      );

      expect(find.text('Latest Weight'), findsOneWidget);

      expect(find.text('65.5 kg'), findsOneWidget);
    });

    testWidgets('displays negative weight change', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          WeightTrendResult(points: [point(1, 67.0), point(9, 65.5)]),
        ),
      );

      expect(find.text('Weight Change'), findsOneWidget);

      expect(find.text('-1.5 kg'), findsOneWidget);
    });

    testWidgets('displays positive weight change', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          WeightTrendResult(points: [point(1, 60.0), point(9, 62.5)]),
        ),
      );

      expect(find.text('+2.5 kg'), findsOneWidget);
    });

    testWidgets('handles a single measurement', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(WeightTrendResult(points: [point(9, 65.5)])),
      );

      expect(find.text('65.5 kg'), findsOneWidget);

      expect(find.text('Not enough data'), findsOneWidget);

      expect(
        find.text('1 recorded day(s) in the selected period.'),
        findsOneWidget,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders multiple weight records safely', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          WeightTrendResult(
            points: [
              point(1, 67.0),
              point(3, 66.5),
              point(5, 66.2),
              point(9, 65.5),
            ],
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);

      expect(
        find.text('4 recorded day(s) in the selected period.'),
        findsOneWidget,
      );

      expect(find.text('2026-11-01'), findsOneWidget);

      expect(find.text('2026-11-09'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  });
}
