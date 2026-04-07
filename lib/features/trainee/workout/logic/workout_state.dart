import 'package:flutter/foundation.dart';

import '../data/models/workout_plan_model.dart';
import '../data/models/workout_history_model.dart';

/// States emitted by [WorkoutBloc].
@immutable
sealed class WorkoutState {
  const WorkoutState();
}

/// Initial state before data is loaded.
final class WorkoutInitial extends WorkoutState {
  const WorkoutInitial();
}

/// Data is being fetched from Firestore.
final class WorkoutLoading extends WorkoutState {
  const WorkoutLoading();
}

/// Plans loaded successfully.
///
/// [activePlans] contains only plans where `isActive == true`.
/// [allPlans] contains every plan for the plan selector.
final class WorkoutLoaded extends WorkoutState {
  final List<WorkoutPlanModel> activePlans;
  final List<WorkoutPlanModel> allPlans;
  final List<WorkoutHistoryModel> histories;

  const WorkoutLoaded({
    required this.activePlans,
    required this.allPlans,
    required this.histories,
  });
}

/// An error occurred while fetching plans.
final class WorkoutError extends WorkoutState {
  final String message;

  const WorkoutError(this.message);
}
