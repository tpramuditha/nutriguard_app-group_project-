import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/pantry/data/models/pantry_item_model.dart';
import 'package:nutriguard_app/features/pantry/data/repositories/pantry_repository.dart';

void main() {
  const userId = 'test_user';
  const itemId = 'eggs_001';

  late FakeFirebaseFirestore firestore;
  late PantryRepository repository;

  PantryItemModel createEggs({double quantity = 6, double? lowStockThreshold}) {
    return PantryItemModel(
      id: itemId,
      name: 'Eggs',
      quantity: quantity,
      unit: 'pcs',
      category: 'Protein',
      lowStockThreshold: lowStockThreshold,
      createdAt: DateTime(2026, 11, 6),
    );
  }

  Future<void> seedItem(PantryItemModel item) async {
    await firestore
        .collection('users')
        .doc(userId)
        .collection('pantryItems')
        .doc(item.id)
        .set(item.toMap());
  }

  Future<Map<String, dynamic>> getSavedData() async {
    final snapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('pantryItems')
        .doc(itemId)
        .get();

    return snapshot.data()!;
  }

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = PantryRepository(firestore: firestore);
  });

  group('Pantry minimum stock threshold updates', () {
    test('saves a new minimum stock threshold', () async {
      await seedItem(createEggs(quantity: 6));

      await repository.updatePantryItem(
        userId: userId,
        item: createEggs(quantity: 6, lowStockThreshold: 8),
      );

      final data = await getSavedData();

      expect(data['quantity'], 6);
      expect(data['lowStockThreshold'], 8);
    });

    test('updates an existing minimum stock threshold', () async {
      await seedItem(createEggs(quantity: 6, lowStockThreshold: 8));

      await repository.updatePantryItem(
        userId: userId,
        item: createEggs(quantity: 10, lowStockThreshold: 5),
      );

      final data = await getSavedData();

      expect(data['quantity'], 10);
      expect(data['lowStockThreshold'], 5);
    });

    test('deletes threshold when user clears the field', () async {
      await seedItem(createEggs(quantity: 6, lowStockThreshold: 8));

      await repository.updatePantryItem(
        userId: userId,
        item: createEggs(quantity: 10, lowStockThreshold: null),
      );

      final data = await getSavedData();

      expect(data['quantity'], 10);
      expect(data.containsKey('lowStockThreshold'), isFalse);
    });

    test('keeps threshold absent when it was never set', () async {
      await seedItem(createEggs(quantity: 6));

      await repository.updatePantryItem(
        userId: userId,
        item: createEggs(quantity: 10),
      );

      final data = await getSavedData();

      expect(data['quantity'], 10);
      expect(data.containsKey('lowStockThreshold'), isFalse);
    });

    test('restored item does not report low stock after clearing', () async {
      await seedItem(createEggs(quantity: 6, lowStockThreshold: 8));

      await repository.updatePantryItem(
        userId: userId,
        item: createEggs(quantity: 6, lowStockThreshold: null),
      );

      final data = await getSavedData();

      final restoredItem = PantryItemModel.fromMap(id: itemId, map: data);

      expect(restoredItem.lowStockThreshold, isNull);
      expect(restoredItem.isRunningLow, isFalse);
    });
  });
}
