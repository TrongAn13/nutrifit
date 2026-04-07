import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a food item in the Firestore `foods` collection.
///
/// Foods can be system-provided ([isSystem] = true) or trainee-created.
class FoodModel {
  final String foodId;
  final String? userId; // null for system foods
  final String name;
  final String category; // e.g. 'Thịt', 'Rau', 'Ngũ cốc'
  final double calories; // per serving (kcal)
  final double protein; // grams
  final double fat; // grams
  final double carbs; // grams
  final String? imageUrl;
  final bool isSystem;
  final DateTime createdAt;

  const FoodModel({
    required this.foodId,
    this.userId,
    required this.name,
    required this.category,
    this.calories = 0,
    this.protein = 0,
    this.fat = 0,
    this.carbs = 0,
    this.imageUrl,
    this.isSystem = false,
    required this.createdAt,
  });

  // ───────────────────────── JSON Serialization ─────────────────────────

  factory FoodModel.fromJson(Map<String, dynamic> json) {
    return FoodModel(
      foodId: json['foodId'] as String? ?? '',
      userId: json['userId'] as String?,
      // Thêm as String? ?? '' để nếu Firebase không có dữ liệu, nó tự gán chuỗi rỗng
      name: json['name'] as String? ?? 'Chưa có tên',
      category: json['category'] as String? ?? 'Chưa phân loại',

      calories: (json['calories'] as num?)?.toDouble() ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
      imageUrl: json['imageUrl'] as String?,
      isSystem: json['isSystem'] as bool? ?? false,

      // Xử lý an toàn cho Timestamp phòng trường hợp cache offline bị null
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'foodId': foodId,
      'userId': userId,
      'name': name,
      'category': category,
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'carbs': carbs,
      'imageUrl': imageUrl,
      'isSystem': isSystem,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // ───────────────────────── copyWith ─────────────────────────

  FoodModel copyWith({
    String? foodId,
    String? userId,
    String? name,
    String? category,
    double? calories,
    double? protein,
    double? fat,
    double? carbs,
    String? imageUrl,
    bool? isSystem,
    DateTime? createdAt,
  }) {
    return FoodModel(
      foodId: foodId ?? this.foodId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      category: category ?? this.category,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      carbs: carbs ?? this.carbs,
      imageUrl: imageUrl ?? this.imageUrl,
      isSystem: isSystem ?? this.isSystem,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'FoodModel(name: $name, cal: $calories, system: $isSystem)';
}
