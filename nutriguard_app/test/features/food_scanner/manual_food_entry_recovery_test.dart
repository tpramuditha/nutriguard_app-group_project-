import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:nutriguard_app/features/food_scanner/data/models/food_log_model.dart';
import 'package:nutriguard_app/features/food_scanner/data/repositories/food_log_repository.dart';
import 'package:nutriguard_app/features/food_scanner/presentation/pages/manual_food_entry_page.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class FailingFoodLogRepository extends FoodLogRepository {
  FailingFoodLogRepository() : super(firestore: FakeFirebaseFirestore());

  @override
  Future<String> saveFoodLog({
    required String userId,
    required FoodLogModel foodLog,
    String? submissionId,
  }) async {
    throw Exception('Simulated network failure');
  }
}

void main() {
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late FailingFoodLogRepository repository;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    repository = FailingFoodLogRepository();

    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.uid).thenReturn('test-user');
  });

  Future<void> openManualEntry(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(tester.element(find.text('Open Manual Entry')))
                    .push(
                      MaterialPageRoute<void>(
                        builder: (_) => ManualFoodEntryPage(
                          foodLogRepository: repository,
                          firebaseAuth: mockAuth,
                        ),
                      ),
                    );
              },
              child: const Text('Open Manual Entry'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Manual Entry'));
    await tester.pumpAndSettle();

    expect(find.text('Manual Food Entry'), findsOneWidget);
  }

  Future<void> enterValidFood(WidgetTester tester) async {
    final fields = find.byType(TextFormField);

    await tester.enterText(fields.at(0), 'Rice and Dhal Curry');
    await tester.enterText(fields.at(1), '100');
    await tester.enterText(fields.at(2), '150');
    await tester.enterText(fields.at(3), '10');
    await tester.enterText(fields.at(4), '20');
    await tester.enterText(fields.at(5), '5');

    await tester.scrollUntilVisible(
      find.text('Save Food'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.pumpAndSettle();
  }

  testWidgets('failed save shows recovery dialog with working actions', (
    tester,
  ) async {
    await openManualEntry(tester);
    await enterValidFood(tester);

    // The fake repository always fails.
    await tester.tap(find.text('Save Food'));
    await tester.pumpAndSettle();

    // Saving must finish so recovery becomes available.
    expect(find.text('Saving Food...'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Start New Entry'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.pumpAndSettle();

    expect(find.text('Start New Entry'), findsOneWidget);

    // Open recovery confirmation.
    await tester.tap(find.text('Start New Entry'));
    await tester.pumpAndSettle();

    expect(find.text('Start a New Entry?'), findsOneWidget);

    // Keep the current submission.
    await tester.tap(find.text('Keep This Entry'));
    await tester.pumpAndSettle();

    expect(find.text('Start a New Entry?'), findsNothing);
    expect(find.text('Manual Food Entry'), findsOneWidget);

    // Open the dialog again.
    await tester.scrollUntilVisible(
      find.text('Start New Entry'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Start New Entry'));
    await tester.pumpAndSettle();

    // Leave the current entry.
    await tester.tap(find.text('Leave Entry'));
    await tester.pumpAndSettle();

    expect(find.text('Manual Food Entry'), findsNothing);
    expect(find.text('Open Manual Entry'), findsOneWidget);
  });
}
