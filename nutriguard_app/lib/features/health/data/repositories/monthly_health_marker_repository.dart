import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/monthly_health_marker_model.dart';

class MonthlyHealthMarkerRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  MonthlyHealthMarkerRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _markersCollection() {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError(
        'You must be signed in to access monthly health markers.',
      );
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('monthlyHealthMarkers');
  }

  Future<void> saveMarkers(MonthlyHealthMarkerModel markers) async {
    final document = _markersCollection().doc(markers.month);

    if (markers.measurements.isEmpty) {
      throw ArgumentError('Enter at least one measurement.');
    }

    final incomingNames = markers.measurements.map((m) => m.name).toList();

    if (incomingNames.toSet().length != incomingNames.length) {
      throw ArgumentError('Duplicate measurement names are not allowed.');
    }

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(document);

      if (!snapshot.exists) {
        transaction.set(document, markers.toMap());
        return;
      }

      final existing = MonthlyHealthMarkerModel.fromMap(snapshot.data()!);

      final merged = {
        for (final measurement in existing.measurements)
          measurement.name: measurement,
      };

      for (final measurement in markers.measurements) {
        merged[measurement.name] = measurement;
      }

      if (merged.length > 7) {
        throw StateError(
          'A month cannot contain more than 7 different measurements.',
        );
      }

      final updated = MonthlyHealthMarkerModel(
        month: markers.month,
        measurements: merged.values.toList(),
      );

      transaction.set(document, updated.toMap());
    });
  }

  Future<MonthlyHealthMarkerModel?> getMarkers(String month) async {
    final document = await _markersCollection().doc(month).get();

    if (!document.exists) {
      return null;
    }

    return MonthlyHealthMarkerModel.fromMap(document.data()!);
  }

  Future<List<MonthlyHealthMarkerModel>> getMarkersForRange({
    required DateTime startMonth,
    required DateTime endMonth,
  }) async {
    final start = DateTime(startMonth.year, startMonth.month);

    final end = DateTime(endMonth.year, endMonth.month);

    if (end.isBefore(start)) {
      throw ArgumentError('End month cannot be before start month.');
    }

    final monthIds = <String>[];

    var current = start;

    while (!current.isAfter(end)) {
      final monthId =
          '${current.year}-'
          '${current.month.toString().padLeft(2, '0')}';

      monthIds.add(monthId);

      current = DateTime(current.year, current.month + 1);
    }

    // Reuse the existing authenticated Firestore method.
    final results = await Future.wait(
      monthIds.map((monthId) => getMarkers(monthId)),
    );

    // Months without saved records are excluded.
    return results.whereType<MonthlyHealthMarkerModel>().toList();
  }
}
