import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/weight_log_model.dart';

class WeightLogRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  WeightLogRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  // Access only the signed-in user's weight records.
  CollectionReference<Map<String, dynamic>> _weightCollection() {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('You must be signed in to manage weight logs.');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('weightLogs');
  }

  // Validate weight measurements before saving.
  void _validateWeight(WeightLogModel weight) {
    if (!weight.weightKg.isFinite ||
        weight.weightKg < 2 ||
        weight.weightKg > 500) {
      throw ArgumentError('Weight must be between 2 and 500 kg.');
    }

    if (weight.measuredAt.isAfter(DateTime.now())) {
      throw ArgumentError('Weight measurement date cannot be in the future.');
    }
  }

  // Add a new weight measurement.
  // Firestore generates the document ID.
  Future<String> addWeight(WeightLogModel weight) async {
    _validateWeight(weight);

    final collection = _weightCollection();

    final document = await collection.add(weight.toMap());

    return document.id;
  }

  // Load all weight measurements, newest first.
  Future<List<WeightLogModel>> getWeightLogs() async {
    final snapshot = await _weightCollection()
        .orderBy('measuredAt', descending: true)
        .get();

    return snapshot.docs.map((document) {
      return WeightLogModel.fromMap(id: document.id, map: document.data());
    }).toList();
  }

  // Load weight measurements within an inclusive
  // calendar-date range.
  Future<List<WeightLogModel>> getWeightLogsForRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final start = DateTime(startDate.year, startDate.month, startDate.day);

    final end = DateTime(endDate.year, endDate.month, endDate.day);

    if (end.isBefore(start)) {
      throw ArgumentError('End date cannot be before start date.');
    }

    // Exclusive boundary includes the whole end day.
    final endExclusive = DateTime(endDate.year, endDate.month, endDate.day + 1);

    final snapshot = await _weightCollection()
        .where('measuredAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('measuredAt', isLessThan: Timestamp.fromDate(endExclusive))
        .orderBy('measuredAt', descending: true)
        .get();

    return snapshot.docs.map((document) {
      return WeightLogModel.fromMap(id: document.id, map: document.data());
    }).toList();
  }

  // Update an existing weight measurement.
  Future<void> updateWeight(WeightLogModel weight) async {
    if (weight.id.trim().isEmpty) {
      throw ArgumentError('Weight log ID cannot be empty.');
    }

    _validateWeight(weight);

    await _weightCollection().doc(weight.id).update(weight.toMap());
  }

  // Delete a saved weight measurement.
  Future<void> deleteWeight(String weightLogId) async {
    if (weightLogId.trim().isEmpty) {
      throw ArgumentError('Weight log ID cannot be empty.');
    }

    await _weightCollection().doc(weightLogId).delete();
  }
}
