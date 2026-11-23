import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguard_app/features/profile/presentation/pages/help_support_page.dart';

void main() {
  group('HelpSupportPage', () {
    Future<void> pumpHelpSupportPage(WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: HelpSupportPage()));
    }

    testWidgets('displays the Help & Support page title and welcome card', (
      tester,
    ) async {
      await pumpHelpSupportPage(tester);

      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('How can we help you?'), findsOneWidget);
      expect(find.textContaining('Find helpful information'), findsOneWidget);
    });

    testWidgets('displays all help sections', (tester) async {
      await pumpHelpSupportPage(tester);

      expect(find.text('Getting Started'), findsOneWidget);
      expect(find.text('Food & Nutrition'), findsOneWidget);
      expect(find.text('Health & Exercise'), findsOneWidget);
      expect(find.text('Privacy & Account'), findsOneWidget);
      expect(find.text('Contact Support'), findsNWidgets(2));
      expect(find.text('About NutriGuard'), findsOneWidget);
    });

    testWidgets('expands Food Scanner Help and displays instructions', (
      tester,
    ) async {
      await pumpHelpSupportPage(tester);

      await tester.tap(find.text('Food Scanner Help'));
      await tester.pumpAndSettle();

      expect(
        find.text('Open Food Scanner from the Dashboard.'),
        findsOneWidget,
      );
      expect(find.text('Capture a clear image of your food.'), findsOneWidget);
    });

    testWidgets('displays contact information notice and medical disclaimer', (
      tester,
    ) async {
      await pumpHelpSupportPage(tester);

      await tester.ensureVisible(
        find.text('Support contact details are not configured yet.'),
      );

      expect(
        find.text('Support contact details are not configured yet.'),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.textContaining('do not replace professional medical advice'),
      );

      expect(
        find.textContaining('do not replace professional medical advice'),
        findsOneWidget,
      );
    });
  });
}
