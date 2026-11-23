import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/pantry/data/models/pantry_item_model.dart';
import 'package:nutriguard_app/features/pantry/data/models/recipe_model.dart';
import 'package:nutriguard_app/features/pantry/data/services/recipe_matching_service.dart';
import 'package:nutriguard_app/features/pantry/presentation/pages/recipe_details_page.dart';

void main() {
  const matchingService = RecipeMatchingService();

  RecipeModel createRecipe() {
    return const RecipeModel(
      id: 'test_recipe',
      name: 'Test Egg Rice',
      description: 'A simple test recipe.',
      preparationMinutes: 5,
      cookingMinutes: 15,
      servings: 2,
      calories: 350,
      protein: 15,
      carbs: 45,
      fat: 10,
      ingredients: [
        RecipeIngredient(name: 'Rice', quantity: 200, unit: 'g'),
        RecipeIngredient(name: 'Eggs', quantity: 2, unit: 'pcs'),
        RecipeIngredient(name: 'Carrots', quantity: 100, unit: 'g'),
      ],
      instructions: [
        'Cook the rice.',
        'Cook the eggs.',
        'Mix the ingredients.',
      ],
    );
  }

  PantryItemModel createPantryItem({
    required String name,
    required double quantity,
    required String unit,
  }) {
    return PantryItemModel(
      id: name,
      name: name,
      quantity: quantity,
      unit: unit,
      category: 'Other',
      createdAt: DateTime(2026, 11, 6),
    );
  }

  RecipeMatchResult createResult({
    bool includeEggs = true,
    bool includeCarrots = false,
  }) {
    final pantryItems = [
      createPantryItem(name: 'Rice', quantity: 500, unit: 'g'),
      if (includeEggs) createPantryItem(name: 'Eggs', quantity: 4, unit: 'pcs'),
      if (includeCarrots)
        createPantryItem(name: 'Carrots', quantity: 150, unit: 'g'),
    ];

    return matchingService.matchRecipe(
      recipe: createRecipe(),
      pantryItems: pantryItems,
    );
  }

  Future<void> pumpDetailsPage(
    WidgetTester tester,
    RecipeMatchResult result,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: RecipeDetailsPage(result: result)),
    );
  }

  group('RecipeDetailsPage', () {
    testWidgets('displays recipe name and description', (tester) async {
      await pumpDetailsPage(tester, createResult());

      expect(find.text('Test Egg Rice'), findsOneWidget);
      expect(find.text('A simple test recipe.'), findsOneWidget);
    });

    testWidgets('displays cooking time and servings', (tester) async {
      await pumpDetailsPage(tester, createResult());

      expect(find.text('20 min'), findsOneWidget);
      expect(find.text('2 servings'), findsOneWidget);
    });

    testWidgets('displays nutrition section', (tester) async {
      await pumpDetailsPage(tester, createResult());

      expect(find.text('Estimated Nutrition'), findsOneWidget);

      expect(find.text('350 kcal'), findsOneWidget);
      expect(find.text('15 g'), findsOneWidget);
      expect(find.text('45 g'), findsOneWidget);
      expect(find.text('10 g'), findsOneWidget);
    });

    testWidgets('displays ingredient availability count', (tester) async {
      await pumpDetailsPage(tester, createResult());

      await tester.scrollUntilVisible(
        find.text('2 of 3 ingredients available'),
        200,
      );

      expect(find.text('2 of 3 ingredients available'), findsOneWidget);
    });

    testWidgets('shows available ingredient information', (tester) async {
      await pumpDetailsPage(tester, createResult());

      await tester.scrollUntilVisible(find.text('Rice'), 200);

      expect(find.text('Rice'), findsOneWidget);
      expect(find.text('Eggs'), findsOneWidget);
      expect(find.text('Available'), findsNWidgets(2));
    });

    testWidgets('shows missing ingredient information', (tester) async {
      await pumpDetailsPage(tester, createResult());

      await tester.scrollUntilVisible(find.text('Carrots'), 200);

      expect(find.text('Carrots'), findsOneWidget);
      expect(find.text('Missing'), findsOneWidget);
    });

    testWidgets('shows cooking instructions', (tester) async {
      await pumpDetailsPage(tester, createResult());

      await tester.scrollUntilVisible(find.text('Cooking Instructions'), 200);

      expect(find.text('Cooking Instructions'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Cook the rice.'), 200);

      expect(find.text('Cook the rice.'), findsOneWidget);
    });

    testWidgets('shows 100 percent match when all ingredients exist', (
      tester,
    ) async {
      await pumpDetailsPage(tester, createResult(includeCarrots: true));

      expect(find.text('100% match'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('3 of 3 ingredients available'),
        200,
      );

      expect(find.text('3 of 3 ingredients available'), findsOneWidget);
    });

    testWidgets('shows partial match correctly', (tester) async {
      await pumpDetailsPage(tester, createResult());

      expect(find.text('67% match'), findsOneWidget);
    });

    testWidgets('shows per-serving nutrition label and values', (tester) async {
      await pumpDetailsPage(tester, createResult());

      expect(find.text('Values shown per serving'), findsOneWidget);

      expect(find.text('350 kcal'), findsOneWidget);
      expect(find.text('15 g'), findsOneWidget);
      expect(find.text('45 g'), findsOneWidget);
      expect(find.text('10 g'), findsOneWidget);
    });

    testWidgets('shows full recipe nutrition totals', (tester) async {
      await pumpDetailsPage(tester, createResult());

      await tester.scrollUntilVisible(find.text('Full Recipe Nutrition'), 200);

      expect(find.text('Full Recipe Nutrition'), findsOneWidget);

      expect(find.text('Total Servings'), findsOneWidget);
      expect(find.text('Total Calories'), findsOneWidget);
      expect(find.text('700 kcal'), findsOneWidget);

      expect(find.text('Total Protein'), findsOneWidget);
      expect(find.text('30 g'), findsOneWidget);

      expect(find.text('Total Carbs'), findsOneWidget);
      expect(find.text('90 g'), findsOneWidget);

      expect(find.text('Total Fat'), findsOneWidget);
      expect(find.text('20 g'), findsOneWidget);
    });
  });
}
