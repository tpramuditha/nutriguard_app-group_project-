import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:nutriguard_app/features/food_scanner/data/models/food_log_model.dart';
import 'package:nutriguard_app/features/food_scanner/data/repositories/food_log_repository.dart';
import 'package:nutriguard_app/features/food_scanner/presentation/pages/manual_food_entry_page.dart';

class MockFoodLogRepository extends Mock implements FoodLogRepository {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class FakeFoodLogModel extends Fake implements FoodLogModel {}

void main() {
  late MockFoodLogRepository repository;
  late MockFirebaseAuth auth;
  late MockUser user;

  setUpAll(() {
    registerFallbackValue(FakeFoodLogModel());
  });

  setUp(() {
    repository = MockFoodLogRepository();
    auth = MockFirebaseAuth();
    user = MockUser();

    when(() => user.uid).thenReturn('test-user');
    when(() => auth.currentUser).thenReturn(user);

    when(
      () => repository.saveFoodLog(
        userId: any(named: 'userId'),
        foodLog: any(named: 'foodLog'),
        submissionId: any(named: 'submissionId'),
      ),
    ).thenAnswer((_) async => 'food-log-1');
  });

  Future<void> pumpManualFoodEntryPage(
    WidgetTester tester, {
    String? initialFoodName,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ManualFoodEntryPage(
          foodLogRepository: repository,
          firebaseAuth: auth,
          initialFoodName: initialFoodName,
        ),
      ),
    );
  }

  testWidgets('shows validation error when food name is empty', (tester) async {
    await pumpManualFoodEntryPage(tester);

    await tester.scrollUntilVisible(
      find.text('Save Food'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.text('Save Food'));
    await tester.pump();

    expect(find.text('Enter food name'), findsOneWidget);

    verifyNever(
      () => repository.saveFoodLog(
        userId: any(named: 'userId'),
        foodLog: any(named: 'foodLog'),
        submissionId: any(named: 'submissionId'),
      ),
    );
  });

  testWidgets('shows validation error when portion size is zero', (
    tester,
  ) async {
    await pumpManualFoodEntryPage(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Portion Size'),
      '0',
    );

    await tester.scrollUntilVisible(
      find.text('Save Food'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.text('Save Food'));
    await tester.pump();

    expect(find.text('Portion must be between 0 and 5000 g'), findsOneWidget);

    verifyNever(
      () => repository.saveFoodLog(
        userId: any(named: 'userId'),
        foodLog: any(named: 'foodLog'),
        submissionId: any(named: 'submissionId'),
      ),
    );
  });

  testWidgets('shows validation error for invalid calories', (tester) async {
    await pumpManualFoodEntryPage(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Calories'),
      'abc',
    );

    await tester.scrollUntilVisible(
      find.text('Save Food'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.text('Save Food'));
    await tester.pump();

    expect(find.text('Enter a valid number'), findsWidgets);

    verifyNever(
      () => repository.saveFoodLog(
        userId: any(named: 'userId'),
        foodLog: any(named: 'foodLog'),
        submissionId: any(named: 'submissionId'),
      ),
    );
  });

  testWidgets('shows validation error when calories exceed maximum', (
    tester,
  ) async {
    await pumpManualFoodEntryPage(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Calories'),
      '1000001',
    );

    await tester.scrollUntilVisible(
      find.text('Save Food'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.text('Save Food'));
    await tester.pump();

    expect(find.text('Enter a value between 0 and 1000000'), findsOneWidget);

    verifyNever(
      () => repository.saveFoodLog(
        userId: any(named: 'userId'),
        foodLog: any(named: 'foodLog'),
        submissionId: any(named: 'submissionId'),
      ),
    );
  });

  testWidgets('does not save when user chooses Edit Values', (tester) async {
    await pumpManualFoodEntryPage(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Food Name'),
      'Test Food',
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Portion Size'),
      '100',
    );

    await tester.enterText(find.widgetWithText(TextFormField, 'Calories'), '0');

    await tester.enterText(find.widgetWithText(TextFormField, 'Protein'), '0');

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Carbohydrates'),
      '0',
    );

    await tester.enterText(find.widgetWithText(TextFormField, 'Fat'), '0');

    await tester.scrollUntilVisible(
      find.text('Save Food'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.text('Save Food'));
    await tester.pumpAndSettle();

    expect(find.text('Check Nutrition Values'), findsOneWidget);

    await tester.tap(find.text('Edit Values'));
    await tester.pumpAndSettle();

    expect(find.text('Check Nutrition Values'), findsNothing);

    verifyNever(
      () => repository.saveFoodLog(
        userId: any(named: 'userId'),
        foodLog: any(named: 'foodLog'),
        submissionId: any(named: 'submissionId'),
      ),
    );
  });

  testWidgets('saves food when user chooses Save Anyway', (tester) async {
    await pumpManualFoodEntryPage(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Food Name'),
      'Test Food',
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Portion Size'),
      '100',
    );

    await tester.enterText(find.widgetWithText(TextFormField, 'Calories'), '0');

    await tester.enterText(find.widgetWithText(TextFormField, 'Protein'), '0');

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Carbohydrates'),
      '0',
    );

    await tester.enterText(find.widgetWithText(TextFormField, 'Fat'), '0');

    await tester.scrollUntilVisible(
      find.text('Save Food'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.text('Save Food'));
    await tester.pumpAndSettle();

    expect(find.text('Check Nutrition Values'), findsOneWidget);

    await tester.tap(find.text('Save Anyway'));
    await tester.pumpAndSettle();

    verify(
      () => repository.saveFoodLog(
        userId: 'test-user',
        foodLog: any(named: 'foodLog'),
        submissionId: any(named: 'submissionId'),
      ),
    ).called(1);
  });

  testWidgets('saves food successfully with valid nutrition values', (
    tester,
  ) async {
    await pumpManualFoodEntryPage(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Food Name'),
      'Rice',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Portion Size'),
      '200',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Calories'),
      '250',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Protein'), '5');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Carbohydrates'),
      '50',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Fat'), '2');

    await tester.scrollUntilVisible(
      find.text('Save Food'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.text('Save Food'));
    await tester.pumpAndSettle();

    verify(
      () => repository.saveFoodLog(
        userId: 'test-user',
        foodLog: any(named: 'foodLog'),
        submissionId: any(named: 'submissionId'),
      ),
    ).called(1);
  });

  testWidgets('shows loading indicator while saving food', (tester) async {
    final completer = Completer<String>();

    when(
      () => repository.saveFoodLog(
        userId: any(named: 'userId'),
        foodLog: any(named: 'foodLog'),
        submissionId: any(named: 'submissionId'),
      ),
    ).thenAnswer((_) => completer.future);

    await pumpManualFoodEntryPage(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Food Name'),
      'Rice',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Portion Size'),
      '200',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Calories'),
      '250',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Protein'), '5');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Carbohydrates'),
      '50',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Fat'), '2');

    await tester.scrollUntilVisible(
      find.text('Save Food'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.text('Save Food'));
    await tester.pump();

    expect(find.text('Saving Food...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete('food-log-1');
    await tester.pumpAndSettle();
  });
}
