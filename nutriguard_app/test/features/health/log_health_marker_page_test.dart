import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:nutriguard_app/features/health/data/models/monthly_health_marker_model.dart';
import 'package:nutriguard_app/features/health/data/repositories/monthly_health_marker_repository.dart';
import 'package:nutriguard_app/features/health/presentation/pages/log_health_marker_page.dart';

class MockMonthlyHealthMarkerRepository extends Mock
    implements MonthlyHealthMarkerRepository {}

class FakeMonthlyHealthMarkerModel extends Fake
    implements MonthlyHealthMarkerModel {}

void main() {
  late MockMonthlyHealthMarkerRepository repository;

  setUpAll(() {
    registerFallbackValue(FakeMonthlyHealthMarkerModel());
  });

  setUp(() {
    repository = MockMonthlyHealthMarkerRepository();

    when(() => repository.saveMarkers(any())).thenAnswer((_) async {});
  });

  Future<void> pumpLogHealthMarkerPage(
    WidgetTester tester, {
    DateTime? selectedMonth,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LogHealthMarkerPage(
          repository: repository,
          selectedMonth: selectedMonth,
        ),
      ),
    );
  }

  testWidgets('shows error when no measurements are entered', (tester) async {
    await pumpLogHealthMarkerPage(tester);

    await tester.ensureVisible(find.text("Save This Month's Markers"));
    await tester.tap(find.text("Save This Month's Markers"));
    await tester.pump();

    expect(find.text('Enter at least one measurement.'), findsOneWidget);

    verifyNever(() => repository.saveMarkers(any()));
  });

  testWidgets('rejects invalid measurement values', (tester) async {
    await pumpLogHealthMarkerPage(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Total Cholesterol'),
      'abc',
    );

    await tester.ensureVisible(find.text("Save This Month's Markers"));
    await tester.tap(find.text("Save This Month's Markers"));
    await tester.pump();

    expect(find.text('Enter a valid positive number'), findsOneWidget);

    verifyNever(() => repository.saveMarkers(any()));
  });

  testWidgets('requires both systolic and diastolic values', (tester) async {
    await pumpLogHealthMarkerPage(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Systolic'),
      '120',
    );

    await tester.ensureVisible(find.text("Save This Month's Markers"));

    await tester.tap(find.text("Save This Month's Markers"));
    await tester.pump();

    expect(
      find.text('Enter both systolic and diastolic pressure.'),
      findsOneWidget,
    );

    verifyNever(() => repository.saveMarkers(any()));
  });

  testWidgets('saves valid health markers successfully', (tester) async {
    await pumpLogHealthMarkerPage(tester, selectedMonth: DateTime(2026, 10));

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Total Cholesterol'),
      '185',
    );

    await tester.ensureVisible(find.text("Save This Month's Markers"));

    await tester.tap(find.text("Save This Month's Markers"));
    await tester.pumpAndSettle();

    verify(
      () => repository.saveMarkers(
        any(
          that: isA<MonthlyHealthMarkerModel>()
              .having((m) => m.month, 'month', '2026-10')
              .having((m) => m.measurements.length, 'measurement count', 1)
              .having(
                (m) => m.measurements.first.name,
                'measurement name',
                'Total Cholesterol',
              )
              .having(
                (m) => m.measurements.first.value,
                'measurement value',
                185,
              ),
        ),
      ),
    ).called(1);

    expect(find.text('Log Health Markers'), findsNothing);
  });

  testWidgets('shows error when saving health markers fails', (tester) async {
    when(() => repository.saveMarkers(any()))
        .thenThrow(Exception('Network error'));

    await pumpLogHealthMarkerPage(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Total Cholesterol'),
      '185',
    );

    await tester.ensureVisible(find.text("Save This Month's Markers"));

    await tester.tap(find.text("Save This Month's Markers"));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(
      find.text(
        'Unable to save health markers. Check your connection and try again.',
      ),
      findsOneWidget,
    );

    expect(find.text('Log Health Markers'), findsOneWidget);
  });

  testWidgets('shows loading indicator while saving', (tester) async {
    final completer = Completer<void>();

    when(() => repository.saveMarkers(any()))
        .thenAnswer((_) => completer.future);

    await pumpLogHealthMarkerPage(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Total Cholesterol'),
      '185',
    );

    await tester.ensureVisible(find.text("Save This Month's Markers"));

    await tester.tap(find.text("Save This Month's Markers"));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete();

    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
