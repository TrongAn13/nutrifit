import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'active_workout_cubit.dart';

/// A single logged set recorded by the user.
@immutable
class LoggedSet {
  final int setNumber;
  final double weight;
  final int reps;
  final DateTime loggedAt;

  const LoggedSet({
    required this.setNumber,
    required this.weight,
    required this.reps,
    required this.loggedAt,
  });
}

/// State for [ActiveExerciseCubit].
@immutable
class ActiveExerciseState {
  /// Total target sets from the plan.
  final int targetSets;

  /// Target reps per set from the plan.
  final int targetReps;

  /// Rest time in seconds from the plan.
  final int restTimeSeconds;

  /// History of logged sets.
  final List<LoggedSet> loggedSets;

  /// Countdown timer: seconds remaining (0 = idle).
  final int restRemaining;

  /// Whether the rest timer is actively running.
  final bool isTimerRunning;

  const ActiveExerciseState({
    required this.targetSets,
    required this.targetReps,
    required this.restTimeSeconds,
    this.loggedSets = const [],
    this.restRemaining = 0,
    this.isTimerRunning = false,
  });

  int get completedSets => loggedSets.length;

  double get progress =>
      targetSets > 0 ? (completedSets / targetSets).clamp(0.0, 1.0) : 0.0;

  ActiveExerciseState copyWith({
    int? targetSets,
    int? targetReps,
    int? restTimeSeconds,
    List<LoggedSet>? loggedSets,
    int? restRemaining,
    bool? isTimerRunning,
  }) {
    return ActiveExerciseState(
      targetSets: targetSets ?? this.targetSets,
      targetReps: targetReps ?? this.targetReps,
      restTimeSeconds: restTimeSeconds ?? this.restTimeSeconds,
      loggedSets: loggedSets ?? this.loggedSets,
      restRemaining: restRemaining ?? this.restRemaining,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
    );
  }
}

/// Manages a single exercise session: logging sets and rest countdown.
class ActiveExerciseCubit extends Cubit<ActiveExerciseState> {
  Timer? _timer;
  final ActiveWorkoutCubit? workoutCubit;
  final int? exerciseIndex;

  ActiveExerciseCubit({
    required int targetSets,
    required int targetReps,
    required int restTimeSeconds,
    this.workoutCubit,
    this.exerciseIndex,
  }) : super(
         ActiveExerciseState(
           targetSets: targetSets,
           targetReps: targetReps,
           restTimeSeconds: restTimeSeconds,
         ),
       ) {
    _loadInitialHistory();
  }

  void _loadInitialHistory() {
    if (workoutCubit == null || exerciseIndex == null) return;

    final setsData = workoutCubit!.state.setsData[exerciseIndex!];
    if (setsData == null) return;

    final List<LoggedSet> initialHistory = [];
    for (int i = 0; i < setsData.length; i++) {
      final sd = setsData[i];
      if (sd.isCompleted) {
        initialHistory.add(
          LoggedSet(
            setNumber: i + 1,
            weight: sd.weight,
            reps: sd.reps,
            loggedAt: DateTime.now(),
          ),
        );
      }
    }

    emit(state.copyWith(loggedSets: initialHistory));
  }

  /// Log a completed set and start the rest timer.
  void logSet(double weight, int reps) {
    if (workoutCubit == null || exerciseIndex == null) return;

    final setsData = workoutCubit!.state.setsData[exerciseIndex!];
    if (setsData == null) return;

    // Find the first uncompleted set
    int setIndex = -1;
    for (int i = 0; i < setsData.length; i++) {
      if (!setsData[i].isCompleted) {
        setIndex = i;
        break;
      }
    }

    // If all target sets are done, we still add one functionally if they keep pressing +
    if (setIndex == -1) {
      setIndex = setsData.length;
      // Tell workout cubit to add a new set to its tracking list (optional, but for simplicity we rely on logging here)
      // Actually, let's just use completedSets from our own state as the new index
      setIndex = state.completedSets;
    }

    final logged = LoggedSet(
      setNumber: state.completedSets + 1,
      weight: weight,
      reps: reps,
      loggedAt: DateTime.now(),
    );

    emit(state.copyWith(loggedSets: [...state.loggedSets, logged]));
    _startRest();

    // Sync back to the workout session
    // Only update if it's within the original target bounds, or if the user added more sets, WorkoutCubit handles it
    try {
      workoutCubit!.updateWeight(exerciseIndex!, setIndex, weight);
      workoutCubit!.updateReps(exerciseIndex!, setIndex, reps);
      // completeSet also starts the workout cubit rest timer, which is fine,
      // but we should just ensure they don't visually conflict.
      // Since completeSet toggles, we must check if not completed
      if (setIndex < setsData.length && !setsData[setIndex].isCompleted) {
        workoutCubit!.completeSet(exerciseIndex!, setIndex);
      }
    } catch (_) {
      // Ignore out of bounds
    }
  }

  /// Start the rest countdown timer.
  void _startRest() {
    _timer?.cancel();
    emit(
      state.copyWith(
        restRemaining: state.restTimeSeconds,
        isTimerRunning: true,
      ),
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = state.restRemaining - 1;
      if (remaining <= 0) {
        _timer?.cancel();
        emit(state.copyWith(restRemaining: 0, isTimerRunning: false));
      } else {
        emit(state.copyWith(restRemaining: remaining));
      }
    });
  }

  /// Toggle the rest timer pause/resume.
  void toggleTimer() {
    if (state.isTimerRunning) {
      // Pause
      _timer?.cancel();
      emit(state.copyWith(isTimerRunning: false));
    } else if (state.restRemaining > 0) {
      // Resume
      emit(state.copyWith(isTimerRunning: true));
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        final remaining = state.restRemaining - 1;
        if (remaining <= 0) {
          _timer?.cancel();
          emit(state.copyWith(restRemaining: 0, isTimerRunning: false));
        } else {
          emit(state.copyWith(restRemaining: remaining));
        }
      });
    }
  }

  /// Skip the rest timer.
  void skipRest() {
    _timer?.cancel();
    emit(state.copyWith(restRemaining: 0, isTimerRunning: false));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
