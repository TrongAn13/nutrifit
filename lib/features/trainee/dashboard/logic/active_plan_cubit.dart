import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/widgets.dart';

import '../../workout/data/models/routine_model.dart';
import '../../workout/data/models/workout_history_model.dart';
import '../../workout/data/models/workout_plan_model.dart';
import '../../workout/data/repositories/workout_repository.dart';

/// State representing the currently active workout plan for the dashboard.
class ActivePlanState {
  final WorkoutPlanModel? plan;
  final bool isLoading;
  final String? errorMessage;

  const ActivePlanState({
    this.plan,
    this.isLoading = false,
    this.errorMessage,
  });

  ActivePlanState copyWith({
    WorkoutPlanModel? plan,
    bool? isLoading,
    String? errorMessage,
    bool clearPlan = false,
  }) {
    return ActivePlanState(
      plan: clearPlan ? null : (plan ?? this.plan),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  /// Returns today's routine from the active plan, or null if none matches.
  RoutineModel? get todayRoutine {
    if (plan == null) return null;

    // Get today's weekday as 1=Mon ... 7=Sun (Dart uses 1=Mon ... 7=Sun)
    final todayWeekday = DateTime.now().weekday;

    // Check if today is a training day
    if (!plan!.trainingDays.contains(todayWeekday)) return null;

    // Find the routine matching today's weekday
    for (final routine in plan!.routines) {
      if (routine.dayOfWeek == todayWeekday) {
        return routine;
      }
    }

    // Fallback: find the routine by index in trainingDays
    final dayIndex = plan!.trainingDays.indexOf(todayWeekday);
    if (dayIndex >= 0 && dayIndex < plan!.routines.length) {
      return plan!.routines[dayIndex];
    }

    return null;
  }

  /// Whether today is a rest day.
  bool get isRestDay {
    if (plan == null) return true;
    return !plan!.trainingDays.contains(DateTime.now().weekday);
  }
}

/// Cubit that loads and exposes the currently active workout plan.
///
/// Used by the trainee dashboard to display the active plan's image
/// and today's workout routine dynamically.
class ActivePlanCubit extends Cubit<ActivePlanState> {
  final WorkoutRepository _repo;

  ActivePlanCubit({required WorkoutRepository workoutRepository})
      : _repo = workoutRepository,
        super(const ActivePlanState());

  factory ActivePlanCubit.fromContext(BuildContext context) {
    return ActivePlanCubit(
      workoutRepository: context.read<WorkoutRepository>(),
    );
  }

  /// Load the active plan from Firestore.
  Future<void> loadActivePlan() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final activePlans = await _repo.getActivePlans();
      if (activePlans.isNotEmpty) {
        emit(state.copyWith(plan: activePlans.first, isLoading: false));
      } else {
        emit(state.copyWith(isLoading: false, clearPlan: true));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  /// Fetches workout histories for the current user.
  Future<List<WorkoutHistoryModel>> getWorkoutHistories() {
    return _repo.getWorkoutHistories();
  }

  /// Fetches all plans for the current user.
  Future<List<WorkoutPlanModel>> getAllPlans() {
    return _repo.getAllPlans();
  }

  /// Saves a workout history entry.
  Future<void> saveWorkoutHistory(WorkoutHistoryModel history) {
    return _repo.saveWorkoutHistory(history);
  }

  /// Deletes a workout history entry by id.
  Future<void> deleteWorkoutHistory(String historyId) {
    return _repo.deleteWorkoutHistory(historyId);
  }

  /// Updates a workout plan document.
  Future<void> updatePlan(WorkoutPlanModel plan) {
    return _repo.updatePlan(plan);
  }
}
