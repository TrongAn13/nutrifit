import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single meal item within a nutrition plan.
class PlanMealItem {
  final String name;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final String? portion;

  const PlanMealItem({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.portion,
  });

  factory PlanMealItem.fromJson(Map<String, dynamic> json) {
    return PlanMealItem(
      name: json['name'] as String,
      calories: json['calories'] as int,
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      portion: json['portion'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'portion': portion,
      };

  PlanMealItem copyWith({
    String? name,
    int? calories,
    double? protein,
    double? carbs,
    double? fat,
    String? portion,
  }) {
    return PlanMealItem(
      name: name ?? this.name,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      portion: portion ?? this.portion,
    );
  }
}

/// Represents a day's meal plan within a nutrition plan.
class PlanDayMeals {
  final int dayIndex; // 0-indexed day number
  final String? dayName; // Optional name like "Ngày 1"
  final List<PlanMealItem> breakfast;
  final List<PlanMealItem> lunch;
  final List<PlanMealItem> dinner;
  final List<PlanMealItem> snacks;

  const PlanDayMeals({
    required this.dayIndex,
    this.dayName,
    this.breakfast = const [],
    this.lunch = const [],
    this.dinner = const [],
    this.snacks = const [],
  });

  int get totalCalories {
    int total = 0;
    for (final meal in [...breakfast, ...lunch, ...dinner, ...snacks]) {
      total += meal.calories;
    }
    return total;
  }

  factory PlanDayMeals.fromJson(Map<String, dynamic> json) {
    return PlanDayMeals(
      dayIndex: json['dayIndex'] as int,
      dayName: json['dayName'] as String?,
      breakfast: (json['breakfast'] as List<dynamic>?)
              ?.map((e) => PlanMealItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lunch: (json['lunch'] as List<dynamic>?)
              ?.map((e) => PlanMealItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      dinner: (json['dinner'] as List<dynamic>?)
              ?.map((e) => PlanMealItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      snacks: (json['snacks'] as List<dynamic>?)
              ?.map((e) => PlanMealItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'dayIndex': dayIndex,
        'dayName': dayName,
        'breakfast': breakfast.map((e) => e.toJson()).toList(),
        'lunch': lunch.map((e) => e.toJson()).toList(),
        'dinner': dinner.map((e) => e.toJson()).toList(),
        'snacks': snacks.map((e) => e.toJson()).toList(),
      };

  PlanDayMeals copyWith({
    int? dayIndex,
    String? dayName,
    List<PlanMealItem>? breakfast,
    List<PlanMealItem>? lunch,
    List<PlanMealItem>? dinner,
    List<PlanMealItem>? snacks,
  }) {
    return PlanDayMeals(
      dayIndex: dayIndex ?? this.dayIndex,
      dayName: dayName ?? this.dayName,
      breakfast: breakfast ?? this.breakfast,
      lunch: lunch ?? this.lunch,
      dinner: dinner ?? this.dinner,
      snacks: snacks ?? this.snacks,
    );
  }
}

/// Represents a nutrition plan stored in the Firestore `nutrition_plans` collection.
///
/// A plan cycles through a fixed number of [cycleDays] (e.g. 7-day cycle).
/// Detailed meals/macros per day can be added as sub-collections or
/// embedded maps in future iterations.
class NutritionPlanModel {
  final String planId;
  final String userId;
  final String name;
  final String description;
  final int cycleDays; // number of days in one cycle (e.g. 7)
  final int targetCalories; // average daily calories
  final int carbsPercent; // e.g. 40
  final int proteinPercent; // e.g. 30
  final int fatPercent; // e.g. 30
  final bool isActive;
  final List<PlanDayMeals> dailyMeals;
  final DateTime createdAt;

  const NutritionPlanModel({
    required this.planId,
    required this.userId,
    required this.name,
    this.description = '',
    required this.cycleDays,
    this.targetCalories = 2000,
    this.carbsPercent = 40,
    this.proteinPercent = 30,
    this.fatPercent = 30,
    this.isActive = false,
    this.dailyMeals = const [],
    required this.createdAt,
  });

  // ───────────────────────── JSON Serialization ─────────────────────────

  factory NutritionPlanModel.fromJson(Map<String, dynamic> json) {
    return NutritionPlanModel(
      planId: json['planId'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      cycleDays: json['cycleDays'] as int,
      targetCalories: json['targetCalories'] as int? ?? 2000,
      carbsPercent: json['carbsPercent'] as int? ?? 40,
      proteinPercent: json['proteinPercent'] as int? ?? 30,
      fatPercent: json['fatPercent'] as int? ?? 30,
      isActive: json['isActive'] as bool? ?? false,
      dailyMeals: (json['dailyMeals'] as List<dynamic>?)
              ?.map((e) => PlanDayMeals.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'planId': planId,
      'userId': userId,
      'name': name,
      'description': description,
      'cycleDays': cycleDays,
      'targetCalories': targetCalories,
      'carbsPercent': carbsPercent,
      'proteinPercent': proteinPercent,
      'fatPercent': fatPercent,
      'isActive': isActive,
      'dailyMeals': dailyMeals.map((e) => e.toJson()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // ───────────────────────── copyWith ─────────────────────────

  NutritionPlanModel copyWith({
    String? planId,
    String? userId,
    String? name,
    String? description,
    int? cycleDays,
    int? targetCalories,
    int? carbsPercent,
    int? proteinPercent,
    int? fatPercent,
    bool? isActive,
    List<PlanDayMeals>? dailyMeals,
    DateTime? createdAt,
  }) {
    return NutritionPlanModel(
      planId: planId ?? this.planId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      cycleDays: cycleDays ?? this.cycleDays,
      targetCalories: targetCalories ?? this.targetCalories,
      carbsPercent: carbsPercent ?? this.carbsPercent,
      proteinPercent: proteinPercent ?? this.proteinPercent,
      fatPercent: fatPercent ?? this.fatPercent,
      isActive: isActive ?? this.isActive,
      dailyMeals: dailyMeals ?? this.dailyMeals,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'NutritionPlanModel(planId: $planId, name: $name, cycleDays: $cycleDays, active: $isActive)';
}
