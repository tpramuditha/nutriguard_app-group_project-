import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

typedef TemporaryDirectoryProvider = Future<Directory> Function();

class UserDataExportService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final TemporaryDirectoryProvider _temporaryDirectoryProvider;

  UserDataExportService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    TemporaryDirectoryProvider? temporaryDirectoryProvider,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _temporaryDirectoryProvider =
           temporaryDirectoryProvider ?? getTemporaryDirectory;

  static const List<String> _collections = [
    'foodLogs',
    'healthReports',
    'monthlyHealthMarkers',
    'pantryItems',
    'plannedMeals',
    'exerciseLogs',
    'weeklyExercisePlans',
    'weightLogs',
  ];

  static const List<String> _preferences = [
    'nutrition',
    'profile',
    'notifications',
  ];

  Future<File> createExportFile() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('Please log in to export your data.');
    }

    final userRef = _firestore.collection('users').doc(user.uid);

    final rows = <List<String>>[
      ['category', 'documentId', 'dataJson'],
    ];

    for (final collectionName in _collections) {
      final snapshot = await userRef.collection(collectionName).get();

      for (final document in snapshot.docs) {
        rows.add([
          _categoryName(collectionName),
          document.id,
          jsonEncode(_normalize(document.data())),
        ]);
      }
    }

    for (final preferenceName in _preferences) {
      final snapshot = await userRef
          .collection('preferences')
          .doc(preferenceName)
          .get();

      if (snapshot.exists) {
        rows.add([
          'Personal Preferences',
          preferenceName,
          jsonEncode(_normalize(snapshot.data() ?? {})),
        ]);
      }
    }

    final csvContent = rows.map(_encodeCsvRow).join('\r\n');
    final content = '\uFEFF$csvContent';

    final directory = await _temporaryDirectoryProvider();

    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');

    final file = File(p.join(directory.path, 'nutriguard_data_$timestamp.csv'));

    await file.writeAsString(content, encoding: utf8, flush: true);

    return file;
  }

  Future<ShareResult> shareExportFile(File file) async {
    if (!await file.exists()) {
      throw StateError('The export file could not be found.');
    }

    return SharePlus.instance.share(
      ShareParams(
        title: 'NutriGuard Data Export',
        subject: 'My NutriGuard Data',
        text: 'My personal NutriGuard data export.',
        files: [XFile(file.path, mimeType: 'text/csv')],
      ),
    );
  }

  String _categoryName(String collectionName) {
    const categories = {
      'foodLogs': 'Food History',
      'healthReports': 'Health Reports',
      'monthlyHealthMarkers': 'Monthly Health Markers',
      'pantryItems': 'My Pantry',
      'plannedMeals': 'Meal Plans',
      'exerciseLogs': 'Exercise Records',
      'weeklyExercisePlans': 'Weekly Exercise Plans',
      'weightLogs': 'Weight Records',
    };

    return categories[collectionName] ?? collectionName;
  }

  String _encodeCsvRow(List<String> values) {
    return values
        .map((value) {
          final escaped = value.replaceAll('"', '""');
          return '"$escaped"';
        })
        .join(',');
  }

  dynamic _normalize(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toUtc().toIso8601String();
    }

    if (value is DateTime) {
      return value.toUtc().toIso8601String();
    }

    if (value is GeoPoint) {
      return {'latitude': value.latitude, 'longitude': value.longitude};
    }

    if (value is DocumentReference) {
      return value.path;
    }

    if (value is Blob) {
      return base64Encode(value.bytes);
    }

    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(key.toString(), _normalize(item)),
      );
    }

    if (value is Iterable) {
      return value.map(_normalize).toList();
    }

    return value;
  }
}
