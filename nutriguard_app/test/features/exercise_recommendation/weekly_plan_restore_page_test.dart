import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/exercise_recommendation/data/models/saved_weekly_exercise_plan.dart';
import 'package:nutriguard_app/features/exercise_recommendation/domain/services/exercise_recommendation_service.dart';
import 'package:nutriguard_app/features/exercise_recommendation/domain/services/weekly_exercise_schedule_service.dart';
import 'package:nutriguard_app/features/exercise_recommendation/presentation/pages/exercise_recommendation_page.dart';

void main() {
  const scheduleService = WeeklyExerciseScheduleService();

  const request = ExerciseRecommendationRequest(
    goal: FitnessGoal.buildStrength,
    activityLevel: ActivityLevel.intermediate,
    preference: ExercisePreference.strength,
  );

  SavedWeeklyExercisePlan makeSavedPlan() {
    final schedule = scheduleService.generate(request: request);

    return SavedWeeklyExercisePlan.fromSchedule(
      referenceDate: DateTime.now(),
      request: request,
      schedule: schedule,
    );
  }

  Widget buildApp(Future<SavedWeeklyExercisePlan?> Function(DateTime) loader) {
    return MaterialApp(home: ExerciseRecommendationPage(planLoader: loader));
  }

  group('Weekly Plan Restore UI', () {
    testWidgets('restores saved schedule and statistics', (tester) async {
      final savedPlan = makeSavedPlan();

      await tester.pumpWidget(buildApp((_) async => savedPlan));

      await tester.pumpAndSettle();

      expect(find.text('Regenerate Week Schedule'), findsOneWidget);

      expect(find.text('Planned Sessions'), findsOneWidget);

      expect(find.text('${savedPlan.schedule.plannedMinutes}'), findsOneWidget);

      expect(find.text('Build Strength'), findsOneWidget);
    });

    testWidgets('shows generator when no saved plan exists', (tester) async {
      await tester.pumpWidget(buildApp((_) async => null));

      await tester.pumpAndSettle();

      expect(find.text('Generate Week Schedule'), findsOneWidget);

      expect(find.text('Planned Sessions'), findsNothing);
    });

    testWidgets('does not overwrite user changes during loading', (
      tester,
    ) async {
      final completer = Completer<SavedWeeklyExercisePlan?>();

      await tester.pumpWidget(buildApp((_) => completer.future));

      await tester.pump();

      expect(find.text('Restoring saved weekly plan...'), findsOneWidget);

      final intermediate = find.byKey(const ValueKey('level-intermediate'));

      await tester.ensureVisible(intermediate);
      await tester.tap(intermediate);
      await tester.pump();

      completer.complete(makeSavedPlan());

      await tester.pumpAndSettle();

      expect(find.text('Generate Week Schedule'), findsOneWidget);

      expect(find.text('Planned Sessions'), findsNothing);

      expect(tester.takeException(), isNull);
    });
  });
}
