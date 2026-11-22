import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/profile_preferences_model.dart';
import '../models/notification_preferences_model.dart';

class ProfilePreferencesRepository {
  final FirebaseFirestore _firestore;

  ProfilePreferencesRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _profileDocument(String userId) {
    _validateUserId(userId);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('preferences')
        .doc('profile');
  }

  DocumentReference<Map<String, dynamic>> _notificationDocument(String userId) {
    _validateUserId(userId);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('preferences')
        .doc('notifications');
  }

  void _validateUserId(String userId) {
    if (userId.trim().isEmpty) {
      throw ArgumentError('A valid user ID is required.');
    }
  }

  // Load dietary restrictions, allergies and unit system.
  Future<ProfilePreferencesModel> getProfilePreferences({
    required String userId,
  }) async {
    final snapshot = await _profileDocument(userId).get();

    if (!snapshot.exists || snapshot.data() == null) {
      return ProfilePreferencesModel.defaultPreferences;
    }

    return ProfilePreferencesModel.fromMap(snapshot.data()!);
  }

  // Save dietary restrictions, allergies and unit system.
  Future<void> saveProfilePreferences({
    required String userId,
    required ProfilePreferencesModel preferences,
  }) async {
    final restrictions = preferences.dietaryRestrictions;
    final allergies = preferences.allergies;

    final validRestrictions =
        restrictions.isNotEmpty &&
        restrictions.every(
          ProfilePreferencesModel.allowedRestrictions.contains,
        ) &&
        !(restrictions.contains('None') && restrictions.length > 1);

    if (!validRestrictions) {
      throw ArgumentError('Invalid dietary restrictions.');
    }

    if (allergies.length > 30 ||
        allergies.any((allergy) => allergy.trim().isEmpty)) {
      throw ArgumentError('Invalid allergy list.');
    }

    if (!ProfilePreferencesModel.allowedUnitSystems.contains(
      preferences.unitSystem,
    )) {
      throw ArgumentError('Invalid unit system.');
    }

    await _profileDocument(userId).set(preferences.toMap());
  }

  // Load notification preferences.
  Future<NotificationPreferencesModel> getNotificationPreferences({
    required String userId,
  }) async {
    final snapshot = await _notificationDocument(userId).get();

    if (!snapshot.exists || snapshot.data() == null) {
      return NotificationPreferencesModel.defaultPreferences;
    }

    return NotificationPreferencesModel.fromMap(snapshot.data()!);
  }

  // Save notification preferences.
  Future<void> saveNotificationPreferences({
    required String userId,
    required NotificationPreferencesModel preferences,
  }) async {
    await _notificationDocument(userId).set(preferences.toMap());
  }
}
