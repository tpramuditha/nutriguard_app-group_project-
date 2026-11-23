import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguard_app/features/planner/presentation/widgets/weekly_meal_day_card.dart';

void main() {
  Widget buildTestWidget({
    String dayName = 'Monday',
    String date = '2026-11-09',
    int mealCount = 0,
    double estimatedCalories = 0,
    List<String> mealDescriptions = const [],
    VoidCallback? onTap,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: WeeklyMealDayCard(
            dayName: dayName,
            date: date,
            mealCount: mealCount,
            estimatedCalories: estimatedCalories,
            mealDescriptions: mealDescriptions,
            onTap: onTap,
          ),
        ),
      ),
    );
  }

  group('WeeklyMealDayCard', () {
    testWidgets('displays day name and date', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(dayName: 'Wednesday', date: '2026-11-11'),
      );

      expect(find.text('Wednesday · 2026-11-11'), findsOneWidget);
    });

    testWidgets('displays rounded calorie total', (tester) async {
      await tester.pumpWidget(buildTestWidget(estimatedCalories: 420.6));

      expect(find.text('421 kcal'), findsOneWidget);
    });

    testWidgets('shows empty state when no meals exist', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('No meals planned.'), findsOneWidget);
    });

    testWidgets('displays meal count and descriptions', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          mealCount: 2,
          estimatedCalories: 680,
          mealDescriptions: const [
            'Breakfast: Vegetable Omelette',
            'Lunch: Egg Fried Rice',
          ],
        ),
      );

      expect(find.text('2 planned meal(s)'), findsOneWidget);

      expect(find.text('Breakfast: Vegetable Omelette'), findsOneWidget);

      expect(find.text('Lunch: Egg Fried Rice'), findsOneWidget);

      expect(find.text('No meals planned.'), findsNothing);
    });

    testWidgets('executes onTap callback when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        buildTestWidget(
          onTap: () {
            tapped = true;
          },
        ),
      );

      await tester.tap(find.byType(WeeklyMealDayCard));

      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('shows arrow when card is tappable', (tester) async {
      await tester.pumpWidget(buildTestWidget(onTap: () {}));

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('hides arrow when callback is absent', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });
  });
}
