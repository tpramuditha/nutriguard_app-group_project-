import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nutriguard_app/features/profile/data/services/user_data_export_service.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseAuth auth;
  late MockUser user;
  late Directory temporaryDirectory;
  late UserDataExportService service;

  const userId = 'user-123';

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    auth = MockFirebaseAuth();
    user = MockUser();

    when(() => auth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn(userId);

    temporaryDirectory = await Directory.systemTemp.createTemp(
      'nutriguard_export_test_',
    );

    service = UserDataExportService(
      firestore: firestore,
      auth: auth,
      temporaryDirectoryProvider: () async => temporaryDirectory,
    );
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  group('UserDataExportService', () {
    test('creates a CSV file with the correct headers', () async {
      final file = await service.createExportFile();

      expect(await file.exists(), isTrue);

      final bytes = await file.readAsBytes();

      // UTF-8 BOM must be the first three bytes.
      expect(bytes.length >= 3, isTrue);
      expect(bytes[0], 0xEF);
      expect(bytes[1], 0xBB);
      expect(bytes[2], 0xBF);

      // Decode the CSV after the BOM.
      final content = utf8.decode(bytes.sublist(3));

      expect(content, contains('"category","documentId","dataJson"'));
    });

    test('exports records from all eight collections', () async {
      final userRef = firestore.collection('users').doc(userId);

      final collections = {
        'foodLogs': 'Food History',
        'healthReports': 'Health Reports',
        'monthlyHealthMarkers': 'Monthly Health Markers',
        'pantryItems': 'My Pantry',
        'plannedMeals': 'Meal Plans',
        'exerciseLogs': 'Exercise Records',
        'weeklyExercisePlans': 'Weekly Exercise Plans',
        'weightLogs': 'Weight Records',
      };

      for (final entry in collections.entries) {
        await userRef.collection(entry.key).doc('test-document').set({
          'testField': entry.key,
        });
      }

      final file = await service.createExportFile();
      final content = await file.readAsString(encoding: utf8);

      for (final entry in collections.entries) {
        expect(content, contains(entry.value));
        expect(content, contains('test-document'));
        expect(content, contains(entry.key));
      }
    });

    test('exports existing preference documents', () async {
      final preferencesRef = firestore
          .collection('users')
          .doc(userId)
          .collection('preferences');

      await preferencesRef.doc('nutrition').set({'dailyCalorieGoal': 2000});

      await preferencesRef.doc('profile').set({
        'dietaryRestrictions': ['Vegetarian'],
      });

      await preferencesRef.doc('notifications').set({'mealReminders': true});

      final file = await service.createExportFile();
      final content = await file.readAsString(encoding: utf8);

      expect(content, contains('nutrition'));
      expect(content, contains('profile'));
      expect(content, contains('notifications'));
      expect(content, contains('Personal Preferences'));
    });

    test('does not export missing preference documents', () async {
      final file = await service.createExportFile();
      final content = await file.readAsString(encoding: utf8);

      expect(content, isNot(contains('Personal Preferences')));
    });

    test('exports only the currently authenticated user data', () async {
      await firestore
          .collection('users')
          .doc(userId)
          .collection('foodLogs')
          .doc('my-food')
          .set({'foodName': 'Rice'});

      await firestore
          .collection('users')
          .doc('another-user')
          .collection('foodLogs')
          .doc('other-food')
          .set({'foodName': 'Bread'});

      final file = await service.createExportFile();
      final content = await file.readAsString(encoding: utf8);

      expect(content, contains('my-food'));
      expect(content, isNot(contains('other-food')));
      expect(content, isNot(contains('Bread')));
    });

    test('preserves nested document data in JSON', () async {
      await firestore
          .collection('users')
          .doc(userId)
          .collection('foodLogs')
          .doc('nested-food')
          .set({
            'foodName': 'Rice',
            'nutrition': {
              'calories': 250,
              'macros': {'protein': 5, 'carbs': 50},
            },
          });

      final file = await service.createExportFile();
      final content = await file.readAsString(encoding: utf8);

      expect(content, contains('nested-food'));
      expect(content, contains('nutrition'));
      expect(content, contains('calories'));
      expect(content, contains('protein'));
      expect(content, contains('carbs'));
    });

    test('converts Firestore timestamps to ISO 8601 strings', () async {
      final date = DateTime.utc(2026, 11, 15, 10, 30);

      await firestore
          .collection('users')
          .doc(userId)
          .collection('foodLogs')
          .doc('dated-food')
          .set({'createdAt': Timestamp.fromDate(date)});

      final file = await service.createExportFile();
      final content = await file.readAsString(encoding: utf8);

      expect(content, contains(date.toIso8601String()));
    });

    test('creates a CSV file with escaped quotation marks', () async {
      await firestore
          .collection('users')
          .doc(userId)
          .collection('foodLogs')
          .doc('special-food')
          .set({'foodName': 'Rice, "Red" Rice'});

      final file = await service.createExportFile();
      final content = await file.readAsString(encoding: utf8);

      // CSV quotation marks inside a field must be doubled.
      expect(content, contains('""'));
      expect(content, contains('special-food'));
    });

    test('throws StateError when no user is authenticated', () async {
      when(() => auth.currentUser).thenReturn(null);

      expect(() => service.createExportFile(), throwsA(isA<StateError>()));
    });

    test('throws StateError when sharing a missing file', () async {
      final missingFile = File(
        '${temporaryDirectory.path}${Platform.pathSeparator}missing.csv',
      );

      expect(
        () => service.shareExportFile(missingFile),
        throwsA(isA<StateError>()),
      );
    });
  });
}
