import 'package:flutter/foundation.dart';

import '../data/models/workout_plan_model.dart';

/// Events dispatched to [WorkoutBloc].
@immutable
sealed class WorkoutEvent {
  const WorkoutEvent();
}

/// Load active workout plans for the current user.
final class WorkoutLoadRequested extends WorkoutEvent {
  const WorkoutLoadRequested();
}

/// Delete a workout plan by its ID.
final class WorkoutDeleteRequested extends WorkoutEvent {
  final String planId;
  const WorkoutDeleteRequested(this.planId);
}

/// Set a workout plan as active.
final class WorkoutSetActiveRequested extends WorkoutEvent {
  final String planId;
  const WorkoutSetActiveRequested(this.planId);
}

/// Clone a system plan and save it as user's personal plan.
final class WorkoutCloneSystemPlan extends WorkoutEvent {
  final WorkoutPlanModel systemPlan;
  const WorkoutCloneSystemPlan(this.systemPlan);
}
