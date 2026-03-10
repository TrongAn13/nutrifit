import 'package:flutter/foundation.dart';

import '../data/models/workout_plan_model.dart';

/// States emitted by [WorkoutTemplateBloc].
@immutable
sealed class WorkoutTemplateState {
  const WorkoutTemplateState();
}

final class WorkoutTemplateInitial extends WorkoutTemplateState {
  const WorkoutTemplateInitial();
}

final class WorkoutTemplateLoading extends WorkoutTemplateState {
  const WorkoutTemplateLoading();
}

/// All plans loaded successfully.
final class WorkoutTemplateLoaded extends WorkoutTemplateState {
  final List<WorkoutPlanModel> plans;

  const WorkoutTemplateLoaded(this.plans);
}

final class WorkoutTemplateError extends WorkoutTemplateState {
  final String message;

  const WorkoutTemplateError(this.message);
}
