import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:nutriguard_app/features/health/data/models/health_measurement_model.dart';
import 'package:nutriguard_app/features/health/data/models/monthly_health_marker_model.dart';
import 'package:nutriguard_app/features/health/data/repositories/monthly_health_marker_repository.dart';
import 'package:nutriguard_app/features/progress/presentation/widgets/health_marker_trends_section.dart';

class MockMonthlyHealthMarkerRepository extends Mock
    implements MonthlyHealthMarkerRepository {}

void main() {
  late MockMonthlyHealthMarkerRepository repository;

  setUp(() {
    repository = MockMonthlyHealthMarkerRepository();
  });

  Widget buildTestWidget({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: HealthMarkerTrendsSection(
            startDate: startDate,
            endDate: endDate,
            repository: repository,
          ),
        ),
      ),
    );
  }

  const novemberRecord = MonthlyHealthMarkerModel(
    month: '2026-11',
    measurements: [
      HealthMeasurementModel(
        name: 'Total Cholesterol',
        value: 175,
        unit: 'mg/dL',
      ),
      HealthMeasurementModel(
        name: 'Fasting Blood Glucose',
        value: 95,
        unit: 'mg/dL',
      ),
      HealthMeasurementModel(
        name: 'Systolic Blood Pressure',
        value: 120,
        unit: 'mmHg',
      ),
      HealthMeasurementModel(
        name: 'Diastolic Blood Pressure',
        value: 80,
        unit: 'mmHg',
      ),
    ],
  );

  void stubRecords(List<MonthlyHealthMarkerModel> records) {
    when(
      () => repository.getMarkersForRange(
        startMonth: any(named: 'startMonth'),
        endMonth: any(named: 'endMonth'),
      ),
    ).thenAnswer((_) async => records);
  }

  group('HealthMarkerTrendsSection', () {
    testWidgets('displays section heading', (tester) async {
      stubRecords([]);

      await tester.pumpWidget(
        buildTestWidget(
          startDate: DateTime(2026, 11, 1),
          endDate: DateTime(2026, 11, 9),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Health Markers'), findsOneWidget);
    });

    testWidgets('shows empty state when no records exist', (tester) async {
      stubRecords([]);

      await tester.pumpWidget(
        buildTestWidget(
          startDate: DateTime(2026, 11, 1),
          endDate: DateTime(2026, 11, 9),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('No health marker records available for this period.'),
        findsOneWidget,
      );
    });

    testWidgets('renders all four health marker charts', (tester) async {
      stubRecords([novemberRecord]);

      await tester.pumpWidget(
        buildTestWidget(
          startDate: DateTime(2026, 11, 1),
          endDate: DateTime(2026, 11, 9),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Total Cholesterol Trend'), findsOneWidget);

      expect(find.text('Fasting Blood Glucose Trend'), findsOneWidget);

      expect(find.text('Systolic Blood Pressure Trend'), findsOneWidget);

      expect(find.text('Diastolic Blood Pressure Trend'), findsOneWidget);
    });

    testWidgets('displays saved measurement values', (tester) async {
      stubRecords([novemberRecord]);

      await tester.pumpWidget(
        buildTestWidget(
          startDate: DateTime(2026, 11, 1),
          endDate: DateTime(2026, 11, 9),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Nov 2026: 175.0 mg/dL'), findsOneWidget);

      expect(find.text('Nov 2026: 95.0 mg/dL'), findsOneWidget);

      expect(find.text('Nov 2026: 120.0 mmHg'), findsOneWidget);

      expect(find.text('Nov 2026: 80.0 mmHg'), findsOneWidget);
    });

    testWidgets('refresh button reloads health records', (tester) async {
      stubRecords([]);

      await tester.pumpWidget(
        buildTestWidget(
          startDate: DateTime(2026, 11, 1),
          endDate: DateTime(2026, 11, 9),
        ),
      );

      await tester.pumpAndSettle();

      verify(
        () => repository.getMarkersForRange(
          startMonth: any(named: 'startMonth'),
          endMonth: any(named: 'endMonth'),
        ),
      ).called(1);

      await tester.tap(find.byTooltip('Refresh health markers'));

      await tester.pumpAndSettle();

      verify(
        () => repository.getMarkersForRange(
          startMonth: any(named: 'startMonth'),
          endMonth: any(named: 'endMonth'),
        ),
      ).called(1);
    });

    testWidgets('reloads when selected period changes', (tester) async {
      stubRecords([]);

      await tester.pumpWidget(
        buildTestWidget(
          startDate: DateTime(2026, 11, 1),
          endDate: DateTime(2026, 11, 9),
        ),
      );

      await tester.pumpAndSettle();

      await tester.pumpWidget(
        buildTestWidget(
          startDate: DateTime(2026, 6, 1),
          endDate: DateTime(2026, 11, 9),
        ),
      );

      await tester.pumpAndSettle();

      verify(
        () => repository.getMarkersForRange(
          startMonth: any(named: 'startMonth'),
          endMonth: any(named: 'endMonth'),
        ),
      ).called(2);
    });

    testWidgets('shows error message when repository fails', (tester) async {
      when(
        () => repository.getMarkersForRange(
          startMonth: any(named: 'startMonth'),
          endMonth: any(named: 'endMonth'),
        ),
      ).thenAnswer((_) async => throw Exception('Firebase unavailable'));

      await tester.pumpWidget(
        buildTestWidget(
          startDate: DateTime(2026, 11, 1),
          endDate: DateTime(2026, 11, 9),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Unable to load health marker history.'),
        findsOneWidget,
      );

      expect(find.text('Try Again'), findsOneWidget);
    });
  });
}
