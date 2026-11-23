import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/meals/presentation/widgets/meal_type_selector.dart';

void main() {
  Future<void> pumpSelector(
    WidgetTester tester, {
    required String selectedMeal,
    required ValueChanged<String> onMealSelected,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MealTypeSelector(
            selectedMeal: selectedMeal,
            onMealSelected: onMealSelected,
          ),
        ),
      ),
    );
  }

  group('MealTypeSelector', () {
    testWidgets('displays all four meal types', (tester) async {
      await pumpSelector(tester, selectedMeal: 'Lunch', onMealSelected: (_) {});

      expect(find.text('Breakfast'), findsOneWidget);
      expect(find.text('Lunch'), findsOneWidget);
      expect(find.text('Dinner'), findsOneWidget);
      expect(find.text('Snack'), findsOneWidget);
    });

    testWidgets('shows Lunch as selected', (tester) async {
      await pumpSelector(tester, selectedMeal: 'Lunch', onMealSelected: (_) {});

      final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Lunch'),
      );

      expect(chip.selected, isTrue);
    });

    testWidgets('calls callback when Breakfast is tapped', (tester) async {
      String? selected;

      await pumpSelector(
        tester,
        selectedMeal: 'Lunch',
        onMealSelected: (meal) {
          selected = meal;
        },
      );

      await tester.tap(find.text('Breakfast'));
      await tester.pump();

      expect(selected, 'Breakfast');
    });

    testWidgets('calls callback when Dinner is tapped', (tester) async {
      String? selected;

      await pumpSelector(
        tester,
        selectedMeal: 'Lunch',
        onMealSelected: (meal) {
          selected = meal;
        },
      );

      await tester.tap(find.text('Dinner'));
      await tester.pump();

      expect(selected, 'Dinner');
    });

    testWidgets('supports Snack selection', (tester) async {
      await pumpSelector(tester, selectedMeal: 'Snack', onMealSelected: (_) {});

      final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Snack'),
      );

      expect(chip.selected, isTrue);
    });
  });
}
