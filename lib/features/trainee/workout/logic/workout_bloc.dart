import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repositories/workout_repository.dart';
import '../data/models/workout_history_model.dart';
import '../data/models/workout_plan_model.dart';
import 'workout_event.dart';
import 'workout_state.dart';

/// Manages workout plan data for the WorkoutDashboard.
class WorkoutBloc extends Bloc<WorkoutEvent, WorkoutState> {
  final WorkoutRepository _repo;

  WorkoutBloc({required WorkoutRepository workoutRepository})
    : _repo = workoutRepository,
      super(const WorkoutInitial()) {
    on<WorkoutLoadRequested>(_onLoadRequested);
    on<WorkoutDeleteRequested>(_onDeleteRequested);
    on<WorkoutSetActiveRequested>(_onSetActiveRequested);
    on<WorkoutCloneSystemPlan>(_onCloneSystemPlan);
  }

  /// Fetches both active and all plans from Firestore.
  Future<void> _onLoadRequested(
    WorkoutLoadRequested event,
    Emitter<WorkoutState> emit,
  ) async {
    emit(const WorkoutLoading());
    try {
      // Fetch both in parallel
      final results = await Future.wait([
        _repo.getActivePlans(),
        _repo.getAllPlans(),
        _repo.getWorkoutHistories(),
      ]);
      emit(
        WorkoutLoaded(
          activePlans: results[0] as List<WorkoutPlanModel>,
          allPlans: results[1] as List<WorkoutPlanModel>,
          histories: results[2] as List<WorkoutHistoryModel>,
        ),
      );
    } catch (e) {
      emit(WorkoutError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  /// Deletes a workout plan and reloads the list.
  Future<void> _onDeleteRequested(
    WorkoutDeleteRequested event,
    Emitter<WorkoutState> emit,
  ) async {
    try {
      await _repo.deletePlan(event.planId);
      // Reload after delete
      add(const WorkoutLoadRequested());
    } catch (e) {
      emit(WorkoutError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  /// Sets a plan as active and reloads the list.
  Future<void> _onSetActiveRequested(
    WorkoutSetActiveRequested event,
    Emitter<WorkoutState> emit,
  ) async {
    try {
      await _repo.setActivePlan(event.planId);
      add(const WorkoutLoadRequested());
    } catch (e) {
      emit(WorkoutError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  /// Clones a system plan and saves it as the trainee's personal active plan.
  Future<void> _onCloneSystemPlan(
    WorkoutCloneSystemPlan event,
    Emitter<WorkoutState> emit,
  ) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        emit(const WorkoutError('Chưa đăng nhập'));
        return;
      }

      // 1. Deactivate all existing plans
      final allPlans = await _repo.getAllPlans();
      for (final plan in allPlans) {
        if (plan.isActive) {
          await _repo.updatePlan(plan.copyWith(isActive: false));
        }
      }

      // 2. Generate new planId for the clone
      final newPlanId = 'plan_${DateTime.now().millisecondsSinceEpoch}';

      // 3. Clone the system plan with new ID and trainee ownership
      final clonedPlan = event.systemPlan.copyWith(
        planId: newPlanId,
        userId: userId,
        isActive: true,
        createdAt: DateTime.now(),
      );

      // 4. Save the cloned plan
      await _repo.createPlan(clonedPlan);

      // 5. Reload the list
      add(const WorkoutLoadRequested());
    } catch (e) {
      emit(WorkoutError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
