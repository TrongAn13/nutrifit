import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/routine_model.dart';
import '../../data/repositories/workout_repository.dart';
import '../../logic/active_workout_cubit.dart';

/// Displays the list of exercises inside a routine.
/// From here users can start an active workout session.
class RoutineDetailScreen extends StatelessWidget {
  final RoutineModel routine;
  final String planName;

  const RoutineDetailScreen({
    super.key,
    required this.routine,
    required this.planName,
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
                context.read<ActiveWorkoutCubit>().loadRoutine(routine);
                final completed = await context.push<bool>(
                  '/active-workout',
                );
                if (completed == true && context.mounted) {
                  // Save workout completed to Firestore
                  try {
                    await WorkoutRepository().markWorkoutCompleted();
                  } catch (_) {
                    // Ignore — offline will auto-sync
                  }
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

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                  child: Text(
                    '${index + 1}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                title: Text(
                  ex.exerciseName,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '${ex.sets} hiệp × ${ex.reps} reps'
                  '${ex.weight != null ? ' · ${ex.weight!.toStringAsFixed(0)} kg' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                trailing: Icon(
                  Icons.fitness_center_rounded,
                  size: 20,
                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
