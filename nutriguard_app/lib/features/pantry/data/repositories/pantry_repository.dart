import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/pantry_item_model.dart';

class PantryRepository {
  final FirebaseFirestore _firestore;

  PantryRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _pantryItems(String userId) {
    if (userId.trim().isEmpty) {
      throw ArgumentError('A valid user ID is required.');
    }

    return _firestore.collection('users').doc(userId).collection('pantryItems');
  }

  void _validateItem(PantryItemModel item) {
    if (item.name.trim().isEmpty) {
      throw ArgumentError('Ingredient name is required.');
    }

    if (item.name.trim().length > 100) {
      throw ArgumentError('Ingredient name cannot exceed 100 characters.');
    }

    if (!item.quantity.isFinite || item.quantity <= 0) {
      throw ArgumentError('Ingredient quantity must be greater than zero.');
    }

    if (item.unit.trim().isEmpty) {
      throw ArgumentError('Ingredient unit is required.');
    }

    if (item.category.trim().isEmpty) {
      throw ArgumentError('Ingredient category is required.');
    }
  }

  // CREATE: Add an ingredient to the user's pantry.
  Future<String> addPantryItem({
    required String userId,
    required PantryItemModel item,
  }) async {
    _validateItem(item);

    final collection = _pantryItems(userId);

    final document = await collection.add(item.toMap());

    return document.id;
  }

  // READ: Retrieve all pantry items.
  Future<List<PantryItemModel>> getPantryItems({required String userId}) async {
    final snapshot = await _pantryItems(userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((document) {
      return PantryItemModel.fromMap(id: document.id, map: document.data());
    }).toList();
  }

  // STREAM: Automatically receive Firestore updates.
  Stream<List<PantryItemModel>> watchPantryItems({required String userId}) {
    return _pantryItems(
      userId,
    ).orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((document) {
        return PantryItemModel.fromMap(id: document.id, map: document.data());
      }).toList();
    });
  }

  // UPDATE: Edit an existing ingredient.
  Future<void> updatePantryItem({
    required String userId,
    required PantryItemModel item,
  }) async {
    _validateItem(item);

    if (item.id.trim().isEmpty) {
      throw ArgumentError('A pantry document ID is required for updates.');
    }

    final updateData = item.toMap();

    if (item.lowStockThreshold == null) {
      updateData['lowStockThreshold'] = FieldValue.delete();
    }

    await _pantryItems(userId).doc(item.id).update(updateData);
  }

  // DELETE: Remove an ingredient.
  Future<void> deletePantryItem({
    required String userId,
    required String itemId,
  }) async {
    if (itemId.trim().isEmpty) {
      throw ArgumentError('A pantry document ID is required.');
    }

    await _pantryItems(userId).doc(itemId).delete();
  }
}
