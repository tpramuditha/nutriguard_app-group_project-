import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/exercise_recommendation/presentation/pages/exercise_recommendation_page.dart';

void main() {
  Widget buildTestApp() {
    return const MaterialApp(home: ExerciseRecommendationPage());
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();

    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> generateSchedule(WidgetTester tester) async {
    await tapVisible(tester, find.text('Generate Week Schedule'));
  }

  group('Weekly Exercise Plan UI', () {
    testWidgets('shows weekly plan controls', (tester) async {
      await tester.pumpWidget(buildTestApp());

      expect(find.text('Weekly Exercise Plan'), findsOneWidget);

      expect(find.text('Generate Week Schedule'), findsOneWidget);

      expect(find.byKey(const ValueKey('exercise-day-0')), findsOneWidget);

      expect(find.byKey(const ValueKey('exercise-day-6')), findsOneWidget);
    });

    testWidgets('generates a weekly schedule', (tester) async {
      await tester.pumpWidget(buildTestApp());

      await generateSchedule(tester);

      expect(find.text('Regenerate Week Schedule'), findsOneWidget);

      expect(find.text('Planned Sessions'), findsOneWidget);

      expect(find.text('Planned Minutes'), findsOneWidget);

      expect(find.text('6'), findsOneWidget);
    });

    testWidgets('displays Monday exercise', (tester) async {
      await tester.pumpWidget(buildTestApp());

      await generateSchedule(tester);

      await tapVisible(tester, find.byKey(const ValueKey('exercise-day-0')));

      expect(find.text('Monday Plan'), findsOneWidget);

      expect(find.text('Rest Day'), findsNothing);

      expect(find.text('Easy Cycling'), findsOneWidget);
    });

    testWidgets('displays Sunday as a rest day', (tester) async {
      await tester.pumpWidget(buildTestApp());

      await generateSchedule(tester);

      await tapVisible(tester, find.byKey(const ValueKey('exercise-day-6')));

      expect(find.text('Sunday Plan'), findsOneWidget);

      expect(find.text('Rest Day'), findsOneWidget);
    });

    testWidgets('switches between days', (tester) async {
      await tester.pumpWidget(buildTestApp());

      await generateSchedule(tester);

      await tapVisible(tester, find.byKey(const ValueKey('exercise-day-2')));

      expect(find.text('Wednesday Plan'), findsOneWidget);

      await tapVisible(tester, find.byKey(const ValueKey('exercise-day-4')));

      expect(find.text('Friday Plan'), findsOneWidget);
    });

    testWidgets('changing activity level clears schedule', (tester) async {
      await tester.pumpWidget(buildTestApp());

      await generateSchedule(tester);

      expect(find.text('Planned Sessions'), findsOneWidget);

      await tapVisible(
        tester,
        find.byKey(const ValueKey('level-intermediate')),
      );

      expect(find.text('Generate Week Schedule'), findsOneWidget);

      expect(find.text('Planned Sessions'), findsNothing);
    });

    testWidgets('regenerates the weekly schedule', (tester) async {
      await tester.pumpWidget(buildTestApp());

      await generateSchedule(tester);

      await tapVisible(tester, find.text('Regenerate Week Schedule'));

      expect(find.text('Planned Sessions'), findsOneWidget);

      expect(find.text('Regenerate Week Schedule'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  });
}
