import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repositories/workout_repository.dart';
import 'exercise_library_event.dart';
import 'exercise_library_state.dart';

/// Manages the exercise library data (system + trainee-created exercises).
class ExerciseLibraryBloc
    extends Bloc<ExerciseLibraryEvent, ExerciseLibraryState> {
  final WorkoutRepository _repo;
  final String _userId;

  ExerciseLibraryBloc({
    required WorkoutRepository workoutRepository,
    required String userId,
  }) : _repo = workoutRepository,
       _userId = userId,
       super(const ExerciseLibraryInitial()) {
    on<ExerciseLibraryLoadRequested>(_onLoadRequested);
    on<ExerciseLibraryCreateRequested>(_onCreateRequested);
  }

  /// Fetches all exercises from Firestore.
  Future<void> _onLoadRequested(
    ExerciseLibraryLoadRequested event,
    Emitter<ExerciseLibraryState> emit,
  ) async {
    emit(const ExerciseLibraryLoading());
    try {
      final exercises = await _repo.getExercises(_userId);
      emit(ExerciseLibraryLoaded(exercises));
    } catch (e) {
      emit(ExerciseLibraryError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  /// Creates a custom exercise, then reloads the full list.
  Future<void> _onCreateRequested(
    ExerciseLibraryCreateRequested event,
    Emitter<ExerciseLibraryState> emit,
  ) async {
    try {
      await _repo.createCustomExercise(event.exercise);
      // Reload the list after successful creation.
      add(const ExerciseLibraryLoadRequested());
    } catch (e) {
      emit(ExerciseLibraryError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
