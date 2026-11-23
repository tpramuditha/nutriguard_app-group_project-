import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguard_app/features/pantry/data/models/pantry_item_model.dart';

void main() {
  final createdAt = DateTime.utc(2026, 11, 4, 9);

  PantryItemModel createItem({DateTime? expiryDate, double quantity = 2}) {
    return PantryItemModel(
      id: 'pantry_001',
      name: 'Eggs',
      quantity: quantity,
      unit: 'pcs',
      category: 'Protein',
      expiryDate: expiryDate,
      createdAt: createdAt,
    );
  }

  DateTime dateFromToday(int days) {
    final now = DateTime.now();

    return DateTime(now.year, now.month, now.day + days);
  }

  group('PantryItemModel', () {
    test('creates a pantry item with required fields', () {
      final item = createItem();

      expect(item.id, 'pantry_001');
      expect(item.name, 'Eggs');
      expect(item.quantity, 2);
      expect(item.unit, 'pcs');
      expect(item.category, 'Protein');
      expect(item.expiryDate, isNull);
    });

    test('converts a pantry item to Firestore map', () {
      final expiryDate = DateTime.utc(2026, 11, 10);
      final item = createItem(expiryDate: expiryDate);

      final map = item.toMap();

      expect(map['name'], 'Eggs');
      expect(map['quantity'], 2);
      expect(map['unit'], 'pcs');
      expect(map['category'], 'Protein');
      expect(map['expiryDate'], isA<Timestamp>());
      expect(map['createdAt'], isA<Timestamp>());
      expect(map.containsKey('id'), isFalse);
    });

    test('restores a pantry item from Firestore map', () {
      final original = createItem(expiryDate: DateTime.utc(2026, 11, 10));

      final restored = PantryItemModel.fromMap(
        id: original.id,
        map: original.toMap(),
      );

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.quantity, original.quantity);
      expect(restored.unit, original.unit);
      expect(restored.category, original.category);

      expect(
        restored.expiryDate!.isAtSameMomentAs(original.expiryDate!),
        isTrue,
      );

      expect(restored.createdAt.isAtSameMomentAs(original.createdAt), isTrue);
    });

    test('supports items without an expiry date', () {
      final original = createItem();

      final restored = PantryItemModel.fromMap(
        id: original.id,
        map: original.toMap(),
      );

      expect(restored.expiryDate, isNull);
      expect(restored.isExpired, isFalse);
      expect(restored.isExpiringSoon, isFalse);
    });

    test('identifies expired pantry items', () {
      final item = createItem(expiryDate: dateFromToday(-2));

      expect(item.isExpired, isTrue);
      expect(item.isExpiringSoon, isFalse);
    });

    test('identifies pantry items expiring today', () {
      final item = createItem(expiryDate: dateFromToday(0));

      expect(item.isExpired, isFalse);
      expect(item.isExpiringSoon, isTrue);
    });

    test('identifies pantry items expiring within 3 days', () {
      final item = createItem(expiryDate: dateFromToday(3));

      expect(item.isExpired, isFalse);
      expect(item.isExpiringSoon, isTrue);
    });

    test('does not flag items expiring after 3 days', () {
      final item = createItem(expiryDate: dateFromToday(5));

      expect(item.isExpired, isFalse);
      expect(item.isExpiringSoon, isFalse);
    });

    test('copyWith updates quantity without losing other data', () {
      final original = createItem();

      final updated = original.copyWith(quantity: 5);

      expect(updated.quantity, 5);
      expect(updated.name, original.name);
      expect(updated.id, original.id);
      expect(updated.createdAt, original.createdAt);
    });

    test('copyWith updates ingredient details', () {
      final original = createItem();

      final updated = original.copyWith(
        name: 'Milk',
        quantity: 1.5,
        unit: 'L',
        category: 'Dairy',
      );

      expect(updated.name, 'Milk');
      expect(updated.quantity, 1.5);
      expect(updated.unit, 'L');
      expect(updated.category, 'Dairy');
    });

    test('copyWith can remove expiry date', () {
      final original = createItem(expiryDate: dateFromToday(2));

      final updated = original.copyWith(clearExpiryDate: true);

      expect(updated.expiryDate, isNull);
    });
  });
}
