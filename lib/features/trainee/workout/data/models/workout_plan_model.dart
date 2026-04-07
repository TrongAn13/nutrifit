import 'package:cloud_firestore/cloud_firestore.dart';

import 'routine_model.dart';

/// Represents a workout plan stored in the Firestore `workout_plans` collection.
///
/// Each plan contains a list of [RoutineModel] (training sessions)
/// embedded as a nested array, following NoSQL denormalization best practices.
///
/// [trainingDays] holds the selected weekdays (1 = Monday … 7 = Sunday).
/// [sessionsPerWeek] is derived from [trainingDays.length] for convenience.
class WorkoutPlanModel {
  final String planId;
  final String userId;
  final String name;
  final String description;
  final int totalWeeks;
  final List<int> trainingDays;
  final bool isActive;
  final List<RoutineModel> routines;
  final DateTime createdAt;
  final String? assignedByCoachId;
  final bool isTemplate; // True if this is a reusable template created by a coach.
  final String level; // Beginner, Intermediate, Advanced
  final String category; // Fat Loss, Muscle Gain, Strength
  final String genderTarget; // Male, Female, All
  final String imageUrl; // Banner/Thumbnail for the plan
  final String equipment; // Full Equipment, Dumbbells Only, Home, etc.

  /// Convenience getter: number of sessions equals the selected days count.
  int get sessionsPerWeek => trainingDays.length;

  const WorkoutPlanModel({
    required this.planId,
    required this.userId,
    required this.name,
    this.description = '',
    required this.totalWeeks,
    this.trainingDays = const [1, 3, 5],
    this.isActive = false,
    this.routines = const [],
    required this.createdAt,
    this.assignedByCoachId,
    this.isTemplate = false,
    this.level = 'Beginner',
    this.category = 'Muscle Gain',
    this.genderTarget = 'Male',
    this.imageUrl = '',
    this.equipment = 'Full Equipment',
  });

  // ───────────────────────── JSON Serialization ─────────────────────────

  factory WorkoutPlanModel.fromJson(Map<String, dynamic> json) {
    // Backward-compatible: if trainingDays exists use it,
    // otherwise generate default consecutive days from sessionsPerWeek/daysPerWeek.
    final List<int> days;
    if (json['trainingDays'] != null) {
      days =
          (json['trainingDays'] as List<dynamic>)
              .map((e) => (e as num).toInt())
              .toList()
            ..sort();
    } else {
      final sessions =
          (json['sessionsPerWeek'] as num?)?.toInt() ??
          (json['daysPerWeek'] as num?)?.toInt() ??
          3;
      days = List.generate(sessions, (i) => i + 1);
    }

    // Parse createdAt from both Timestamp and String formats
    DateTime parsedCreatedAt = DateTime.now();
    if (json['createdAt'] != null) {
      if (json['createdAt'] is Timestamp) {
        parsedCreatedAt = (json['createdAt'] as Timestamp).toDate();
      } else if (json['createdAt'] is String) {
        parsedCreatedAt =
            DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now();
      }
    }

    // Parse totalWeeks with fallback
    final totalWeeks = (json['totalWeeks'] as num?)?.toInt() ?? 8;

    return WorkoutPlanModel(
      planId: json['planId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? 'Chưa có tên',
      description: json['description'] as String? ?? '',
      totalWeeks: totalWeeks,
      trainingDays: days,
      isActive: json['isActive'] as bool? ?? false,
      routines:
          (json['routines'] as List<dynamic>?)
              ?.map((e) => RoutineModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: parsedCreatedAt,
      assignedByCoachId: json['assignedByCoachId'] as String?,
      isTemplate: json['isTemplate'] as bool? ?? false,
      level: json['level'] as String? ?? 'Beginner',
      category: json['category'] as String? ?? 'Muscle Gain',
      genderTarget: json['genderTarget'] as String? ?? 'Male',
      imageUrl: json['imageUrl'] as String? ?? '',
      equipment: json['equipment'] as String? ?? 'Full Equipment',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'planId': planId,
      'userId': userId,
      'name': name,
      'description': description,
      'totalWeeks': totalWeeks,
      'trainingDays': trainingDays,
      'sessionsPerWeek': sessionsPerWeek, // kept for backward compatibility
      'isActive': isActive,
      'routines': routines.map((r) => r.toJson()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      if (assignedByCoachId != null) 'assignedByCoachId': assignedByCoachId,
      'isTemplate': isTemplate,
      'level': level,
      'category': category,
      'genderTarget': genderTarget,
      'imageUrl': imageUrl,
      'equipment': equipment,
    };
  }

  // ───────────────────────── copyWith ─────────────────────────

  WorkoutPlanModel copyWith({
    String? planId,
    String? userId,
    String? name,
    String? description,
    int? totalWeeks,
    List<int>? trainingDays,
    bool? isActive,
    List<RoutineModel>? routines,
    DateTime? createdAt,
    String? assignedByCoachId,
    bool? isTemplate,
    String? level,
    String? category,
    String? genderTarget,
    String? imageUrl,
    String? equipment,
  }) {
    return WorkoutPlanModel(
      planId: planId ?? this.planId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      totalWeeks: totalWeeks ?? this.totalWeeks,
      trainingDays: trainingDays ?? this.trainingDays,
      isActive: isActive ?? this.isActive,
      routines: routines ?? this.routines,
      createdAt: createdAt ?? this.createdAt,
      assignedByCoachId: assignedByCoachId ?? this.assignedByCoachId,
      isTemplate: isTemplate ?? this.isTemplate,
      level: level ?? this.level,
      category: category ?? this.category,
      genderTarget: genderTarget ?? this.genderTarget,
      imageUrl: imageUrl ?? this.imageUrl,
      equipment: equipment ?? this.equipment,
    );
  }

  @override
  String toString() =>
      'WorkoutPlanModel(planId: $planId, name: $name, weeks: $totalWeeks, days: $trainingDays, active: $isActive)';
}
