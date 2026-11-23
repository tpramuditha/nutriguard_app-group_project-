import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/pantry/data/models/pantry_item_model.dart';
import 'package:nutriguard_app/features/pantry/data/repositories/pantry_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late PantryRepository repository;

  const userId = 'test_user_001';

  PantryItemModel createItem({
    String id = '',
    String name = 'Eggs',
    double quantity = 6,
    String unit = 'pcs',
    String category = 'Protein',
    DateTime? expiryDate,
  }) {
    return PantryItemModel(
      id: id,
      name: name,
      quantity: quantity,
      unit: unit,
      category: category,
      expiryDate: expiryDate,
      createdAt: DateTime.utc(2026, 11, 4, 9),
    );
  }

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = PantryRepository(firestore: firestore);
  });

  group('PantryRepository', () {
    test('adds an ingredient to Firestore', () async {
      final item = createItem();

      final documentId = await repository.addPantryItem(
        userId: userId,
        item: item,
      );

      expect(documentId, isNotEmpty);

      final document = await firestore
          .collection('users')
          .doc(userId)
          .collection('pantryItems')
          .doc(documentId)
          .get();

      expect(document.exists, isTrue);
      expect(document.data()?['name'], 'Eggs');
      expect(document.data()?['quantity'], 6);
    });

    test('retrieves saved pantry items', () async {
      await repository.addPantryItem(
        userId: userId,
        item: createItem(name: 'Rice'),
      );

      await repository.addPantryItem(
        userId: userId,
        item: createItem(name: 'Milk'),
      );

      final items = await repository.getPantryItems(userId: userId);

      expect(items.length, 2);
      expect(items.map((item) => item.name), containsAll(['Rice', 'Milk']));
      expect(items.every((item) => item.id.isNotEmpty), isTrue);
    });

    test('returns an empty list when pantry is empty', () async {
      final items = await repository.getPantryItems(userId: userId);

      expect(items, isEmpty);
    });

    test('updates an existing pantry ingredient', () async {
      final documentId = await repository.addPantryItem(
        userId: userId,
        item: createItem(),
      );

      final updatedItem = createItem(
        id: documentId,
        name: 'Eggs',
        quantity: 12,
      );

      await repository.updatePantryItem(userId: userId, item: updatedItem);

      final items = await repository.getPantryItems(userId: userId);

      expect(items.length, 1);
      expect(items.first.quantity, 12);
    });

    test('deletes an ingredient from Firestore', () async {
      final documentId = await repository.addPantryItem(
        userId: userId,
        item: createItem(),
      );

      await repository.deletePantryItem(userId: userId, itemId: documentId);

      final items = await repository.getPantryItems(userId: userId);

      expect(items, isEmpty);
    });

    test('keeps different users pantry items separate', () async {
      await repository.addPantryItem(
        userId: 'user_A',
        item: createItem(name: 'Rice'),
      );

      await repository.addPantryItem(
        userId: 'user_B',
        item: createItem(name: 'Milk'),
      );

      final userAItems = await repository.getPantryItems(userId: 'user_A');

      final userBItems = await repository.getPantryItems(userId: 'user_B');

      expect(userAItems.length, 1);
      expect(userAItems.first.name, 'Rice');

      expect(userBItems.length, 1);
      expect(userBItems.first.name, 'Milk');
    });

    test('rejects an ingredient with an empty name', () async {
      await expectLater(
        repository.addPantryItem(
          userId: userId,
          item: createItem(name: '  '),
        ),
        throwsArgumentError,
      );
    });

    test('rejects zero and negative quantities', () async {
      for (final quantity in [0.0, -1.0]) {
        await expectLater(
          repository.addPantryItem(
            userId: userId,
            item: createItem(quantity: quantity),
          ),
          throwsArgumentError,
        );
      }
    });

    test('rejects invalid quantities such as NaN', () async {
      await expectLater(
        repository.addPantryItem(
          userId: userId,
          item: createItem(quantity: double.nan),
        ),
        throwsArgumentError,
      );
    });

    test('rejects an empty user ID', () async {
      await expectLater(
        repository.getPantryItems(userId: ''),
        throwsArgumentError,
      );
    });

    test('rejects updates without a document ID', () async {
      await expectLater(
        repository.updatePantryItem(userId: userId, item: createItem()),
        throwsArgumentError,
      );
    });

    test('rejects deletion without a document ID', () async {
      await expectLater(
        repository.deletePantryItem(userId: userId, itemId: ''),
        throwsArgumentError,
      );
    });

    test('preserves ingredient expiry date', () async {
      final expiryDate = DateTime.utc(2026, 11, 10);

      await repository.addPantryItem(
        userId: userId,
        item: createItem(expiryDate: expiryDate),
      );

      final items = await repository.getPantryItems(userId: userId);

      expect(items.first.expiryDate!.isAtSameMomentAs(expiryDate), isTrue);
    });
  });
}
