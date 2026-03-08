import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/models/routine_model.dart';
import '../data/models/workout_plan_model.dart';
import '../data/repositories/workout_repository.dart';

// ───────────────────────── State ─────────────────────────

@immutable
class CreatePlanState {
  final List<RoutineModel> routines;
  final List<int> trainingDays;
  final bool isSaving;
  final bool isSaved;
  final String? errorMessage;

  const CreatePlanState({
    this.routines = const [],
    this.trainingDays = const [1, 3, 5],
    this.isSaving = false,
    this.isSaved = false,
    this.errorMessage,
  });

  CreatePlanState copyWith({
    List<RoutineModel>? routines,
    List<int>? trainingDays,
    bool? isSaving,
    bool? isSaved,
    String? errorMessage,
  }) {
    return CreatePlanState(
      routines: routines ?? this.routines,
      trainingDays: trainingDays ?? this.trainingDays,
      isSaving: isSaving ?? this.isSaving,
      isSaved: isSaved ?? this.isSaved,
      errorMessage: errorMessage,
    );
  }
}

// ───────────────────────── Cubit ─────────────────────────

/// Manages the state while building a new [WorkoutPlanModel].
class CreatePlanCubit extends Cubit<CreatePlanState> {
  final WorkoutRepository _repo;
  final String _userId;
  static const _uuid = Uuid();

  CreatePlanCubit({
    required WorkoutRepository workoutRepository,
    required String userId,
  }) : _repo = workoutRepository,
       _userId = userId,
       super(const CreatePlanState());

  /// Toggles a weekday in the selected training days list.
  /// Day values: 1 = Monday … 7 = Sunday.
  void toggleTrainingDay(int day) {
    final current = List<int>.from(state.trainingDays);
    if (current.contains(day)) {
      // Prevent removing all days — must keep at least 1
      if (current.length > 1) {
        current.remove(day);
      }
    } else {
      current.add(day);
    }
    current.sort();
    emit(state.copyWith(trainingDays: current));
  }

  /// Initializes empty routines mapped to the given [trainingDays].
  ///
  /// Each day in [trainingDays] gets one routine with the corresponding
  /// [dayOfWeek] value. E.g. [1, 3, 5] → Buổi 1 (Mon), Buổi 2 (Wed), Buổi 3 (Fri).
  void initRoutines(List<int> trainingDays) {
    final sorted = List<int>.from(trainingDays)..sort();
    final routines = List.generate(
      sorted.length,
      (i) => RoutineModel(
        routineId: _uuid.v4(),
        name: 'Buổi ${i + 1}',
        dayOfWeek: sorted[i],
      ),
    );
    emit(state.copyWith(routines: routines, trainingDays: sorted));
  }

  /// Adds an [ExerciseEntry] to the routine at [routineIndex].
  void addExerciseToRoutine(int routineIndex, ExerciseEntry entry) {
    final updatedRoutines = List<RoutineModel>.from(state.routines);
    final routine = updatedRoutines[routineIndex];
    updatedRoutines[routineIndex] = routine.copyWith(
      exercises: [...routine.exercises, entry],
    );
    emit(state.copyWith(routines: updatedRoutines));
  }

  /// Removes the exercise at [exerciseIndex] from the routine at [routineIndex].
  void removeExercise(int routineIndex, int exerciseIndex) {
    final updatedRoutines = List<RoutineModel>.from(state.routines);
    final routine = updatedRoutines[routineIndex];
    final updatedExercises = List<ExerciseEntry>.from(routine.exercises)
      ..removeAt(exerciseIndex);
    updatedRoutines[routineIndex] = routine.copyWith(
      exercises: updatedExercises,
    );
    emit(state.copyWith(routines: updatedRoutines));
  }

  /// Updates the name of a routine.
  void updateRoutineName(int routineIndex, String name) {
    final updatedRoutines = List<RoutineModel>.from(state.routines);
    updatedRoutines[routineIndex] = updatedRoutines[routineIndex].copyWith(
      name: name,
    );
    emit(state.copyWith(routines: updatedRoutines));
  }

  /// Reorders exercises within a routine via drag-and-drop.
  void reorderExercises(int routineIndex, int oldIndex, int newIndex) {
    final updatedRoutines = List<RoutineModel>.from(state.routines);
    final routine = updatedRoutines[routineIndex];
    final exercises = List<ExerciseEntry>.from(routine.exercises);

    final item = exercises.removeAt(oldIndex);
    exercises.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, item);

    updatedRoutines[routineIndex] = routine.copyWith(exercises: exercises);
    emit(state.copyWith(routines: updatedRoutines));
  }

  /// Saves the full [WorkoutPlanModel] to Firestore.
  Future<void> savePlan({
    required String name,
    required String description,
    required int totalWeeks,
    required List<int> trainingDays,
  }) async {
    emit(state.copyWith(isSaving: true, errorMessage: null));
    try {
      final plan = WorkoutPlanModel(
        planId: _uuid.v4(),
        userId: _userId,
        name: name,
        description: description,
        totalWeeks: totalWeeks,
        trainingDays: trainingDays,
        isActive: true,
        routines: state.routines,
        createdAt: DateTime.now(),
      );
      await _repo.createPlan(plan);
      emit(state.copyWith(isSaving: false, isSaved: true));
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }
}
