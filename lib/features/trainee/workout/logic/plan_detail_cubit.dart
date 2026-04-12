import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/widgets.dart';

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
  final bool isActivating;
  final bool activatedSuccessfully;

  const PlanDetailState({
    required this.plan,
    this.currentRoutineIndex = 0,
    this.isSaving = false,
    this.errorMessage,
    this.savedSuccessfully = false,
    this.isActivating = false,
    this.activatedSuccessfully = false,
  });

  PlanDetailState copyWith({
    WorkoutPlanModel? plan,
    int? currentRoutineIndex,
    bool? isSaving,
    String? errorMessage,
    bool? savedSuccessfully,
    bool? isActivating,
    bool? activatedSuccessfully,
  }) {
    return PlanDetailState(
      plan: plan ?? this.plan,
      currentRoutineIndex: currentRoutineIndex ?? this.currentRoutineIndex,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      savedSuccessfully: savedSuccessfully ?? false,
      isActivating: isActivating ?? false,
      activatedSuccessfully: activatedSuccessfully ?? false,
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

  static const Map<int, String> _dayLabels = {
    1: 'Thứ 2',
    2: 'Thứ 3',
    3: 'Thứ 4',
    4: 'Thứ 5',
    5: 'Thứ 6',
    6: 'Thứ 7',
    7: 'Chủ nhật',
  };

  PlanDetailCubit({
    required WorkoutRepository workoutRepository,
    required WorkoutPlanModel initialPlan,
  }) : _repo = workoutRepository,
       super(PlanDetailState(plan: initialPlan));

  factory PlanDetailCubit.fromContext({
    required BuildContext context,
    required WorkoutPlanModel initialPlan,
  }) {
    return PlanDetailCubit(
      workoutRepository: context.read<WorkoutRepository>(),
      initialPlan: initialPlan,
    );
  }

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

  /// Update basic plan information from the edit-info tab.
  void updatePlanBasics({
    required String name,
    required String description,
    required int totalWeeks,
    required List<int> trainingDays,
    required String imageUrl,
  }) {
    final sortedDays = List<int>.from(trainingDays)..sort();
    final routines = _rebuildRoutines(
      totalWeeks: totalWeeks,
      trainingDays: sortedDays,
      currentRoutines: state.plan.routines,
    );

    var nextIndex = state.currentRoutineIndex;
    if (routines.isEmpty) {
      nextIndex = 0;
    } else if (nextIndex >= routines.length) {
      nextIndex = routines.length - 1;
    }

    emit(
      state.copyWith(
        plan: state.plan.copyWith(
          name: name,
          description: description,
          totalWeeks: totalWeeks,
          trainingDays: sortedDays,
          imageUrl: imageUrl.trim(),
          routines: routines,
        ),
        currentRoutineIndex: nextIndex,
      ),
    );
  }

  List<RoutineModel> _rebuildRoutines({
    required int totalWeeks,
    required List<int> trainingDays,
    required List<RoutineModel> currentRoutines,
  }) {
    final routines = <RoutineModel>[];
    var sourceIndex = 0;

    for (int week = 0; week < totalWeeks; week++) {
      for (int i = 0; i < trainingDays.length; i++) {
        final dayOfWeek = trainingDays[i];
        final fallbackName = _dayLabels[dayOfWeek] ?? 'Buổi ${i + 1}';
        final existing = sourceIndex < currentRoutines.length
            ? currentRoutines[sourceIndex]
            : null;

        routines.add(
          RoutineModel(
            routineId: existing?.routineId ??
                'routine_${week}_${dayOfWeek}_${DateTime.now().microsecondsSinceEpoch}',
            name: existing?.name ?? fallbackName,
            dayOfWeek: dayOfWeek,
            exercises: existing?.exercises ?? const [],
          ),
        );
        sourceIndex++;
      }
    }

    return routines;
  }

  /// Update plan banner image URL.
  void updateBannerUrl(String imageUrl) {
    emit(state.copyWith(plan: state.plan.copyWith(imageUrl: imageUrl.trim())));
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

  /// Update an existing exercise in the current routine.
  void updateExercise(int exerciseIndex, ExerciseEntry updatedExercise) {
    final routines = List<RoutineModel>.from(state.plan.routines);
    final current = routines[state.currentRoutineIndex];
    final exercises = List<ExerciseEntry>.from(current.exercises);
    exercises[exerciseIndex] = updatedExercise;
    routines[state.currentRoutineIndex] = current.copyWith(
      exercises: exercises,
    );
    emit(state.copyWith(plan: state.plan.copyWith(routines: routines)));
  }

  /// Save the entire plan to Firestore.
  Future<void> savePlan() async {
    emit(state.copyWith(isSaving: true, errorMessage: null));
    try {
      final isTaken = await _repo.isPlanNameTaken(
        planName: state.plan.name,
        isTemplate: state.plan.isTemplate,
        excludePlanId: state.plan.planId,
      );

      if (isTaken) {
        emit(
          state.copyWith(
            isSaving: false,
            errorMessage: 'Tên giáo án đã tồn tại. Vui lòng chọn tên khác.',
          ),
        );
        return;
      }

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

  /// Activate this plan as the user's current workout plan.
  ///
  /// Saves the plan first (to ensure it exists in Firestore),
  /// then sets it as the only active plan via a batch write.
  Future<void> activatePlan() async {
    emit(state.copyWith(isActivating: true, errorMessage: null));
    try {
      // Ensure the plan is saved first
      await _repo.updatePlan(state.plan);

      // Set this plan as the sole active plan
      await _repo.setActivePlan(state.plan.planId);

      // Update local state to reflect active status
      emit(state.copyWith(
        isActivating: false,
        activatedSuccessfully: true,
        plan: state.plan.copyWith(isActive: true),
      ));
    } catch (e) {
      emit(
        state.copyWith(
          isActivating: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }
}
