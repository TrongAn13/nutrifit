import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../nutrition/data/models/water_entry_model.dart';

/// Represents a daily tracking log stored in the Firestore `daily_logs` collection.
///
/// Each document corresponds to one day for one user, capturing
/// calorie intake, macronutrient totals, meal entries, and workout status.
class DailyLogModel {
  final String logId;
  final String userId;
  final DateTime date;
  final double totalCaloriesIn;
  final double totalProtein;
  final double totalFat;
  final double totalCarbs;
  final double caloriesGoal;
  final double proteinGoal;
  final double fatGoal;
  final double carbsGoal;
  final bool workoutCompleted;
  final List<MealEntry> meals;
  final List<WaterEntryModel> waterEntries;
  final int waterGoalMl;
  final String? notes;

  const DailyLogModel({
    required this.logId,
    required this.userId,
    required this.date,
    this.totalCaloriesIn = 0,
    this.totalProtein = 0,
    this.totalFat = 0,
    this.totalCarbs = 0,
    this.caloriesGoal = 2200,
    this.proteinGoal = 150,
    this.fatGoal = 70,
    this.carbsGoal = 250,
    this.workoutCompleted = false,
    this.meals = const [],
    this.waterEntries = const [],
    this.waterGoalMl = 2500,
    this.notes,
  });

  // ───────────────────────── JSON Serialization ─────────────────────────

  factory DailyLogModel.fromJson(Map<String, dynamic> json) {
    return DailyLogModel(
      logId: json['logId'] as String,
      userId: json['userId'] as String,
      date: (json['date'] as Timestamp).toDate(),
      totalCaloriesIn: (json['totalCaloriesIn'] as num?)?.toDouble() ?? 0,
      totalProtein: (json['totalProtein'] as num?)?.toDouble() ?? 0,
      totalFat: (json['totalFat'] as num?)?.toDouble() ?? 0,
      totalCarbs: (json['totalCarbs'] as num?)?.toDouble() ?? 0,
      caloriesGoal: (json['caloriesGoal'] as num?)?.toDouble() ?? 2200,
      proteinGoal: (json['proteinGoal'] as num?)?.toDouble() ?? 150,
      fatGoal: (json['fatGoal'] as num?)?.toDouble() ?? 70,
      carbsGoal: (json['carbsGoal'] as num?)?.toDouble() ?? 250,
      workoutCompleted: json['workoutCompleted'] as bool? ?? false,
      meals: (json['meals'] as List<dynamic>?)
              ?.map((e) => MealEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      waterEntries: (json['waterEntries'] as List<dynamic>?)
              ?.map((e) => WaterEntryModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      waterGoalMl: (json['waterGoalMl'] as num?)?.toInt() ?? 2500,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'logId': logId,
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'totalCaloriesIn': totalCaloriesIn,
      'totalProtein': totalProtein,
      'totalFat': totalFat,
      'totalCarbs': totalCarbs,
      'caloriesGoal': caloriesGoal,
      'proteinGoal': proteinGoal,
      'fatGoal': fatGoal,
      'carbsGoal': carbsGoal,
      'workoutCompleted': workoutCompleted,
      'meals': meals.map((m) => m.toJson()).toList(),
      'waterEntries': waterEntries.map((w) => w.toJson()).toList(),
      'waterGoalMl': waterGoalMl,
      'notes': notes,
    };
  }

  // ───────────────────────── copyWith ─────────────────────────

  DailyLogModel copyWith({
    String? logId,
    String? userId,
    DateTime? date,
    double? totalCaloriesIn,
    double? totalProtein,
    double? totalFat,
    double? totalCarbs,
    double? caloriesGoal,
    double? proteinGoal,
    double? fatGoal,
    double? carbsGoal,
    bool? workoutCompleted,
    List<MealEntry>? meals,
    List<WaterEntryModel>? waterEntries,
    int? waterGoalMl,
    String? notes,
  }) {
    return DailyLogModel(
      logId: logId ?? this.logId,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      totalCaloriesIn: totalCaloriesIn ?? this.totalCaloriesIn,
      totalProtein: totalProtein ?? this.totalProtein,
      totalFat: totalFat ?? this.totalFat,
      totalCarbs: totalCarbs ?? this.totalCarbs,
      caloriesGoal: caloriesGoal ?? this.caloriesGoal,
      proteinGoal: proteinGoal ?? this.proteinGoal,
      fatGoal: fatGoal ?? this.fatGoal,
      carbsGoal: carbsGoal ?? this.carbsGoal,
      workoutCompleted: workoutCompleted ?? this.workoutCompleted,
      meals: meals ?? this.meals,
      waterEntries: waterEntries ?? this.waterEntries,
      waterGoalMl: waterGoalMl ?? this.waterGoalMl,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() =>
      'DailyLogModel(logId: $logId, date: $date, calories: $totalCaloriesIn, trained: $workoutCompleted)';
}

/// A single meal entry within a [DailyLogModel].
///
/// Stored as a nested map inside the `meals` array of the `daily_logs` document.
class MealEntry {
  final String mealId;
  final String mealType; // 'breakfast', 'lunch', 'dinner', 'snack'
  final String name;
  final double calories;
  final double protein;
  final double fat;
  final double carbs;

  const MealEntry({
    required this.mealId,
    required this.mealType,
    required this.name,
    this.calories = 0,
    this.protein = 0,
    this.fat = 0,
    this.carbs = 0,
  });

  factory MealEntry.fromJson(Map<String, dynamic> json) {
    return MealEntry(
      mealId: json['mealId'] as String,
      mealType: json['mealType'] as String,
      name: json['name'] as String,
      calories: (json['calories'] as num?)?.toDouble() ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mealId': mealId,
      'mealType': mealType,
      'name': name,
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'carbs': carbs,
    };
  }

  MealEntry copyWith({
    String? mealId,
    String? mealType,
    String? name,
    double? calories,
    double? protein,
    double? fat,
    double? carbs,
  }) {
    return MealEntry(
      mealId: mealId ?? this.mealId,
      mealType: mealType ?? this.mealType,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      carbs: carbs ?? this.carbs,
    );
  }

  @override
  String toString() => 'MealEntry(name: $name, cal: $calories)';
}
