/// Represents a single workout routine (training session) inside a [WorkoutPlanModel].
///
/// Stored as a nested map within the `routines` array of the Firestore
/// `workout_plans` document — NOT as a separate collection.
class RoutineModel {
  final String routineId;
  final String name;
  final int dayOfWeek; // 1 = Monday … 7 = Sunday
  final List<ExerciseEntry> exercises;

  const RoutineModel({
    required this.routineId,
    required this.name,
    required this.dayOfWeek,
    this.exercises = const [],
  });

  // ───────────────────────── JSON Serialization ─────────────────────────

  factory RoutineModel.fromJson(Map<String, dynamic> json) {
    return RoutineModel(
      routineId: json['routineId'] as String,
      name: json['name'] as String,
      dayOfWeek: json['dayOfWeek'] as int,
      exercises:
          (json['exercises'] as List<dynamic>?)
              ?.map((e) => ExerciseEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'routineId': routineId,
      'name': name,
      'dayOfWeek': dayOfWeek,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }

  // ───────────────────────── copyWith ─────────────────────────

  RoutineModel copyWith({
    String? routineId,
    String? name,
    int? dayOfWeek,
    List<ExerciseEntry>? exercises,
  }) {
    return RoutineModel(
      routineId: routineId ?? this.routineId,
      name: name ?? this.name,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      exercises: exercises ?? this.exercises,
    );
  }

  @override
  String toString() =>
      'RoutineModel(routineId: $routineId, name: $name, day: $dayOfWeek)';
}

/// A single exercise within a [RoutineModel].
class ExerciseEntry {
  final String exerciseName;
  final String primaryMuscle; // e.g. 'Ngực', 'Lưng', 'Chân'
  final int sets;
  final int reps;
  final double? weight; // kg, nullable for bodyweight exercises
  final int restTime; // rest between sets in seconds

  const ExerciseEntry({
    required this.exerciseName,
    this.primaryMuscle = '',
    required this.sets,
    required this.reps,
    this.weight,
    this.restTime = 60,
  });

  factory ExerciseEntry.fromJson(Map<String, dynamic> json) {
    return ExerciseEntry(
      exerciseName: json['exerciseName'] as String,
      primaryMuscle: json['primaryMuscle'] as String? ?? '',
      sets: json['sets'] as int,
      reps: json['reps'] as int,
      weight: (json['weight'] as num?)?.toDouble(),
      restTime: json['restTime'] as int? ?? 60,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseName': exerciseName,
      'primaryMuscle': primaryMuscle,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'restTime': restTime,
    };
  }

  ExerciseEntry copyWith({
    String? exerciseName,
    String? primaryMuscle,
    int? sets,
    int? reps,
    double? weight,
    int? restTime,
  }) {
    return ExerciseEntry(
      exerciseName: exerciseName ?? this.exerciseName,
      primaryMuscle: primaryMuscle ?? this.primaryMuscle,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      restTime: restTime ?? this.restTime,
    );
  }

  @override
  String toString() =>
      'ExerciseEntry(name: $exerciseName, sets: $sets, reps: $reps, weight: $weight, rest: $restTime)';
}
