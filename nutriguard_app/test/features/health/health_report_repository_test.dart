import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mocktail/mocktail.dart';

import 'package:nutriguard_app/features/health/data/models/health_measurement_model.dart';
import 'package:nutriguard_app/features/health/data/models/health_report_model.dart';
import 'package:nutriguard_app/features/health/data/repositories/health_report_repository.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late HealthReportRepository repository;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();

    when(() => mockUser.uid).thenReturn('userA');
    when(() => mockAuth.currentUser).thenReturn(mockUser);

    repository = HealthReportRepository(
      firestore: fakeFirestore,
      auth: mockAuth,
    );
  });

  HealthReportModel createTestReport(DateTime date) {
    return HealthReportModel(
      reportType: 'Lipid Profile',
      reportName: 'Lipid Profile',
      reportDate: date,
      measurements: const [
        HealthMeasurementModel(
          name: 'Total Cholesterol',
          value: 185,
          unit: 'mg/dL',
        ),
        HealthMeasurementModel(
          name: 'HDL Cholesterol',
          value: 55,
          unit: 'mg/dL',
        ),
      ],
    );
  }

  test('saves a report to the signed-in user collection', () async {
    final report = createTestReport(DateTime(2026, 10, 17));

    final reportId = await repository.saveReport(report);

    expect(reportId, isNotEmpty);

    final document = await fakeFirestore
        .collection('users')
        .doc('userA')
        .collection('healthReports')
        .doc(reportId)
        .get();

    expect(document.exists, true);
    expect(document.data()?['reportName'], 'Lipid Profile');
    expect(document.data()?['reportType'], 'Lipid Profile');
  });

  test('retrieves saved reports correctly', () async {
    final report = createTestReport(DateTime(2026, 10, 17));

    await repository.saveReport(report);

    final reports = await repository.getReports();

    expect(reports.length, 1);
    expect(reports.first.reportName, 'Lipid Profile');
    expect(reports.first.measurements.length, 2);
    expect(reports.first.measurements.first.value, 185);
  });

  test('returns reports newest first', () async {
    await repository.saveReport(createTestReport(DateTime(2026, 9, 1)));

    await repository.saveReport(createTestReport(DateTime(2026, 10, 17)));

    final reports = await repository.getReports();

    expect(reports.length, 2);
    expect(reports.first.reportDate.month, 10);
    expect(reports.last.reportDate.month, 9);
  });

  test('prevents access when user is signed out', () async {
    when(() => mockAuth.currentUser).thenReturn(null);

    expect(() => repository.getReports(), throwsA(isA<StateError>()));
  });
}
