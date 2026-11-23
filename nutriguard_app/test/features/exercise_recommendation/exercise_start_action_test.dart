import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/app/routes/route_names.dart';
import 'package:nutriguard_app/features/exercise_recommendation/data/models/exercise_recommendation_model.dart';
import 'package:nutriguard_app/features/exercise_recommendation/presentation/widgets/exercise_start_action.dart';

void main() {
  const exercise = ExerciseRecommendationModel(
    id: 'walking',
    name: 'Walking',
    type: 'Cardio',
    intensity: 'Low',
    durationMinutes: 20,
    description: 'Walk at a comfortable pace.',
    benefits: ['Supports general fitness'],
    safetyNotes: ['Stop if you feel unwell.'],
  );

  Widget buildTestApp() {
    return MaterialApp(
      home: const Scaffold(body: ExerciseStartAction(exercise: exercise)),
      routes: {
        RouteNames.exercise: (_) => const Scaffold(
          body: Center(child: Text('Exercise Tracking Test Page')),
        ),
      },
    );
  }

  Future<void> openDialog(WidgetTester tester) async {
    await tester.tap(find.text('Start Session'));
    await tester.pumpAndSettle();
  }

  group('ExerciseStartAction', () {
    testWidgets('displays Start Session button', (tester) async {
      await tester.pumpWidget(buildTestApp());

      expect(
        find.byKey(const ValueKey('start-exercise-session')),
        findsOneWidget,
      );

      expect(find.text('Start Session'), findsOneWidget);
    });

    testWidgets('opens confirmation dialog', (tester) async {
      await tester.pumpWidget(buildTestApp());

      await openDialog(tester);

      expect(find.text('Start Exercise Session'), findsOneWidget);

      expect(find.text('Walking'), findsOneWidget);
      expect(find.text('Type: Cardio'), findsOneWidget);
      expect(find.text('Intensity: Low'), findsOneWidget);
      expect(find.text('Suggested duration: 20 minutes'), findsOneWidget);

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Open Tracking'), findsOneWidget);
    });

    testWidgets('Cancel closes dialog without navigation', (tester) async {
      await tester.pumpWidget(buildTestApp());

      await openDialog(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Start Exercise Session'), findsNothing);

      expect(find.text('Exercise Tracking Test Page'), findsNothing);

      expect(find.text('Start Session'), findsOneWidget);
    });

    testWidgets('Open Tracking navigates to exercise route', (tester) async {
      await tester.pumpWidget(buildTestApp());

      await openDialog(tester);

      await tester.tap(find.text('Open Tracking'));
      await tester.pumpAndSettle();

      expect(find.text('Exercise Tracking Test Page'), findsOneWidget);

      expect(find.text('Start Exercise Session'), findsNothing);
    });

    testWidgets('shows guidance about completion status', (tester) async {
      await tester.pumpWidget(buildTestApp());

      await openDialog(tester);

      expect(
        find.textContaining('will not automatically mark this'),
        findsOneWidget,
      );

      expect(tester.takeException(), isNull);
    });
  });
}
