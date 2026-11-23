import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:nutriguard_app/app/routes/route_names.dart';
import 'package:nutriguard_app/core/services/firebase/firebase_auth_service.dart';
import 'package:nutriguard_app/features/auth/presentation/pages/login_page.dart';

class MockFirebaseAuthService extends Mock implements FirebaseAuthService {}

class MockUserCredential extends Mock implements UserCredential {}

void main() {
  late MockFirebaseAuthService authService;
  late MockUserCredential userCredential;

  setUp(() {
    authService = MockFirebaseAuthService();
    userCredential = MockUserCredential();
  });

  Future<void> pumpLoginPage(WidgetTester tester, {Widget? destination}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(authService: authService),
        routes: {
          RouteNames.dashboard: (_) =>
              destination ?? const Scaffold(body: Text('Dashboard Screen')),
          RouteNames.signup: (_) => const Scaffold(body: Text('Signup Screen')),
        },
      ),
    );
  }

  group('LoginPage validation', () {
    testWidgets('shows error when email is empty', (tester) async {
      await pumpLoginPage(tester);

      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email address.'), findsOneWidget);

      verifyNever(
        () => authService.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    });

    testWidgets('shows error for invalid email', (tester) async {
      await pumpLoginPage(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'invalid-email',
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );

      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address.'), findsOneWidget);

      verifyNever(
        () => authService.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    });

    testWidgets('shows error when password is empty', (tester) async {
      await pumpLoginPage(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );

      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your password.'), findsOneWidget);

      verifyNever(
        () => authService.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    });
  });

  group('LoginPage authentication', () {
    testWidgets('shows loading indicator while logging in', (tester) async {
      final completer = Completer<UserCredential>();

      when(
        () => authService.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) => completer.future);

      await pumpLoginPage(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );

      await tester.ensureVisible(find.text('Log In'));
      await tester.tap(find.text('Log In'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(userCredential);

      await tester.pump();
      await tester.pumpAndSettle();
    });

    testWidgets('shows Firebase authentication error', (tester) async {
      when(
        () => authService.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(FirebaseAuthException(code: 'invalid-credential'));

      await pumpLoginPage(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'wrongpassword',
      );

      await tester.ensureVisible(find.text('Log In'));
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(find.text('Incorrect email or password.'), findsOneWidget);
    });

    testWidgets('navigates to dashboard after successful login', (
      tester,
    ) async {
      when(
        () => authService.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => userCredential);

      await pumpLoginPage(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );

      await tester.ensureVisible(find.text('Log In'));
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(find.text('Dashboard Screen'), findsOneWidget);

      verify(
        () => authService.signIn(
          email: 'test@example.com',
          password: 'password123',
        ),
      ).called(1);
    });
  });
}
