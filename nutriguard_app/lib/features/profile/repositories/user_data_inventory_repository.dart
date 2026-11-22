import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserDataInventory {
  final Map<String, int> collectionCounts;
  final Map<String, bool> preferenceDocuments;

  const UserDataInventory({
    required this.collectionCounts,
    required this.preferenceDocuments,
  });

  int get totalRecords =>
      collectionCounts.values.fold(
        0,
        (total, recordCount) => total + recordCount,
      ) +
      preferenceDocuments.values.where((exists) => exists).length;
}

class UserDataInventoryRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  UserDataInventoryRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  Future<UserDataInventory> getInventory() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('Please log in to view your stored data.');
    }

    final userRef = _firestore.collection('users').doc(user.uid);

    const collectionNames = [
      'healthReports',
      'monthlyHealthMarkers',
      'foodLogs',
      'pantryItems',
      'plannedMeals',
      'exerciseLogs',
      'weightLogs',
      'weeklyExercisePlans',
    ];

    final countResults = await Future.wait(
      collectionNames.map((name) async {
        final snapshot = await userRef.collection(name).count().get();
        return MapEntry(name, snapshot.count ?? 0);
      }),
    );

    const preferenceNames = ['nutrition', 'profile', 'notifications'];

    final preferenceResults = await Future.wait(
      preferenceNames.map((name) async {
        final snapshot = await userRef
            .collection('preferences')
            .doc(name)
            .get();

        return MapEntry(name, snapshot.exists);
      }),
    );

    return UserDataInventory(
      collectionCounts: Map.fromEntries(countResults),
      preferenceDocuments: Map.fromEntries(preferenceResults),
    );
  }
}
