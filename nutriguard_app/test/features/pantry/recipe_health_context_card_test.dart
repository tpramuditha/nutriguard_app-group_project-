import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/pantry/presentation/widgets/recipe_health_context_card.dart';

void main() {
  final testDate = DateTime(2026, 11, 6);

  Future<void> pumpCard(
    WidgetTester tester, {
    required Future<bool> healthDataFuture,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: RecipeHealthContextCard(
              healthDataFuture: healthDataFuture,
              referenceDate: testDate,
            ),
          ),
        ),
      ),
    );
  }

  group('RecipeHealthContextCard', () {
    testWidgets('shows Health Profile title', (tester) async {
      await pumpCard(tester, healthDataFuture: Future.value(true));

      expect(find.text('Health Profile'), findsOneWidget);
    });

    testWidgets('displays correct month label', (tester) async {
      await pumpCard(tester, healthDataFuture: Future.value(true));

      expect(find.text('Nov 2026'), findsOneWidget);
    });

    testWidgets('shows recorded status when data exists', (tester) async {
      await pumpCard(tester, healthDataFuture: Future.value(true));

      await tester.pump();

      expect(
        find.text('Health markers recorded for Nov 2026.'),
        findsOneWidget,
      );
    });

    testWidgets('shows no-data status when records are absent', (tester) async {
      await pumpCard(tester, healthDataFuture: Future.value(false));

      await tester.pump();

      expect(
        find.text('No health markers recorded for Nov 2026.'),
        findsOneWidget,
      );
    });

    testWidgets('shows loading state while checking', (tester) async {
      final completer = Completer<bool>();

      await pumpCard(tester, healthDataFuture: completer.future);

      expect(find.text('Checking monthly health markers...'), findsOneWidget);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(true);
      await tester.pump();
    });

    testWidgets('shows error message on loading failure', (tester) async {
      final completer = Completer<bool>();

      await pumpCard(tester, healthDataFuture: completer.future);

      completer.completeError(StateError('Simulated Firebase failure'));

      await tester.pump();

      expect(
        find.text(
          'Unable to load health markers. '
          'Check your connection and refresh.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows refresh button', (tester) async {
      await pumpCard(tester, healthDataFuture: Future.value(true));

      expect(find.byTooltip('Refresh health markers'), findsOneWidget);
    });

    testWidgets('shows medical suitability disclaimer', (tester) async {
      await pumpCard(tester, healthDataFuture: Future.value(true));

      expect(
        find.textContaining('Health measurements are not used to determine'),
        findsOneWidget,
      );
    });
  });
}
