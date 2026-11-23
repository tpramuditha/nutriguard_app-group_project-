import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:nutriguard_app/features/pantry/data/repositories/pantry_repository.dart';
import 'package:nutriguard_app/features/pantry/presentation/pages/pantry_page.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

void main() {
  late FakeFirebaseFirestore firestore;
  late PantryRepository repository;
  late MockFirebaseAuth auth;
  late MockUser user;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = PantryRepository(firestore: firestore);

    auth = MockFirebaseAuth();
    user = MockUser();

    when(() => user.uid).thenReturn('test-user');
    when(() => auth.currentUser).thenReturn(user);
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: PantryPage(repository: repository, firebaseAuth: auth),
    );
  }

  group('PantryPage', () {
    testWidgets('displays pantry page for signed-in user', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('My Pantry'), findsOneWidget);
      expect(find.text('Find recipes you can make right now'), findsOneWidget);
      expect(find.text('Your pantry is empty'), findsOneWidget);
    });

    testWidgets('displays login message when user is not signed in', (
      tester,
    ) async {
      when(() => auth.currentUser).thenReturn(null);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Please log in to view your pantry.'), findsOneWidget);
    });
  });
}
