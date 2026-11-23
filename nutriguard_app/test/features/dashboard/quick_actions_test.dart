import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mocktail/mocktail.dart';

import 'package:nutriguard_app/app/routes/route_names.dart';
import 'package:nutriguard_app/features/dashboard/presentation/widgets/quick_actions.dart';
import 'package:nutriguard_app/features/pantry/presentation/pages/pantry_page.dart';
import 'package:nutriguard_app/features/pantry/data/repositories/pantry_repository.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  group('QuickActions', () {
    testWidgets('displays all four quick action buttons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: QuickActions())),
        ),
      );

      expect(find.text('Scan Food'), findsOneWidget);
      expect(find.text('Pantry'), findsOneWidget);
      expect(find.text('Planner'), findsOneWidget);
      expect(find.text('Health'), findsOneWidget);
    });

    testWidgets('Scan Food calls the provided callback', (tester) async {
      var callbackCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickActions(
              onScanFood: () async {
                callbackCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Scan Food'));
      await tester.pumpAndSettle();

      expect(callbackCalled, isTrue);
    });

    testWidgets('Scan Food opens food scanner when no callback is provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: QuickActions()),
          routes: {
            RouteNames.foodScanner: (_) =>
                const Scaffold(body: Text('Food Scanner Test Page')),
          },
        ),
      );

      await tester.tap(find.text('Scan Food'));
      await tester.pumpAndSettle();

      expect(find.text('Food Scanner Test Page'), findsOneWidget);
    });

    testWidgets('Pantry opens PantryPage', (tester) async {
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth();

      when(() => auth.currentUser).thenReturn(null);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickActions(
              pantryRepository: PantryRepository(firestore: firestore),
              firebaseAuth: auth,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Pantry'));
      await tester.pumpAndSettle();

      expect(find.byType(PantryPage), findsOneWidget);
      expect(find.text('Please log in to view your pantry.'), findsOneWidget);
    });

    testWidgets('Planner opens the planner route', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: QuickActions()),
          routes: {
            RouteNames.planner: (_) =>
                const Scaffold(body: Text('Planner Test Page')),
          },
        ),
      );

      await tester.tap(find.text('Planner'));
      await tester.pumpAndSettle();

      expect(find.text('Planner Test Page'), findsOneWidget);
    });

    testWidgets('Health opens the health route', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: QuickActions()),
          routes: {
            RouteNames.health: (_) =>
                const Scaffold(body: Text('Health Test Page')),
          },
        ),
      );

      await tester.tap(find.text('Health'));
      await tester.pumpAndSettle();

      expect(find.text('Health Test Page'), findsOneWidget);
    });
  });
}
