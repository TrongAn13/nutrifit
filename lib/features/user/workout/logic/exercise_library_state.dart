import 'package:flutter/foundation.dart';

import '../data/models/exercise_model.dart';

/// States emitted by [ExerciseLibraryBloc].
@immutable
sealed class ExerciseLibraryState {
  const ExerciseLibraryState();
}

/// Initial state before data is loaded.
final class ExerciseLibraryInitial extends ExerciseLibraryState {
  const ExerciseLibraryInitial();
}

/// Exercises are being fetched from Firestore.
final class ExerciseLibraryLoading extends ExerciseLibraryState {
  const ExerciseLibraryLoading();
}

/// Exercises loaded successfully.
final class ExerciseLibraryLoaded extends ExerciseLibraryState {
  final List<ExerciseModel> exercises;

  const ExerciseLibraryLoaded(this.exercises);
}

/// An error occurred while fetching exercises.
final class ExerciseLibraryError extends ExerciseLibraryState {
  final String message;

  const ExerciseLibraryError(this.message);
}
