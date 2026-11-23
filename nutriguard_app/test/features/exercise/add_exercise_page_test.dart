import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:nutriguard_app/features/exercise/presentation/pages/add_exercise_page.dart';
import 'package:nutriguard_app/features/exercise/data/models/exercise_log_model.dart';
import 'package:nutriguard_app/features/exercise/data/repositories/exercise_log_repository.dart';

class MockExerciseLogRepository extends Mock implements ExerciseLogRepository {}

class FakeExerciseLogModel extends Fake implements ExerciseLogModel {}

void main() {
  late MockExerciseLogRepository repository;

  setUpAll(() {
    registerFallbackValue(FakeExerciseLogModel());
  });

  setUp(() {
    repository = MockExerciseLogRepository();

    when(() => repository.addExercise(any()))
        .thenAnswer((_) async => 'exercise-1');
  });

  Future<void> pumpAddExercisePage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: AddExercisePage(repository: repository)),
    );
  }

  group('AddExercisePage validation', () {
    testWidgets('shows validation error for empty exercise name', (
      tester,
    ) async {
      await pumpAddExercisePage(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Exercise Name'),
        '',
      );

      await tester.ensureVisible(find.text('Save Exercise'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Save Exercise'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Exercise'));
      await tester.pumpAndSettle();

      expect(find.text('Enter an exercise name.'), findsOneWidget);
      verifyNever(() => repository.addExercise(any()));
    });

    testWidgets('shows validation error for invalid duration', (tester) async {
      await pumpAddExercisePage(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Exercise Name'),
        'Walking',
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Duration (minutes)'),
        'abc',
      );

      await tester.ensureVisible(find.text('Save Exercise'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Exercise'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid number of minutes.'), findsOneWidget);

      verifyNever(() => repository.addExercise(any()));
    });

    testWidgets('rejects duration above 1440 minutes', (tester) async {
      await pumpAddExercisePage(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Exercise Name'),
        'Walking',
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Duration (minutes)'),
        '1441',
      );

      await tester.ensureVisible(find.text('Save Exercise'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Exercise'));
      await tester.pumpAndSettle();

      expect(find.text('Duration must be between 0 and 1440.'), findsOneWidget);

      verifyNever(() => repository.addExercise(any()));
    });

    testWidgets('shows saving indicator while saving', (tester) async {
      final completer = Completer<String>();

      when(() => repository.addExercise(any()))
          .thenAnswer((_) => completer.future);

      await pumpAddExercisePage(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Exercise Name'),
        'Walking',
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Duration (minutes)'),
        '30',
      );

      await tester.ensureVisible(find.text('Save Exercise'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Exercise'));

      // Process the save operation without waiting for animations to settle.
      await tester.pump();

      expect(find.text('Saving...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete the pending save operation.
      completer.complete('exercise-1');

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('prevents marking a future exercise as completed', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AddExercisePage(
            repository: repository,
            initialExerciseName: 'Walking',
            initialDurationMinutes: 30,
            initialDate: DateTime.now().add(const Duration(days: 1)),
            initialIsCompleted: true,
          ),
        ),
      );

      await tester.ensureVisible(find.text('Save Exercise'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Exercise'));
      await tester.pumpAndSettle();

      expect(
        find.text('A completed exercise cannot have a future date.'),
        findsOneWidget,
      );

      verifyNever(() => repository.addExercise(any()));
    });

    testWidgets('shows error message when saving fails', (tester) async {
      when(() => repository.addExercise(any()))
          .thenThrow(Exception('Save failed'));

      await pumpAddExercisePage(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Exercise Name'),
        'Walking',
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Duration (minutes)'),
        '30',
      );

      await tester.ensureVisible(find.text('Save Exercise'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Exercise'));
      await tester.pumpAndSettle();

      expect(
        find.text('Unable to save exercise. Please try again.'),
        findsOneWidget,
      );
    });
  });
}
