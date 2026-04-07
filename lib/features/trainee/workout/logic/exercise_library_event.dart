import 'package:flutter/foundation.dart';

import '../data/models/exercise_model.dart';

/// Events dispatched to [ExerciseLibraryBloc].
@immutable
sealed class ExerciseLibraryEvent {
  const ExerciseLibraryEvent();
}

/// Load all exercises (system + trainee-created) for the current trainee.
final class ExerciseLibraryLoadRequested extends ExerciseLibraryEvent {
  const ExerciseLibraryLoadRequested();
}

/// Create a new trainee-defined exercise.
final class ExerciseLibraryCreateRequested extends ExerciseLibraryEvent {
  final ExerciseModel exercise;

  const ExerciseLibraryCreateRequested(this.exercise);
}
