import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:nutriguard_app/features/exercise/data/models/exercise_log_model.dart';
import 'package:nutriguard_app/features/exercise/data/repositories/exercise_log_repository.dart';
import 'package:nutriguard_app/features/progress/presentation/widgets/exercise_completion_section.dart';

class MockExerciseLogRepository extends Mock implements ExerciseLogRepository {}

void main() {
  late MockExerciseLogRepository repository;

  final startDate = DateTime(2026, 11, 1);
  final endDate = DateTime(2026, 11, 9);

  ExerciseLogModel createExercise({
    required String id,
    required bool completed,
    int duration = 30,
    DateTime? date,
  }) {
    return ExerciseLogModel(
      id: id,
      exerciseName: 'Walking',
      exerciseType: 'Cardio',
      durationMinutes: duration,
      isCompleted: completed,
      performedAt: date ?? DateTime(2026, 11, 9),
    );
  }

  Widget buildTestWidget({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ExerciseCompletionSection(
            startDate: startDate,
            endDate: endDate,
            repository: repository,
          ),
        ),
      ),
    );
  }

  void stubExercises(List<ExerciseLogModel> logs) {
    when(
      () => repository.getExerciseLogsForRange(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      ),
    ).thenAnswer((_) async => logs);
  }

  setUpAll(() {
    registerFallbackValue(DateTime(2026, 1, 1));
  });

  setUp(() {
    repository = MockExerciseLogRepository();
  });

  group('ExerciseCompletionSection', () {
    testWidgets('displays section heading', (tester) async {
      stubExercises([]);

      await tester.pumpWidget(
        buildTestWidget(startDate: startDate, endDate: endDate),
      );

      await tester.pumpAndSettle();

      expect(find.text('Exercise Completion'), findsOneWidget);
    });

    testWidgets('shows empty state when no records exist', (tester) async {
      stubExercises([]);

      await tester.pumpWidget(
        buildTestWidget(startDate: startDate, endDate: endDate),
      );

      await tester.pumpAndSettle();

      expect(find.text('No exercise records for this period.'), findsOneWidget);
    });

    testWidgets('displays correct completion statistics', (tester) async {
      stubExercises([
        createExercise(id: '1', completed: true, duration: 30),
        createExercise(id: '2', completed: false, duration: 45),
      ]);

      await tester.pumpWidget(
        buildTestWidget(startDate: startDate, endDate: endDate),
      );

      await tester.pumpAndSettle();

      expect(find.text('Recorded Exercise Completion'), findsOneWidget);

      expect(find.text('50.0%'), findsOneWidget);
      expect(find.text('1 of 2 completed'), findsOneWidget);
      expect(find.text('30 min'), findsOneWidget);
      expect(find.text('Completed Minutes'), findsOneWidget);
      expect(find.text('Planned / Incomplete'), findsOneWidget);

      final progress = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );

      expect(progress.value, 0.5);
    });

    testWidgets('refresh button reloads exercise statistics', (tester) async {
      stubExercises([]);

      await tester.pumpWidget(
        buildTestWidget(startDate: startDate, endDate: endDate),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Refresh exercise statistics'));

      await tester.pumpAndSettle();

      verify(
        () => repository.getExerciseLogsForRange(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).called(2);
    });

    testWidgets('reloads when selected date range changes', (tester) async {
      stubExercises([]);

      await tester.pumpWidget(
        buildTestWidget(startDate: startDate, endDate: endDate),
      );

      await tester.pumpAndSettle();

      final newStart = DateTime(2026, 6, 1);

      await tester.pumpWidget(
        buildTestWidget(startDate: newStart, endDate: endDate),
      );

      await tester.pumpAndSettle();

      verify(
        () => repository.getExerciseLogsForRange(
          startDate: startDate,
          endDate: endDate,
        ),
      ).called(1);

      verify(
        () => repository.getExerciseLogsForRange(
          startDate: newStart,
          endDate: endDate,
        ),
      ).called(1);
    });

    testWidgets('shows loading indicator while fetching data', (tester) async {
      final completer = Completer<List<ExerciseLogModel>>();

      when(
        () => repository.getExerciseLogsForRange(
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

      expect(find.text('No exercise records for this period.'), findsOneWidget);
    });

    testWidgets('shows error and retries successfully', (tester) async {
      var callCount = 0;

      when(
        () => repository.getExerciseLogsForRange(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenAnswer((_) async {
        callCount++;

        if (callCount == 1) {
          throw Exception('Firestore unavailable');
        }

        return [createExercise(id: '1', completed: true, duration: 30)];
      });

      await tester.pumpWidget(
        buildTestWidget(startDate: startDate, endDate: endDate),
      );

      await tester.pumpAndSettle();

      expect(find.text('Unable to load exercise statistics.'), findsOneWidget);

      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));

      await tester.pumpAndSettle();

      expect(find.text('100.0%'), findsOneWidget);
      expect(find.text('1 of 1 completed'), findsOneWidget);
      expect(callCount, 2);
    });
  });
}
