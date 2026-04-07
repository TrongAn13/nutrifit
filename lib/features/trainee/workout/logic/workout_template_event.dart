import 'package:flutter/foundation.dart';

/// Events dispatched to [WorkoutTemplateBloc].
@immutable
sealed class WorkoutTemplateEvent {
  const WorkoutTemplateEvent();
}

/// Load all workout plans for the current trainee.
final class WorkoutTemplateLoadRequested extends WorkoutTemplateEvent {
  const WorkoutTemplateLoadRequested();
}

/// Delete a workout plan by its ID.
final class WorkoutTemplateDeleteRequested extends WorkoutTemplateEvent {
  final String planId;

  const WorkoutTemplateDeleteRequested(this.planId);
}

/// Set a specific workout plan as the active plan.
final class WorkoutTemplateSetActiveRequested extends WorkoutTemplateEvent {
  final String planId;

  const WorkoutTemplateSetActiveRequested(this.planId);
}
