import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/exercise_recommendation/domain/services/exercise_recommendation_service.dart';
import 'package:nutriguard_app/features/exercise_recommendation/domain/services/exercise_swap_service.dart';
import 'package:nutriguard_app/features/exercise_recommendation/domain/services/weekly_exercise_schedule_service.dart';
import 'package:nutriguard_app/features/exercise_recommendation/presentation/widgets/exercise_swap_action.dart';

void main() {
  const scheduleService = WeeklyExerciseScheduleService();
  const swapService = ExerciseSwapService();

  const request = ExerciseRecommendationRequest(
    goal: FitnessGoal.generalFitness,
    activityLevel: ActivityLevel.beginner,
  );

  WeeklyExerciseSchedule makeSchedule() {
    return scheduleService.generate(request: request);
  }

  Widget buildTestApp({
    required WeeklyExerciseSchedule schedule,
    required int weekday,
    ValueChanged<WeeklyExerciseSchedule>? onSwap,
  }) {
    var currentSchedule = schedule;

    return MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  Text(
                    currentSchedule.forWeekday(weekday).exercise?.name ??
                        'Rest Day',
                  ),
                  Text('Minutes: ${currentSchedule.plannedMinutes}'),
                  ExerciseSwapAction(
                    schedule: currentSchedule,
                    weekday: weekday,
                    request: request,
                    onSwapped: (updated) {
                      setState(() {
                        currentSchedule = updated;
                      });
                      onSwap?.call(updated);
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> openSwapSheet(WidgetTester tester) async {
    final button = find.byKey(const ValueKey('swap-exercise-1'));

    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  group('ExerciseSwapAction', () {
    testWidgets('shows Swap Exercise button on exercise day', (tester) async {
      await tester.pumpWidget(
        buildTestApp(schedule: makeSchedule(), weekday: 1),
      );

      expect(find.byKey(const ValueKey('swap-exercise-1')), findsOneWidget);
    });

    testWidgets('hides Swap Exercise button on Sunday', (tester) async {
      await tester.pumpWidget(
        buildTestApp(schedule: makeSchedule(), weekday: DateTime.sunday),
      );

      expect(find.text('Rest Day'), findsOneWidget);

      expect(find.byKey(const ValueKey('swap-exercise-7')), findsNothing);
    });

    testWidgets('opens alternatives bottom sheet', (tester) async {
      final schedule = makeSchedule();

      await tester.pumpWidget(buildTestApp(schedule: schedule, weekday: 1));

      await openSwapSheet(tester);

      expect(
        find.text('Select an alternative exercise for this day.'),
        findsOneWidget,
      );

      final alternatives = swapService.getAlternatives(
        schedule: schedule,
        weekday: 1,
        request: request,
      );

      expect(alternatives, isNotEmpty);

      expect(find.text(alternatives.first.name), findsOneWidget);
    });

    testWidgets('swaps exercise and updates planned minutes', (tester) async {
      final schedule = makeSchedule();
      WeeklyExerciseSchedule? updatedSchedule;

      final oldExercise = schedule.forWeekday(1).exercise!;

      final replacement = swapService
          .getAlternatives(schedule: schedule, weekday: 1, request: request)
          .first;

      await tester.pumpWidget(
        buildTestApp(
          schedule: schedule,
          weekday: 1,
          onSwap: (updated) {
            updatedSchedule = updated;
          },
        ),
      );

      await openSwapSheet(tester);

      final replacementFinder = find.text(replacement.name);

      await tester.ensureVisible(replacementFinder);
      await tester.tap(replacementFinder);
      await tester.pumpAndSettle();

      expect(updatedSchedule, isNotNull);

      expect(updatedSchedule!.forWeekday(1).exercise!.id, replacement.id);

      final expectedMinutes =
          schedule.plannedMinutes -
          oldExercise.durationMinutes +
          replacement.durationMinutes;

      expect(updatedSchedule!.plannedMinutes, expectedMinutes);

      expect(find.text('Minutes: $expectedMinutes'), findsOneWidget);
    });

    testWidgets('closing sheet does not change exercise', (tester) async {
      final schedule = makeSchedule();
      var swapCount = 0;

      await tester.pumpWidget(
        buildTestApp(
          schedule: schedule,
          weekday: 1,
          onSwap: (_) {
            swapCount++;
          },
        ),
      );

      await openSwapSheet(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(swapCount, 0);

      expect(find.text(schedule.forWeekday(1).exercise!.name), findsOneWidget);

      expect(find.text('Minutes: ${schedule.plannedMinutes}'), findsOneWidget);
    });
  });
}
