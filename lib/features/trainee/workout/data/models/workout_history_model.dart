import 'package:cloud_firestore/cloud_firestore.dart';

import 'routine_model.dart';

/// Represents a completed workout session.
class WorkoutHistoryModel {
  final String id;
  final String userId;
  final String? planId; // ID of the plan this workout belongs to
  final String routineName;
  final DateTime date;
  final int durationSeconds; // Total duration in seconds
  final int restTimeSeconds; // Total rest time in seconds
  final int caloriesBurned;
  final double completionPercentage; // e.g. 100 for 100%
  final double totalWeightLifted; // in kg
  final int totalReps;
  final List<ExerciseEntry> exercises;

  const WorkoutHistoryModel({
    required this.id,
    required this.userId,
    this.planId,
    required this.routineName,
    required this.date,
    required this.durationSeconds,
    required this.restTimeSeconds,
    required this.caloriesBurned,
    required this.completionPercentage,
    required this.totalWeightLifted,
    required this.totalReps,
    this.exercises = const [],
  });

  factory WorkoutHistoryModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate = DateTime.now();
    if (json['date'] != null) {
      if (json['date'] is Timestamp) {
        parsedDate = (json['date'] as Timestamp).toDate();
      } else if (json['date'] is String) {
        parsedDate =
            DateTime.tryParse(json['date'] as String) ?? DateTime.now();
      }
    }

    return WorkoutHistoryModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      planId: json['planId'] as String?,
      routineName: json['routineName'] as String? ?? '',
      date: parsedDate,
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      restTimeSeconds: json['restTimeSeconds'] as int? ?? 0,
      caloriesBurned: json['caloriesBurned'] as int? ?? 0,
      completionPercentage:
          (json['completionPercentage'] as num?)?.toDouble() ?? 0.0,
      totalWeightLifted: (json['totalWeightLifted'] as num?)?.toDouble() ?? 0.0,
      totalReps: json['totalReps'] as int? ?? 0,
      exercises:
          (json['exercises'] as List<dynamic>?)
              ?.map((e) => ExerciseEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      if (planId != null) 'planId': planId,
      'routineName': routineName,
      'date': Timestamp.fromDate(date),
      'durationSeconds': durationSeconds,
      'restTimeSeconds': restTimeSeconds,
      'caloriesBurned': caloriesBurned,
      'completionPercentage': completionPercentage,
      'totalWeightLifted': totalWeightLifted,
      'totalReps': totalReps,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }

  WorkoutHistoryModel copyWith({
    String? id,
    String? userId,
    String? planId,
    String? routineName,
    DateTime? date,
    int? durationSeconds,
    int? restTimeSeconds,
    int? caloriesBurned,
    double? completionPercentage,
    double? totalWeightLifted,
    int? totalReps,
    List<ExerciseEntry>? exercises,
  }) {
    return WorkoutHistoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      planId: planId ?? this.planId,
      routineName: routineName ?? this.routineName,
      date: date ?? this.date,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      restTimeSeconds: restTimeSeconds ?? this.restTimeSeconds,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      totalWeightLifted: totalWeightLifted ?? this.totalWeightLifted,
      totalReps: totalReps ?? this.totalReps,
      exercises: exercises ?? this.exercises,
    );
  }
}
