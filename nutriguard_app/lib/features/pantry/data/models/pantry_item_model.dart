import 'package:cloud_firestore/cloud_firestore.dart';

class PantryItemModel {
  final String id;
  final String name;
  final double quantity;
  final String unit;
  final String category;
  final DateTime? expiryDate;
  final DateTime createdAt;

  // NEW: Optional ingredient-specific minimum stock.
  final double? lowStockThreshold;

  const PantryItemModel({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.category,
    this.expiryDate,
    required this.createdAt,
    this.lowStockThreshold,
  });

  bool get isExpired {
    if (expiryDate == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return expiryDate!.isBefore(today);
  }

  bool get isExpiringSoon {
    if (expiryDate == null || isExpired) {
      return false;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final difference = expiryDate!.difference(today).inDays;

    return difference >= 0 && difference <= 3;
  }

  // NEW: Only report Running Low if a threshold is configured.
  bool get isRunningLow {
    final threshold = lowStockThreshold;

    if (threshold == null) {
      return false;
    }

    if (!threshold.isFinite || threshold < 0) {
      return false;
    }

    return quantity <= threshold;
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'category': category,
      'expiryDate': expiryDate == null ? null : Timestamp.fromDate(expiryDate!),
      'createdAt': Timestamp.fromDate(createdAt),
    };

    // Backward compatible with existing Firestore rules.
    // Do not send the new field until it has a value.
    if (lowStockThreshold != null) {
      map['lowStockThreshold'] = lowStockThreshold;
    }

    return map;
  }

  factory PantryItemModel.fromMap({
    required String id,
    required Map<String, dynamic> map,
  }) {
    return PantryItemModel(
      id: id,
      name: map['name'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String,
      category: map['category'] as String,
      expiryDate: map['expiryDate'] == null
          ? null
          : (map['expiryDate'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lowStockThreshold: map['lowStockThreshold'] == null
          ? null
          : (map['lowStockThreshold'] as num).toDouble(),
    );
  }

  PantryItemModel copyWith({
    String? name,
    double? quantity,
    String? unit,
    String? category,
    DateTime? expiryDate,
    bool clearExpiryDate = false,
    double? lowStockThreshold,
    bool clearLowStockThreshold = false,
  }) {
    return PantryItemModel(
      id: id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      expiryDate: clearExpiryDate ? null : (expiryDate ?? this.expiryDate),
      createdAt: createdAt,
      lowStockThreshold: clearLowStockThreshold
          ? null
          : (lowStockThreshold ?? this.lowStockThreshold),
    );
  }
}
