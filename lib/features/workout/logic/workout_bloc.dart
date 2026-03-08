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
}
