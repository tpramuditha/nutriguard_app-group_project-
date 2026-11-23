import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:nutriguard_app/features/food_history/presentation/pages/food_history_page.dart';
import 'package:nutriguard_app/features/food_scanner/data/models/food_log_model.dart';
import 'package:nutriguard_app/features/food_scanner/data/repositories/food_log_repository.dart';

class MockFoodLogRepository extends Mock implements FoodLogRepository {}

void main() {
  late MockFoodLogRepository repository;

  const testUserId = 'test-user';

  final testFoodLog = FoodLogRecord(
    documentId: 'food-1',
    foodLog: FoodLogModel(
      foodId: 'food-1',
      foodName: 'Rice and Curry',
      source: 'manual',
      grams: 200,
      mealType: 'Lunch',
      calories: 350,
      protein: 12,
      carbs: 55,
      fat: 8,
      loggedAt: DateTime.now(),
    ),
  );

  setUp(() {
    repository = MockFoodLogRepository();
  });

  Future<void> pumpFoodHistoryPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FoodHistoryPage(repository: repository, userId: testUserId),
      ),
    );
  }

  group('FoodHistoryPage', () {
    testWidgets('shows loading indicator while loading food history', (
      tester,
    ) async {
      final completer = Completer<List<FoodLogRecord>>();

      when(() => repository.getFoodLogRecords(userId: testUserId))
          .thenAnswer((_) => completer.future);

      await pumpFoodHistoryPage(tester);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete([]);

      await tester.pumpAndSettle();
    });

    testWidgets('displays food records successfully', (tester) async {
      when(() => repository.getFoodLogRecords(userId: testUserId))
          .thenAnswer((_) async => [testFoodLog]);

      await pumpFoodHistoryPage(tester);
      await tester.pumpAndSettle();

      expect(find.text('Rice and Curry'), findsOneWidget);
    });

    testWidgets('shows empty state when no food records exist', (tester) async {
      when(() => repository.getFoodLogRecords(userId: testUserId))
          .thenAnswer((_) async => []);

      await pumpFoodHistoryPage(tester);
      await tester.pumpAndSettle();

      expect(find.text('No meals logged for this date.'), findsOneWidget);

      expect(find.text('Log a Meal'), findsOneWidget);
    });

    testWidgets('shows error and retries loading food history', (tester) async {
      var callCount = 0;

      when(() => repository.getFoodLogRecords(userId: testUserId))
          .thenAnswer((_) async {
            callCount++;

            if (callCount == 1) {
              throw Exception('Test loading error');
            }

            return [testFoodLog];
          });

      await pumpFoodHistoryPage(tester);
      await tester.pumpAndSettle();

      expect(find.text('Unable to Load Food History'), findsOneWidget);

      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();

      expect(find.text('Rice and Curry'), findsOneWidget);
      expect(callCount, 2);
    });

    testWidgets(
      'shows filter empty state when selected meal type has no records',
      (tester) async {
        when(() => repository.getFoodLogRecords(userId: testUserId))
            .thenAnswer((_) async => [testFoodLog]);

        await pumpFoodHistoryPage(tester);
        await tester.pumpAndSettle();

        // The test food is Lunch. Select Breakfast.
        await tester.tap(find.text('Breakfast'));
        await tester.pumpAndSettle();

        expect(find.text('No meals found for this meal type.'), findsOneWidget);

        // There are records for this date, so don't show Log a Meal.
        expect(find.text('Log a Meal'), findsNothing);
      },
    );
  });
}
