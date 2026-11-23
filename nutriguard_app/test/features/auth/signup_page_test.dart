import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:nutriguard_app/app/routes/route_names.dart';
import 'package:nutriguard_app/core/services/firebase/firebase_auth_service.dart';
import 'package:nutriguard_app/features/auth/presentation/pages/signup_page.dart';

class MockFirebaseAuthService extends Mock implements FirebaseAuthService {}

void main() {
  late MockFirebaseAuthService authService;

  setUp(() {
    authService = MockFirebaseAuthService();
  });

  Future<void> pumpSignupPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SignupPage(authService: authService),
        routes: {
          RouteNames.login: (_) => const Scaffold(body: Text('Login Screen')),
        },
      ),
    );
  }

  Future<void> enterValidSignupDetails(WidgetTester tester) async {
    await tester.enterText(find.byType(TextFormField).at(0), 'Test User');

    await tester.enterText(
      find.byType(TextFormField).at(1),
      'test@example.com',
    );

    await tester.enterText(find.byType(TextFormField).at(2), 'password123');

    await tester.enterText(find.byType(TextFormField).at(3), 'password123');
  }

  Future<void> tapCreateAccount(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Create Account'));
    await tester.tap(find.text('Create Account'));
    await tester.pump();
  }

  group('SignupPage validation', () {
    testWidgets('shows error when fields are empty', (tester) async {
      await pumpSignupPage(tester);

      await tapCreateAccount(tester);
      await tester.pumpAndSettle();

      expect(find.text('Please fill in all fields.'), findsOneWidget);

      verifyNever(
        () => authService.signUp(
          name: any(named: 'name'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    });

    testWidgets('shows error for invalid email', (tester) async {
      await pumpSignupPage(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'Test User');

      await tester.enterText(find.byType(TextFormField).at(1), 'invalid-email');

      await tester.enterText(find.byType(TextFormField).at(2), 'password123');

      await tester.enterText(find.byType(TextFormField).at(3), 'password123');

      await tapCreateAccount(tester);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address.'), findsOneWidget);
    });

    testWidgets('rejects password shorter than 8 characters', (tester) async {
      await pumpSignupPage(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'Test User');

      await tester.enterText(
        find.byType(TextFormField).at(1),
        'test@example.com',
      );

      await tester.enterText(find.byType(TextFormField).at(2), '12345');

      await tester.enterText(find.byType(TextFormField).at(3), '12345');

      await tapCreateAccount(tester);
      await tester.pumpAndSettle();

      expect(
        find.text('Password must have at least 8 characters.'),
        findsOneWidget,
      );
    });

    testWidgets('shows error when passwords do not match', (tester) async {
      await pumpSignupPage(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'Test User');

      await tester.enterText(
        find.byType(TextFormField).at(1),
        'test@example.com',
      );

      await tester.enterText(find.byType(TextFormField).at(2), 'password123');

      await tester.enterText(find.byType(TextFormField).at(3), 'different123');

      await tapCreateAccount(tester);
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match.'), findsOneWidget);
    });

    testWidgets('requires agreement to terms', (tester) async {
      await pumpSignupPage(tester);

      await enterValidSignupDetails(tester);

      await tapCreateAccount(tester);
      await tester.pumpAndSettle();

      expect(
        find.text('Please agree to the Terms & Privacy Policy.'),
        findsOneWidget,
      );
    });
  });

  group('SignupPage authentication', () {
    testWidgets('shows Firebase email already registered error', (
      tester,
    ) async {
      when(
        () => authService.signUp(
          name: any(named: 'name'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

      await pumpSignupPage(tester);
      await enterValidSignupDetails(tester);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      await tapCreateAccount(tester);
      await tester.pumpAndSettle();

      expect(find.text('This email is already registered.'), findsOneWidget);
    });

    testWidgets('shows loading indicator while signing up', (tester) async {
      final completer = Completer<void>();

      when(
        () => authService.signUp(
          name: any(named: 'name'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) => completer.future);

      await pumpSignupPage(tester);
      await enterValidSignupDetails(tester);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      await tapCreateAccount(tester);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete();

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Login Screen'), findsOneWidget);
    });

    testWidgets('navigates to login after successful signup', (tester) async {
      when(
        () => authService.signUp(
          name: any(named: 'name'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {});

      await pumpSignupPage(tester);
      await enterValidSignupDetails(tester);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      await tapCreateAccount(tester);
      await tester.pumpAndSettle();

      expect(find.text('Login Screen'), findsOneWidget);

      verify(
        () => authService.signUp(
          name: 'Test User',
          email: 'test@example.com',
          password: 'password123',
        ),
      ).called(1);
    });
  });
}
