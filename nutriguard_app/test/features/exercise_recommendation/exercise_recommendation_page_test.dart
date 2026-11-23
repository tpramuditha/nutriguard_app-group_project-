import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/exercise_recommendation/presentation/pages/exercise_recommendation_page.dart';
import 'package:nutriguard_app/features/exercise_recommendation/domain/services/exercise_recommendation_service.dart';

void main() {
  Widget buildTestWidget() {
    return const MaterialApp(home: ExerciseRecommendationPage());
  }

  Future<void> generateRecommendations(WidgetTester tester) async {
    final button = find.text('Get Recommendations');

    await tester.ensureVisible(button);
    await tester.pumpAndSettle();

    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  group('ExerciseRecommendationPage', () {
    testWidgets('displays the page title', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Exercise Recommendations'), findsOneWidget);

      expect(find.text('Your Preferences'), findsOneWidget);
    });

    testWidgets('displays preferences and activity level selector', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(DropdownButtonFormField<FitnessGoal>), findsOneWidget);

      expect(
        find.byType(DropdownButtonFormField<ExercisePreference>),
        findsOneWidget,
      );

      expect(find.text('Activity Level'), findsOneWidget);
      expect(find.text('Beginner'), findsOneWidget);
      expect(find.text('Intermediate'), findsOneWidget);

      expect(find.byKey(const ValueKey('level-beginner')), findsOneWidget);

      expect(find.byKey(const ValueKey('level-intermediate')), findsOneWidget);
    });

    testWidgets('shows initial instructions', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(
        find.text(
          'Choose your preferences and tap '
          'Get Recommendations.',
        ),
        findsOneWidget,
      );

      expect(find.text('Recommended Exercises'), findsNothing);
    });

    testWidgets('generates exercise recommendations', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      await generateRecommendations(tester);

      expect(find.text('Recommended Exercises'), findsOneWidget);

      expect(
        find.text('3 suggestions based on your selected preferences'),
        findsOneWidget,
      );

      expect(find.text('Walking'), findsOneWidget);
    });

    testWidgets('displays duration and intensity', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      await generateRecommendations(tester);

      expect(find.text('20 min'), findsWidgets);

      expect(find.text('Low Intensity'), findsWidgets);
    });

    testWidgets('displays benefits and safety notes', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      await generateRecommendations(tester);

      expect(find.text('Benefits'), findsWidgets);

      expect(find.text('Safety Notes'), findsWidgets);

      expect(find.text('Supports general fitness'), findsOneWidget);
    });

    testWidgets('changing a preference clears old results', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      await generateRecommendations(tester);

      expect(find.text('Recommended Exercises'), findsOneWidget);

      final goalDropdown = find.byType(DropdownButtonFormField<FitnessGoal>);

      await tester.ensureVisible(goalDropdown);
      await tester.pumpAndSettle();

      await tester.tap(goalDropdown);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Build Strength').last);
      await tester.pumpAndSettle();

      expect(find.text('Recommended Exercises'), findsNothing);

      expect(
        find.text(
          'Choose your preferences and tap '
          'Get Recommendations.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('regenerates results after preference change', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      final preferenceDropdown = find.byType(
        DropdownButtonFormField<ExercisePreference>,
      );

      await tester.ensureVisible(preferenceDropdown);
      await tester.pumpAndSettle();

      await tester.tap(preferenceDropdown);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Strength').last);
      await tester.pumpAndSettle();

      await generateRecommendations(tester);

      expect(find.text('Recommended Exercises'), findsOneWidget);

      expect(find.text('Chair Exercises'), findsOneWidget);
    });

    testWidgets('displays the health safety disclaimer', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(
        find.textContaining(
          'They do not assess whether an exercise '
          'is medically safe',
        ),
        findsOneWidget,
      );
    });
  });
}
