import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:nutriguard_app/app/routes/app_routes.dart';
import 'package:nutriguard_app/app/routes/route_names.dart';
import 'package:nutriguard_app/features/exercise/data/repositories/exercise_log_repository.dart';
import 'package:nutriguard_app/features/exercise/presentation/pages/add_exercise_page.dart';
import 'package:nutriguard_app/features/exercise_recommendation/data/models/exercise_recommendation_model.dart';
import 'package:nutriguard_app/features/exercise_recommendation/domain/models/exercise_session_arguments.dart';
import 'package:nutriguard_app/features/exercise_recommendation/domain/services/exercise_plan_date_service.dart';
import 'package:nutriguard_app/features/exercise_recommendation/presentation/widgets/exercise_start_action.dart';

class MockExerciseLogRepository extends Mock implements ExerciseLogRepository {}

void main() {
  late MockExerciseLogRepository repository;

  setUp(() {
    repository = MockExerciseLogRepository();
  });

  const recommendation = ExerciseRecommendationModel(
    id: 'gentle_stretching',
    name: 'Gentle Stretching',
    type: 'Flexibility',
    intensity: 'Low',
    durationMinutes: 10,
    description: 'Perform gentle stretches.',
    benefits: ['Supports flexibility'],
    safetyNotes: ['Avoid painful movements.'],
  );

  group('Exercise Date Integration', () {
    testWidgets('prefills selected Wednesday date', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AddExercisePage(
            initialExerciseName: recommendation.name,
            initialExerciseType: recommendation.type,
            initialDurationMinutes: recommendation.durationMinutes,
            initialIsCompleted: false,
            initialDate: DateTime(2026, 11, 11),
            repository: repository,
          ),
        ),
      );

      expect(find.text('Date: 2026-11-11'), findsOneWidget);

      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isFalse,
      );
    });

    testWidgets('manual exercise uses current date', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: AddExercisePage(repository: repository)),
      );

      final today = DateTime.now();

      final expected =
          '${today.year}-'
          '${today.month.toString().padLeft(2, '0')}-'
          '${today.day.toString().padLeft(2, '0')}';

      expect(find.text('Date: $expected'), findsOneWidget);
    });

    test('exercise route preserves navigation arguments', () {
      final arguments = ExerciseSessionArguments(
        recommendation: recommendation,
        plannedDate: DateTime(2026, 11, 11),
      );

      final settings = RouteSettings(
        name: RouteNames.exercise,
        arguments: arguments,
      );

      final route = AppRoutes.generateRoute(settings);

      expect(route.settings.name, RouteNames.exercise);
      expect(route.settings.arguments, same(arguments));
    });

    testWidgets('Start Session passes selected weekday date', (tester) async {
      Object? receivedArguments;

      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(
            body: ExerciseStartAction(
              exercise: recommendation,
              weekday: DateTime.wednesday,
            ),
          ),
          onGenerateRoute: (settings) {
            if (settings.name == RouteNames.exercise) {
              receivedArguments = settings.arguments;

              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) =>
                    const Scaffold(body: Text('Tracking Route Opened')),
              );
            }

            return null;
          },
        ),
      );

      await tester.tap(find.text('Start Session'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Tracking'));
      await tester.pumpAndSettle();

      expect(find.text('Tracking Route Opened'), findsOneWidget);

      expect(receivedArguments, isA<ExerciseSessionArguments>());

      final received = receivedArguments as ExerciseSessionArguments;

      const dateService = ExercisePlanDateService();

      final expectedDate = dateService.dateForWeekday(
        referenceDate: DateTime.now(),
        weekday: DateTime.wednesday,
      );

      expect(received.recommendation.id, recommendation.id);

      expect(received.plannedDate, expectedDate);
    });
  });
}
