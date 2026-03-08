import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a nutrition plan stored in the Firestore `nutrition_plans` collection.
///
/// A plan cycles through a fixed number of [cycleDays] (e.g. 7-day cycle).
/// Detailed meals/macros per day can be added as sub-collections or
/// embedded maps in future iterations.
class NutritionPlanModel {
  final String planId;
  final String userId;
  final String name;
  final int cycleDays; // number of days in one cycle (e.g. 7)
  final bool isActive;
  final DateTime createdAt;

  const NutritionPlanModel({
    required this.planId,
    required this.userId,
    required this.name,
    required this.cycleDays,
    this.isActive = false,
    required this.createdAt,
  });

  // ───────────────────────── JSON Serialization ─────────────────────────

  factory NutritionPlanModel.fromJson(Map<String, dynamic> json) {
    return NutritionPlanModel(
      planId: json['planId'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      cycleDays: json['cycleDays'] as int,
      isActive: json['isActive'] as bool? ?? false,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'planId': planId,
      'userId': userId,
      'name': name,
      'cycleDays': cycleDays,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // ───────────────────────── copyWith ─────────────────────────

  NutritionPlanModel copyWith({
    String? planId,
    String? userId,
    String? name,
    int? cycleDays,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return NutritionPlanModel(
      planId: planId ?? this.planId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      cycleDays: cycleDays ?? this.cycleDays,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'NutritionPlanModel(planId: $planId, name: $name, cycleDays: $cycleDays, active: $isActive)';
}
