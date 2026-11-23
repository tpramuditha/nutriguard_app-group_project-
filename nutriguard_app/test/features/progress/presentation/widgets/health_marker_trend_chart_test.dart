import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/progress/domain/services/health_marker_trend_service.dart';
import 'package:nutriguard_app/features/progress/presentation/widgets/health_marker_trend_chart.dart';

void main() {
  HealthMarkerTrendPoint point({
    required String month,
    required double value,
    String name = 'Total Cholesterol',
    String unit = 'mg/dL',
  }) {
    return HealthMarkerTrendPoint(
      month: month,
      measurementName: name,
      value: value,
      unit: unit,
    );
  }

  Widget buildTestWidget(
    List<HealthMarkerTrendPoint> points, {
    String title = 'Cholesterol Trend',
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: HealthMarkerTrendChart(title: title, points: points),
        ),
      ),
    );
  }

  group('HealthMarkerTrendChart', () {
    testWidgets('displays chart title', (tester) async {
      await tester.pumpWidget(
        buildTestWidget([point(month: '2026-11', value: 180)]),
      );

      expect(find.text('Cholesterol Trend'), findsOneWidget);
    });

    testWidgets('displays measurement name and unit', (tester) async {
      await tester.pumpWidget(
        buildTestWidget([point(month: '2026-11', value: 180)]),
      );

      expect(find.text('Total Cholesterol (mg/dL)'), findsOneWidget);
    });

    testWidgets('displays measurement value and month', (tester) async {
      await tester.pumpWidget(
        buildTestWidget([point(month: '2026-11', value: 180)]),
      );

      expect(find.text('Nov 2026: 180.0 mg/dL'), findsOneWidget);
    });

    testWidgets('sorts months chronologically', (tester) async {
      await tester.pumpWidget(
        buildTestWidget([
          point(month: '2026-11', value: 180),
          point(month: '2026-09', value: 210),
          point(month: '2026-10', value: 195),
        ]),
      );

      final september = find.text('Sep 2026: 210.0 mg/dL');
      final october = find.text('Oct 2026: 195.0 mg/dL');
      final november = find.text('Nov 2026: 180.0 mg/dL');

      expect(september, findsOneWidget);
      expect(october, findsOneWidget);
      expect(november, findsOneWidget);

      final septemberPosition = tester.getTopLeft(september);
      final octoberPosition = tester.getTopLeft(october);
      final novemberPosition = tester.getTopLeft(november);

      // Wrap may place chips on different rows.
      // Compare vertical positions first, then horizontal
      // positions when both chips are on the same row.
      bool appearsBefore(Offset first, Offset second) {
        const tolerance = 1.0;

        if ((first.dy - second.dy).abs() > tolerance) {
          return first.dy < second.dy;
        }

        return first.dx < second.dx;
      }

      expect(appearsBefore(septemberPosition, octoberPosition), isTrue);

      expect(appearsBefore(octoberPosition, novemberPosition), isTrue);
    });

    testWidgets('shows empty state when no records exist', (tester) async {
      await tester.pumpWidget(buildTestWidget([]));

      expect(find.text('No health marker records available.'), findsOneWidget);
    });

    testWidgets('rejects mixed measurement types', (tester) async {
      await tester.pumpWidget(
        buildTestWidget([
          point(month: '2026-10', value: 180, name: 'Total Cholesterol'),
          point(month: '2026-11', value: 95, name: 'Fasting Blood Glucose'),
        ]),
      );

      expect(
        find.textContaining('incompatible measurement types or units'),
        findsOneWidget,
      );
    });

    testWidgets('rejects mixed measurement units', (tester) async {
      await tester.pumpWidget(
        buildTestWidget([
          point(month: '2026-10', value: 180, unit: 'mg/dL'),
          point(month: '2026-11', value: 4.6, unit: 'mmol/L'),
        ]),
      );

      expect(
        find.textContaining('incompatible measurement types or units'),
        findsOneWidget,
      );
    });

    testWidgets('renders chart without exceptions', (tester) async {
      await tester.pumpWidget(
        buildTestWidget([
          point(month: '2026-09', value: 210),
          point(month: '2026-10', value: 195),
          point(month: '2026-11', value: 180),
        ]),
      );

      expect(find.byType(CustomPaint), findsWidgets);

      expect(tester.takeException(), isNull);
    });
  });
}
