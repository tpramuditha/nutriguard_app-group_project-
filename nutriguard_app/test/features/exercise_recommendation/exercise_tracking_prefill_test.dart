import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/app/routes/route_names.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nutriguard_app/features/exercise/data/repositories/exercise_log_repository.dart';
import 'package:nutriguard_app/features/exercise/presentation/pages/add_exercise_page.dart';
import 'package:nutriguard_app/features/exercise_recommendation/data/models/exercise_recommendation_model.dart';
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
    description: 'Gentle stretching exercise.',
    benefits: ['Supports flexibility'],
    safetyNotes: ['Avoid painful movements.'],
  );

  Widget buildForm({
    String? name,
    String? type,
    int? duration,
    bool? completed,
    required ExerciseLogRepository repository,
  }) {
    return MaterialApp(
      home: AddExercisePage(
        initialExerciseName: name,
        initialExerciseType: type,
        initialDurationMinutes: duration,
        initialIsCompleted: completed,
        repository: repository,
      ),
    );
  }

  String fieldValue(WidgetTester tester, int index) {
    final field = tester.widget<TextFormField>(
      find.byType(TextFormField).at(index),
    );

    return field.controller?.text ?? '';
  }

  group('Exercise Tracking Prefill', () {
    testWidgets('manual form starts with empty fields', (tester) async {
      await tester.pumpWidget(buildForm(repository: repository));

      expect(fieldValue(tester, 0), '');
      expect(fieldValue(tester, 1), '');

      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isTrue,
      );
    });

    testWidgets('prefills recommended exercise fields', (tester) async {
      await tester.pumpWidget(
        buildForm(
          name: recommendation.name,
          type: recommendation.type,
          duration: recommendation.durationMinutes,
          completed: false,
          repository: repository,
        ),
      );

      expect(fieldValue(tester, 0), 'Gentle Stretching');
      expect(fieldValue(tester, 1), '10');

      expect(
        tester
            .widget<DropdownButtonFormField<String>>(
              find.byType(DropdownButtonFormField<String>),
            )
            .initialValue,
        'Flexibility',
      );
    });

    testWidgets('recommended activity is not completed', (tester) async {
      await tester.pumpWidget(
        buildForm(
          name: recommendation.name,
          type: recommendation.type,
          duration: recommendation.durationMinutes,
          completed: false,
          repository: repository,
        ),
      );

      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isFalse,
      );

      expect(find.text('This activity is planned.'), findsOneWidget);
    });

    testWidgets('prefilled fields remain editable', (tester) async {
      await tester.pumpWidget(
        buildForm(
          name: recommendation.name,
          type: recommendation.type,
          duration: recommendation.durationMinutes,
          completed: false,
          repository: repository,
        ),
      );

      await tester.enterText(
        find.byType(TextFormField).first,
        'Morning Stretching',
      );

      await tester.enterText(find.byType(TextFormField).at(1), '15');

      expect(fieldValue(tester, 0), 'Morning Stretching');
      expect(fieldValue(tester, 1), '15');
    });

    testWidgets('Start Session passes exercise to tracking route', (
      tester,
    ) async {
      Object? receivedArguments;

      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(
            body: ExerciseStartAction(exercise: recommendation),
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

      expect(receivedArguments, same(recommendation));
    });
  });
}
