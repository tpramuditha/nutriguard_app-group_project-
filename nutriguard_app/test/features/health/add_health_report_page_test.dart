import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'dart:async';

import 'package:nutriguard_app/features/health/presentation/pages/add_health_report_page.dart';
import 'package:nutriguard_app/features/health/data/models/health_report_model.dart';
import 'package:nutriguard_app/features/health/data/repositories/health_report_repository.dart';

class MockHealthReportRepository extends Mock
    implements HealthReportRepository {}

class FakeHealthReportModel extends Fake implements HealthReportModel {}

void main() {
  late MockHealthReportRepository repository;

  setUpAll(() {
    registerFallbackValue(FakeHealthReportModel());
  });

  setUp(() {
    repository = MockHealthReportRepository();

    when(() => repository.saveReport(any()))
        .thenAnswer((_) async => 'report-1');
  });

  Future<void> pumpAddHealthReportPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: AddHealthReportPage(repository: repository)),
    );
  }

  testWidgets('shows validation error when no measurements are entered', (
    tester,
  ) async {
    await pumpAddHealthReportPage(tester);

    await tester.ensureVisible(find.text('Review Report Details'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Review Report Details'));
    await tester.pumpAndSettle();

    expect(find.text('Enter at least one measurement.'), findsOneWidget);

    verifyNever(() => repository.saveReport(any()));
  });

  testWidgets('shows validation error for invalid numeric measurement', (
    tester,
  ) async {
    await pumpAddHealthReportPage(tester);

    await tester.ensureVisible(find.byType(TextFormField).first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'abc');

    await tester.ensureVisible(find.text('Review Report Details'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Review Report Details'));
    await tester.pumpAndSettle();

    expect(
      find.text('Enter a valid positive number for Total Cholesterol.'),
      findsOneWidget,
    );

    verifyNever(() => repository.saveReport(any()));
  });

  testWidgets('shows validation error when custom report name is empty', (
    tester,
  ) async {
    await pumpAddHealthReportPage(tester);

    // Select Custom Report.
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Custom Report').last);
    await tester.pumpAndSettle();

    // Leave the custom report name empty.
    await tester.ensureVisible(find.text('Review Report Details'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Review Report Details'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a custom report name.'), findsOneWidget);

    verifyNever(() => repository.saveReport(any()));
  });

  testWidgets('shows validation error for incomplete custom measurement', (
    tester,
  ) async {
    await pumpAddHealthReportPage(tester);

    // Select Custom Report.
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom Report').last);
    await tester.pumpAndSettle();

    // Enter custom report name.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Custom Report Name'),
      'Vitamin Test',
    );

    // Enter only the measurement name.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Measurement Name'),
      'Vitamin D',
    );

    await tester.ensureVisible(find.text('Review Report Details'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Review Report Details'));
    await tester.pumpAndSettle();

    expect(
      find.text('Complete the name, value, and unit for each measurement.'),
      findsOneWidget,
    );

    verifyNever(() => repository.saveReport(any()));
  });

  testWidgets('shows confirmation dialog when valid measurement is entered', (
    tester,
  ) async {
    await pumpAddHealthReportPage(tester);

    await tester.ensureVisible(find.byType(TextFormField).first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '185');

    await tester.ensureVisible(find.text('Review Report Details'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Review Report Details'));
    await tester.pumpAndSettle();

    expect(find.text('Confirm Report Details'), findsOneWidget);
    expect(
      find.textContaining('Total Cholesterol: 185.0 mg/dL'),
      findsOneWidget,
    );
    expect(find.text('Confirm & Save'), findsOneWidget);

    verifyNever(() => repository.saveReport(any()));
  });

  testWidgets('saves report when confirmation is accepted', (tester) async {
    await pumpAddHealthReportPage(tester);

    await tester.ensureVisible(find.byType(TextFormField).first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '185');

    await tester.ensureVisible(find.text('Review Report Details'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Review Report Details'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm & Save'));
    await tester.pumpAndSettle();

    verify(() => repository.saveReport(any())).called(1);

    expect(find.text('Add Health Report'), findsNothing);
  });

  testWidgets('shows error message when saving report fails', (tester) async {
    when(() => repository.saveReport(any()))
        .thenThrow(Exception('Network error'));

    await pumpAddHealthReportPage(tester);

    await tester.ensureVisible(find.byType(TextFormField).first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '185');

    await tester.ensureVisible(find.text('Review Report Details'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Review Report Details'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm & Save'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Unable to save the report. '
        'Check your connection and try again.',
      ),
      findsOneWidget,
    );

    verify(() => repository.saveReport(any())).called(1);
  });

  testWidgets('shows loading indicator while saving report', (tester) async {
    final completer = Completer<String>();

    when(() => repository.saveReport(any()))
        .thenAnswer((_) => completer.future);

    await pumpAddHealthReportPage(tester);

    await tester.ensureVisible(find.byType(TextFormField).first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '185');

    await tester.ensureVisible(find.text('Review Report Details'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Review Report Details'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm & Save'));
    await tester.pump();

    // Saving state should be active.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Complete the pending save operation.
    completer.complete('report-1');

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('prevents adding more than 10 custom measurements', (
    tester,
  ) async {
    await pumpAddHealthReportPage(tester);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Custom Report').last);
    await tester.pumpAndSettle();

    final measurementRows = find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          RegExp(r'^Measurement \d+$').hasMatch(widget.data ?? ''),
    );

    final addButton = find.text('Add Another Measurement');

    expect(measurementRows, findsOneWidget);

    // Add 9 more measurements.
    for (var i = 0; i < 9; i++) {
      await tester.ensureVisible(addButton);
      await tester.pumpAndSettle();

      await tester.tap(addButton);
      await tester.pumpAndSettle();
    }

    // There should be exactly 10 measurements.
    expect(measurementRows, findsNWidgets(10));

    // Try to add an 11th measurement.
    await tester.ensureVisible(addButton);
    await tester.pumpAndSettle();

    await tester.tap(addButton);
    await tester.pumpAndSettle();

    // Still only 10 measurements.
    expect(measurementRows, findsNWidgets(10));

    expect(
      find.text('A report can contain a maximum of 10 measurements.'),
      findsOneWidget,
    );
  });
}
