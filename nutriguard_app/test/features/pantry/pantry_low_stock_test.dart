import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguard_app/features/pantry/data/models/pantry_item_model.dart';

void main() {
  PantryItemModel createItem({double quantity = 5, double? lowStockThreshold}) {
    return PantryItemModel(
      id: 'test_pantry_item',
      name: 'Rice',
      quantity: quantity,
      unit: 'kg',
      category: 'Grains',
      createdAt: DateTime(2026, 11, 4),
      lowStockThreshold: lowStockThreshold,
    );
  }

  group('Pantry Low Stock Detection', () {
    test('returns false when no threshold is configured', () {
      final item = createItem(quantity: 1);

      expect(item.lowStockThreshold, isNull);
      expect(item.isRunningLow, isFalse);
    });

    test('returns true when quantity is below threshold', () {
      final item = createItem(quantity: 2, lowStockThreshold: 5);

      expect(item.isRunningLow, isTrue);
    });

    test('returns true when quantity equals threshold', () {
      final item = createItem(quantity: 5, lowStockThreshold: 5);

      expect(item.isRunningLow, isTrue);
    });

    test('returns false when quantity exceeds threshold', () {
      final item = createItem(quantity: 8, lowStockThreshold: 5);

      expect(item.isRunningLow, isFalse);
    });

    test('supports decimal low-stock thresholds', () {
      final item = createItem(quantity: 0.5, lowStockThreshold: 1.5);

      expect(item.isRunningLow, isTrue);
    });

    test('converts threshold to and from Firestore map', () {
      final original = createItem(quantity: 2, lowStockThreshold: 4);

      final map = original.toMap();

      expect(map['lowStockThreshold'], 4);

      final restored = PantryItemModel.fromMap(id: original.id, map: map);

      expect(restored.lowStockThreshold, 4);
      expect(restored.isRunningLow, isTrue);
    });

    test('supports older Firestore documents without threshold', () {
      final original = createItem();

      final map = original.toMap();

      expect(map.containsKey('lowStockThreshold'), isFalse);

      final restored = PantryItemModel.fromMap(id: original.id, map: map);

      expect(restored.lowStockThreshold, isNull);
      expect(restored.isRunningLow, isFalse);
    });

    test('copyWith updates threshold and preserves other fields', () {
      final original = createItem(lowStockThreshold: 2);

      final updated = original.copyWith(lowStockThreshold: 6);

      expect(updated.lowStockThreshold, 6);
      expect(updated.isRunningLow, isTrue);
      expect(updated.name, original.name);
      expect(updated.id, original.id);
      expect(original.lowStockThreshold, 2);
    });

    test('copyWith removes the low-stock threshold', () {
      final original = createItem(lowStockThreshold: 3);

      final updated = original.copyWith(clearLowStockThreshold: true);

      expect(updated.lowStockThreshold, isNull);
      expect(updated.isRunningLow, isFalse);
    });

    test('invalid thresholds do not trigger low-stock warning', () {
      final negative = createItem(quantity: 1, lowStockThreshold: -1);

      final notANumber = createItem(quantity: 1, lowStockThreshold: double.nan);

      expect(negative.isRunningLow, isFalse);
      expect(notANumber.isRunningLow, isFalse);
    });
  });
}
