import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models/routine_model.dart';
import '../data/models/workout_plan_model.dart';
import '../data/repositories/workout_repository.dart';

/// State for [PlanDetailCubit].
class PlanDetailState {
  final WorkoutPlanModel plan;
  final int currentRoutineIndex;
  final bool isSaving;
  final String? errorMessage;
  final bool savedSuccessfully;

  const PlanDetailState({
    required this.plan,
    this.currentRoutineIndex = 0,
    this.isSaving = false,
    this.errorMessage,
    this.savedSuccessfully = false,
  });

  PlanDetailState copyWith({
    WorkoutPlanModel? plan,
    int? currentRoutineIndex,
    bool? isSaving,
    String? errorMessage,
    bool? savedSuccessfully,
  }) {
    return PlanDetailState(
      plan: plan ?? this.plan,
      currentRoutineIndex: currentRoutineIndex ?? this.currentRoutineIndex,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      savedSuccessfully: savedSuccessfully ?? false,
    );
  }

  /// The currently selected routine, or null if index is out of range.
  RoutineModel? get currentRoutine {
    if (currentRoutineIndex < 0 ||
        currentRoutineIndex >= plan.routines.length) {
      return null;
    }
    return plan.routines[currentRoutineIndex];
  }
}

/// Manages plan detail editing: selecting routines, renaming, copying,
/// adding exercises, and saving to Firestore.
class PlanDetailCubit extends Cubit<PlanDetailState> {
  final WorkoutRepository _repo;

  PlanDetailCubit({
    required WorkoutRepository workoutRepository,
    required WorkoutPlanModel initialPlan,
  }) : _repo = workoutRepository,
       super(PlanDetailState(plan: initialPlan));

  /// Switch the active routine view.
  void selectRoutine(int index) {
    if (index >= 0 && index < state.plan.routines.length) {
      emit(state.copyWith(currentRoutineIndex: index));
    }
  }

  /// Rename the current routine.
  void renameCurrentRoutine(String newName) {
    final routines = List<RoutineModel>.from(state.plan.routines);
    routines[state.currentRoutineIndex] = routines[state.currentRoutineIndex]
        .copyWith(name: newName);
    emit(state.copyWith(plan: state.plan.copyWith(routines: routines)));
  }

  /// Copy exercises from current routine to the target routine index.
  void copyToRoutine(int targetIndex) {
    if (targetIndex < 0 || targetIndex >= state.plan.routines.length) return;
    if (targetIndex == state.currentRoutineIndex) return;

    final source = state.plan.routines[state.currentRoutineIndex];
    final routines = List<RoutineModel>.from(state.plan.routines);
    routines[targetIndex] = routines[targetIndex].copyWith(
      exercises: List<ExerciseEntry>.from(source.exercises),
    );
    emit(state.copyWith(plan: state.plan.copyWith(routines: routines)));
  }

  /// Add an exercise to the current routine.
  void addExercise(ExerciseEntry exercise) {
    final routines = List<RoutineModel>.from(state.plan.routines);
    final current = routines[state.currentRoutineIndex];
    routines[state.currentRoutineIndex] = current.copyWith(
      exercises: [...current.exercises, exercise],
    );
    emit(state.copyWith(plan: state.plan.copyWith(routines: routines)));
  }

  /// Remove an exercise from the current routine.
  void removeExercise(int exerciseIndex) {
    final routines = List<RoutineModel>.from(state.plan.routines);
    final current = routines[state.currentRoutineIndex];
    final exercises = List<ExerciseEntry>.from(current.exercises)
      ..removeAt(exerciseIndex);
    routines[state.currentRoutineIndex] = current.copyWith(
      exercises: exercises,
    );
    emit(state.copyWith(plan: state.plan.copyWith(routines: routines)));
  }

  /// Save the entire plan to Firestore.
  Future<void> savePlan() async {
    emit(state.copyWith(isSaving: true, errorMessage: null));
    try {
      await _repo.updatePlan(state.plan);
      emit(state.copyWith(isSaving: false, savedSuccessfully: true));
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
