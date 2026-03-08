import 'package:flutter/foundation.dart';

/// Events dispatched to [WorkoutBloc].
@immutable
sealed class WorkoutEvent {
  const WorkoutEvent();
}

/// Load active workout plans for the current user.
final class WorkoutLoadRequested extends WorkoutEvent {
  const WorkoutLoadRequested();
}
