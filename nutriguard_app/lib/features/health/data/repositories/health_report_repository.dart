import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/health_report_model.dart';

class HealthReportRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  HealthReportRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _reportsCollection() {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('You must be signed in to access health reports.');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('healthReports');
  }

  // Save a new health report and return its generated ID.
  Future<String> saveReport(HealthReportModel report) async {
    final data = report.toMap();

    final document = await _reportsCollection().add(data);

    return document.id;
  }

  // Retrieve all reports belonging to the signed-in user.
  Future<List<HealthReportModel>> getReports() async {
    final snapshot = await _reportsCollection().get();

    final reports = snapshot.docs
        .map((doc) => HealthReportModel.fromMap(doc.data()))
        .toList();

    reports.sort((a, b) => b.reportDate.compareTo(a.reportDate));

    return reports;
  }
}
