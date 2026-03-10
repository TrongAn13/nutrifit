import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repositories/workout_repository.dart';
import 'workout_template_event.dart';
import 'workout_template_state.dart';

/// Manages the list of ALL workout plans for the template list screen.
class WorkoutTemplateBloc
    extends Bloc<WorkoutTemplateEvent, WorkoutTemplateState> {
  final WorkoutRepository _repo;

  WorkoutTemplateBloc({required WorkoutRepository workoutRepository})
    : _repo = workoutRepository,
      super(const WorkoutTemplateInitial()) {
    on<WorkoutTemplateLoadRequested>(_onLoad);
    on<WorkoutTemplateDeleteRequested>(_onDelete);
    on<WorkoutTemplateSetActiveRequested>(_onSetActive);
  }

  Future<void> _onLoad(
    WorkoutTemplateLoadRequested event,
    Emitter<WorkoutTemplateState> emit,
  ) async {
    emit(const WorkoutTemplateLoading());
    try {
      final plans = await _repo.getAllPlans();
      emit(WorkoutTemplateLoaded(plans));
    } catch (e) {
      emit(WorkoutTemplateError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onDelete(
    WorkoutTemplateDeleteRequested event,
    Emitter<WorkoutTemplateState> emit,
  ) async {
    try {
      await _repo.deletePlan(event.planId);
      // Reload after delete
      add(const WorkoutTemplateLoadRequested());
    } catch (e) {
      emit(WorkoutTemplateError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  /// Sets a plan as the only active plan, then reloads the list.
  Future<void> _onSetActive(
    WorkoutTemplateSetActiveRequested event,
    Emitter<WorkoutTemplateState> emit,
  ) async {
    try {
      await _repo.setActivePlan(event.planId);
      add(const WorkoutTemplateLoadRequested());
    } catch (e) {
      emit(WorkoutTemplateError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
