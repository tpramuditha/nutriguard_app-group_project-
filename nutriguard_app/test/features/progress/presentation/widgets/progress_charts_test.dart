import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/progress/domain/services/progress_calculation_service.dart';
import 'package:nutriguard_app/features/progress/presentation/widgets/calorie_intake_chart.dart';
import 'package:nutriguard_app/features/progress/presentation/widgets/macro_trends_chart.dart';

void main() {
  List<DailyProgressSummary> createWeeklySummaries() {
    return List.generate(7, (index) {
      final date = DateTime(2026, 11, 2 + index);

      return DailyProgressSummary(
        date: date,
        mealCount: index < 2 ? 1 : 0,
        calories: index == 0
            ? 260
            : index == 1
            ? 562
            : 0,
        protein: index == 0 ? 18 : 0,
        carbs: index == 1 ? 95 : 0,
        fat: index == 0 ? 12 : 0,
      );
    });
  }

  Widget buildTestWidget(Widget chart) {
    return MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: chart)),
    );
  }

  group('CalorieIntakeChart', () {
    testWidgets('displays chart title', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          CalorieIntakeChart(
            summaries: createWeeklySummaries(),
            dailyCalorieTarget: 2400,
          ),
        ),
      );

      expect(find.text('Calorie Intake Trend'), findsOneWidget);
    });

    testWidgets('displays daily calorie target', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          CalorieIntakeChart(
            summaries: createWeeklySummaries(),
            dailyCalorieTarget: 2000,
          ),
        ),
      );

      expect(find.textContaining('Target: 2000 kcal'), findsOneWidget);
    });

    testWidgets('shows weekday labels', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          CalorieIntakeChart(
            summaries: createWeeklySummaries(),
            dailyCalorieTarget: 2400,
          ),
        ),
      );

      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);
    });

    testWidgets('shows empty state', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const CalorieIntakeChart(summaries: [], dailyCalorieTarget: 2000),
        ),
      );

      expect(find.text('No calorie data available.'), findsOneWidget);
    });
  });

  group('MacroTrendsChart', () {
    testWidgets('displays chart title', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(MacroTrendsChart(summaries: createWeeklySummaries())),
      );

      expect(find.text('Macro Trends'), findsOneWidget);
    });

    testWidgets('displays macro legends', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(MacroTrendsChart(summaries: createWeeklySummaries())),
      );

      expect(find.text('Protein'), findsOneWidget);
      expect(find.text('Carbs'), findsOneWidget);
      expect(find.text('Fat'), findsOneWidget);
    });

    testWidgets('renders the custom chart painter', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(MacroTrendsChart(summaries: createWeeklySummaries())),
      );

      expect(find.byType(CustomPaint), findsWidgets);

      expect(tester.takeException(), isNull);
    });

    testWidgets('shows empty state', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const MacroTrendsChart(summaries: [])),
      );

      expect(find.text('No macro trend data available.'), findsOneWidget);
    });
  });
}
