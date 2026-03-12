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
  });

  // ───────────────────────── JSON Serialization ─────────────────────────

  factory WorkoutPlanModel.fromJson(Map<String, dynamic> json) {
    // Backward-compatible: if trainingDays exists use it,
    // otherwise generate default consecutive days from old sessionsPerWeek.
    final List<int> days;
    if (json['trainingDays'] != null) {
      days =
          (json['trainingDays'] as List<dynamic>)
              .map((e) => (e as num).toInt())
              .toList()
            ..sort();
    } else {
      final sessions = json['sessionsPerWeek'] as int? ?? 3;
      days = List.generate(sessions, (i) => i + 1); // [1, 2, ..., sessions]
    }

    return WorkoutPlanModel(
      planId: json['planId'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      totalWeeks: json['totalWeeks'] as int,
      trainingDays: days,
      isActive: json['isActive'] as bool? ?? false,
      routines:
          (json['routines'] as List<dynamic>?)
              ?.map((e) => RoutineModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      assignedByCoachId: json['assignedByCoachId'] as String?,
      isTemplate: json['isTemplate'] as bool? ?? false,
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
    );
  }

  @override
  String toString() =>
      'WorkoutPlanModel(planId: $planId, name: $name, weeks: $totalWeeks, days: $trainingDays, active: $isActive)';
}
