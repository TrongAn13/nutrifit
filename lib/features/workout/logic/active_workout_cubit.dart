import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models/routine_model.dart';

/// State for the active workout session.
class ActiveWorkoutState {
  /// The routine being performed. Null when no workout is active.
  final RoutineModel? routine;

  /// Whether the workout is currently active (routine loaded, not finished).
  bool get isWorkoutActive => routine != null && !isFinished;

  /// Whether the workout timer is actively running.
  final bool isTimerRunning;

  /// Index of the exercise currently being displayed.
  final int currentExerciseIndex;

  /// Per-exercise, per-set completion status.
  /// Key: exercise index, Value: list of set completions.
  final Map<int, List<SetData>> setsData;

  /// Rest timer seconds remaining (0 = not active).
  final int restSecondsRemaining;

  /// Total rest duration for reference.
  final int restDuration;

  /// Total accumulated rest time for the workout in seconds.
  final int totalRestSeconds;

  /// Elapsed seconds for the entire workout duration.
  final int workoutElapsedSeconds;

  /// Whether the entire workout is finished.
  final bool isFinished;

  const ActiveWorkoutState({
    this.routine,
    this.isTimerRunning = false,
    this.currentExerciseIndex = 0,
    this.setsData = const {},
    this.restSecondsRemaining = 0,
    this.restDuration = 60,
    this.totalRestSeconds = 0,
    this.workoutElapsedSeconds = 0,
    this.isFinished = false,
  });

  ActiveWorkoutState copyWith({
    RoutineModel? routine,
    bool? isTimerRunning,
    int? currentExerciseIndex,
    Map<int, List<SetData>>? setsData,
    int? restSecondsRemaining,
    int? restDuration,
    int? totalRestSeconds,
    int? workoutElapsedSeconds,
    bool? isFinished,
  }) {
    return ActiveWorkoutState(
      routine: routine ?? this.routine,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      setsData: setsData ?? this.setsData,
      restSecondsRemaining: restSecondsRemaining ?? this.restSecondsRemaining,
      restDuration: restDuration ?? this.restDuration,
      totalRestSeconds: totalRestSeconds ?? this.totalRestSeconds,
      workoutElapsedSeconds:
          workoutElapsedSeconds ?? this.workoutElapsedSeconds,
      isFinished: isFinished ?? this.isFinished,
    );
  }
}

/// Data for a single set within an exercise.
class SetData {
  final double weight;
  final int reps;
  final bool isCompleted;

  const SetData({this.weight = 0, this.reps = 0, this.isCompleted = false});

  SetData copyWith({double? weight, int? reps, bool? isCompleted}) {
    return SetData(
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// Cubit for managing an active workout session.
///
/// Lives at the app level (provided in main.dart) so that
/// workout state persists when navigating away from the screen.
class ActiveWorkoutCubit extends Cubit<ActiveWorkoutState> {
  Timer? _restTimer;
  Timer? _workoutTimer;
  DateTime? _pausedTime;

  ActiveWorkoutCubit() : super(const ActiveWorkoutState());

  // ─────────────────── Session Lifecycle ───────────────────

  /// Loads a routine and initializes set data, but does NOT start the timer.
  /// Called when the user taps the workout card on the dashboard.
  /// If a session is already active, this call is ignored.
  void loadRoutine(RoutineModel routine) {
    if (state.isWorkoutActive) return;

    _restTimer?.cancel();
    _workoutTimer?.cancel();
    _pausedTime = null;

    emit(ActiveWorkoutState(routine: routine));
    _initSetsData();
  }

  /// Begins the workout timer. Called when the user presses "Bắt đầu tập luyện".
  void beginWorkout() {
    if (!state.isWorkoutActive || state.isTimerRunning) return;
    emit(state.copyWith(isTimerRunning: true));
    _startWorkoutTimer();
  }

  /// Quits the current workout and resets all state.
  void quitWorkout() {
    _restTimer?.cancel();
    _workoutTimer?.cancel();
    _pausedTime = null;
    emit(const ActiveWorkoutState());
  }

  /// Pauses the workout timer (call when app goes to background).
  void pauseWorkout() {
    _workoutTimer?.cancel();
    _pausedTime = DateTime.now();
  }

  /// Resumes the workout timer (call when app returns to foreground).
  void resumeWorkout() {
    if (_pausedTime != null) {
      final diff = DateTime.now().difference(_pausedTime!).inSeconds;
      emit(state.copyWith(
        workoutElapsedSeconds: state.workoutElapsedSeconds + diff,
      ));
      _pausedTime = null;
    }
    if (state.isWorkoutActive) {
      _startWorkoutTimer();
    }
  }

  // ─────────────────── Internal Timer ───────────────────

  void _startWorkoutTimer() {
    _workoutTimer?.cancel();
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      emit(state.copyWith(
        workoutElapsedSeconds: state.workoutElapsedSeconds + 1,
      ));
    });
  }

  // ─────────────────── Set Data ───────────────────

  /// Initialize empty set data for each exercise.
  void _initSetsData() {
    if (state.routine == null) return;
    final data = <int, List<SetData>>{};
    for (int i = 0; i < state.routine!.exercises.length; i++) {
      final ex = state.routine!.exercises[i];
      data[i] = List.generate(
        ex.sets,
        (_) => SetData(weight: ex.weight ?? 0, reps: ex.reps),
      );
    }
    emit(state.copyWith(setsData: data));
  }

  /// Move to a specific exercise.
  void goToExercise(int index) {
    if (state.routine == null) return;
    if (index >= 0 && index < state.routine!.exercises.length) {
      emit(state.copyWith(currentExerciseIndex: index));
    }
  }

  /// Update weight for a specific set.
  void updateWeight(int exerciseIndex, int setIndex, double weight) {
    final updated = Map<int, List<SetData>>.from(state.setsData);
    final sets = List<SetData>.from(updated[exerciseIndex]!);
    sets[setIndex] = sets[setIndex].copyWith(weight: weight);
    updated[exerciseIndex] = sets;
    emit(state.copyWith(setsData: updated));
  }

  /// Update reps for a specific set.
  void updateReps(int exerciseIndex, int setIndex, int reps) {
    final updated = Map<int, List<SetData>>.from(state.setsData);
    final sets = List<SetData>.from(updated[exerciseIndex]!);
    sets[setIndex] = sets[setIndex].copyWith(reps: reps);
    updated[exerciseIndex] = sets;
    emit(state.copyWith(setsData: updated));
  }

  /// Toggle set completion and start rest timer.
  void completeSet(int exerciseIndex, int setIndex) {
    final updated = Map<int, List<SetData>>.from(state.setsData);
    final sets = List<SetData>.from(updated[exerciseIndex]!);
    final wasCompleted = sets[setIndex].isCompleted;
    sets[setIndex] = sets[setIndex].copyWith(isCompleted: !wasCompleted);
    updated[exerciseIndex] = sets;
    emit(state.copyWith(setsData: updated));

    // Start rest timer only when marking as completed
    if (!wasCompleted) {
      _startRestTimer();
    }
  }

  /// Start the countdown rest timer.
  void _startRestTimer() {
    _restTimer?.cancel();
    emit(state.copyWith(restSecondsRemaining: state.restDuration));

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = state.restSecondsRemaining - 1;
      final accumulated = state.totalRestSeconds + 1;

      if (remaining <= 0) {
        timer.cancel();
        emit(
          state.copyWith(
            restSecondsRemaining: 0,
            totalRestSeconds: accumulated,
          ),
        );
      } else {
        emit(
          state.copyWith(
            restSecondsRemaining: remaining,
            totalRestSeconds: accumulated,
          ),
        );
      }
    });
  }

  /// Skip the rest timer.
  void skipRest() {
    _restTimer?.cancel();
    emit(state.copyWith(restSecondsRemaining: 0));
  }

  /// Mark the workout as finished.
  void finishWorkout() {
    _restTimer?.cancel();
    _workoutTimer?.cancel();
    emit(state.copyWith(isFinished: true));
  }

  @override
  Future<void> close() {
    _restTimer?.cancel();
    _workoutTimer?.cancel();
    return super.close();
  }
}
