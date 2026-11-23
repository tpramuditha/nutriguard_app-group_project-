import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/auth/presentation/pages/welcome_page.dart';

void main() {
  testWidgets('NutriGuard welcome page loads successfully', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: WelcomePage())),
    );

    // Check that the first onboarding slide is displayed.
    expect(find.text('NutriGuard'), findsOneWidget);

    // Check the first onboarding button.
    expect(find.text('Get Started'), findsOneWidget);
  });
}
