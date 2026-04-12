import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../data/models/routine_model.dart';
import '../../logic/active_workout_cubit.dart';
import '../widgets/workout_exercise_card.dart';

/// Displays the list of exercises inside a routine.
/// From here users can start an active workout session.
class RoutineDetailScreen extends StatelessWidget {
  final RoutineModel routine;
  final String planName;
  final String? planId;

  const RoutineDetailScreen({
    super.key,
    required this.routine,
    required this.planName,
    this.planId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(routine.name)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: () async {
                context.read<ActiveWorkoutCubit>().loadRoutine(
                  routine,
                  planId: planId,
                );
                final completed = await context.push<bool>(
                  '/active-workout',
                );
                if (completed == true && context.mounted) {
                  await context.read<ActiveWorkoutCubit>().markWorkoutCompleted();
                  if (context.mounted) {
                    context.pop(true); // Propagate completion to dashboard
                  }
                }
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Bắt đầu tập luyện'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Plan name badge ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              planName,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Summary ──
          Text(
            '${routine.exercises.length} bài tập',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),

          // ── Exercise List ──
          ...routine.exercises.asMap().entries.map((entry) {
            final index = entry.key;
            final ex = entry.value;
            return WorkoutExerciseCard(
              index: index,
              exercise: ex,
            );
          }),
        ],
      ),
    );
  }
}
