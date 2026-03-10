import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../data/models/workout_history_model.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/routine_model.dart';
import '../../data/repositories/workout_repository.dart';
import '../../logic/active_exercise_cubit.dart';
import '../../logic/active_workout_cubit.dart';
import 'active_exercise_detail_screen.dart';
import 'workout_result_screen.dart';

/// Full-screen active workout session screen.
///
/// Displays a progress header and the list of exercises for today's routine.
/// Each exercise card can be tapped to open a set-logging bottom sheet.
class ActiveWorkoutScreen extends StatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    if (!mounted) return;
    final cubit = context.read<ActiveWorkoutCubit>();
    if (!cubit.state.isTimerRunning) return;

    if (appState == AppLifecycleState.paused ||
        appState == AppLifecycleState.inactive) {
      cubit.pauseWorkout();
    } else if (appState == AppLifecycleState.resumed) {
      cubit.resumeWorkout();
    }
  }

  /// Formats elapsed seconds into MM:SS or HH:MM:SS.
  String _formattedTime(int totalSeconds) {
    if (totalSeconds == 0) return '00:00';
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      final hStr = hours.toString().padLeft(2, '0');
      return '$hStr:$mStr:$sStr';
    }
    return '$mStr:$sStr';
  }

  void _showFinishDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Kết thúc buổi tập?'),
        content: const Text('Bạn có chắc chắn muốn kết thúc buổi tập này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              // 1. Dismiss confirm dialog
              Navigator.of(ctx).pop();

              // 2. Compute metrics from global cubit state
              final cubit = context.read<ActiveWorkoutCubit>();
              final state = cubit.state;

              final duration = state.workoutElapsedSeconds;
              final restTime = state.totalRestSeconds;
              final calories = (duration / 60 * 5).round();

              int totalReps = 0;
              double totalWeight = 0;
              int completedSetsCount = 0;
              int totalSetsCount = 0;

              for (final entry in state.setsData.entries) {
                final sets = entry.value;
                totalSetsCount += sets.length;
                for (final s in sets) {
                  if (s.isCompleted) {
                    completedSetsCount++;
                    totalReps += s.reps;
                    totalWeight += s.weight * s.reps;
                  }
                }
              }

              final completionPercentage = totalSetsCount > 0
                  ? (completedSetsCount / totalSetsCount) * 100
                  : 0.0;

              final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
              final historyId =
                  DateTime.now().millisecondsSinceEpoch.toString();

              final history = WorkoutHistoryModel(
                id: historyId,
                userId: uid,
                planId: state.planId,
                routineName: state.routine!.name,
                date: DateTime.now(),
                durationSeconds: duration,
                restTimeSeconds: restTime,
                caloriesBurned: calories,
                completionPercentage: completionPercentage,
                totalWeightLifted: totalWeight,
                totalReps: totalReps,
                exercises: state.routine!.exercises,
              );

              // 3. Show Loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) =>
                    const Center(child: CircularProgressIndicator()),
              );

              // 4. Save to Repository
              try {
                await WorkoutRepository().saveWorkoutHistory(history);
              } catch (e) {
                // Ignore failure for UI
              }

              if (context.mounted) {
                // Dismiss Loading
                Navigator.of(context).pop();

                // Go to Result Screen (Replace)
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => WorkoutResultScreen(
                      history: history,
                      onClose: () {
                        // Trigger dashboard refresh via global WorkoutBloc
                      },
                    ),
                  ),
                );

                // Reset global cubit state after navigation
                cubit.quitWorkout();
              }
            },
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActiveWorkoutCubit, ActiveWorkoutState>(
      builder: (context, state) {
        // Guard: show loading if no active workout
        if (!state.isWorkoutActive) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final routine = state.routine!;
        final exercises = routine.exercises;

        // Compute overall progress
        final totalSets = state.setsData.values.expand((list) => list).length;
        final completedSets = state.setsData.values
            .expand((list) => list)
            .where((s) => s.isCompleted)
            .length;
        final progress = totalSets > 0 ? completedSets / totalSets : 0.0;
        final progressPct = (progress * 100).round();

        // Estimate time: ~2 min per set (including rest)
        final estimatedMinutes = totalSets * 2;
        final estHours = estimatedMinutes ~/ 60;
        final estMins = estimatedMinutes % 60;
        final timeLabel = estHours > 0
            ? '~${estHours}h ${estMins}m'
            : '~${estMins}m';

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          body: SafeArea(
            child: Column(
              children: [
                // ── Custom App Bar ──
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              routine.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${exercises.length} bài tập',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Timer display
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: state.isTimerRunning
                              ? Colors.deepOrange.withValues(alpha: 0.1)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 18,
                              color: state.isTimerRunning
                                  ? Colors.deepOrange
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formattedTime(state.workoutElapsedSeconds),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: state.isTimerRunning
                                    ? Colors.deepOrange
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Rest Timer Banner ──
                if (state.restSecondsRemaining > 0)
                  _RestTimerBanner(state: state),

                Expanded(
                  child: exercises.isEmpty
                      ? _EmptyExercisesPlaceholder(routineName: routine.name)
                      : ListView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          children: [
                            // ── Progress Card ──
                            _ProgressHeaderCard(
                              routineName: routine.name,
                              progress: progress,
                              progressPct: progressPct,
                              timeLabel: timeLabel,
                              exerciseCount: exercises.length,
                            ),
                            const SizedBox(height: 20),

                            // ── Exercise List Header ──
                            Row(
                              children: [
                                Icon(
                                  Icons.list_rounded,
                                  size: 18,
                                  color: Colors.grey.shade700,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Danh sách bài tập',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // ── Exercise List ──
                            ...exercises.asMap().entries.map((entry) {
                              final index = entry.key;
                              final ex = entry.value;

                              // Check if all sets for this exercise are done
                              final setsForEx = state.setsData[index] ?? [];
                              final allDone =
                                  setsForEx.isNotEmpty &&
                                  setsForEx.every((s) => s.isCompleted);

                              return _ExerciseListItem(
                                index: index,
                                exercise: ex,
                                isCompleted: allDone,
                                onTap: () => _navigateToExerciseDetail(
                                  context,
                                  exerciseIndex: index,
                                  entry: ex,
                                ),
                              );
                            }),
                            const SizedBox(height: 24),
                          ],
                        ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              height: 54,
              width: double.infinity,
              child: FilledButton(
                onPressed: state.isTimerRunning
                    ? () => _showFinishDialog(context)
                    : () => context.read<ActiveWorkoutCubit>().beginWorkout(),
                style: FilledButton.styleFrom(
                  backgroundColor: state.isTimerRunning
                      ? Colors.red
                      : Colors.deepOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      state.isTimerRunning
                          ? Icons.stop_rounded
                          : Icons.play_arrow_rounded,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      state.isTimerRunning
                          ? 'KẾT THÚC TẬP LUYỆN'
                          : 'BẮT ĐẦU TẬP LUYỆN',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Navigates to the full ActiveExerciseDetailScreen.
  Future<void> _navigateToExerciseDetail(
    BuildContext context, {
    required int exerciseIndex,
    required ExerciseEntry entry,
  }) async {
    // Create ExerciseModel directly from entry data (no Firestore fetch)
    final model = ExerciseModel(
      exerciseId: '',
      name: entry.exerciseName,
      primaryMuscle: entry.primaryMuscle,
      createdAt: DateTime.now(),
    );

    // Wrap the detail screen in ActiveExerciseCubit linking it to the workout sets
    final workoutCubit = context.read<ActiveWorkoutCubit>();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => ActiveExerciseCubit(
            exerciseIndex: exerciseIndex,
            targetSets: entry.sets,
            targetReps: entry.reps,
            restTimeSeconds: entry.restTime,
            workoutCubit: workoutCubit,
          ),
          child: ActiveExerciseDetailScreen(exercise: model, entry: entry),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty Placeholder (when routine has no exercises)
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyExercisesPlaceholder extends StatelessWidget {
  final String routineName;

  const _EmptyExercisesPlaceholder({required this.routineName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fitness_center_rounded,
              size: 64,
              color: colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              routineName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Buổi tập này chưa có bài tập nào.\nHãy thêm bài tập vào giáo án của bạn.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Progress Header Card
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressHeaderCard extends StatelessWidget {
  final String routineName;
  final double progress;
  final int progressPct;
  final String timeLabel;
  final int exerciseCount;

  const _ProgressHeaderCard({
    required this.routineName,
    required this.progress,
    required this.progressPct,
    required this.timeLabel,
    required this.exerciseCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF5722), // deepOrange
            Color(0xFFFF7043), // deepOrange.shade400
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepOrange.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular progress
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    strokeCap: StrokeCap.round,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    color: Colors.white,
                  ),
                ),
                Center(
                  child: Text(
                    '$progressPct%',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),

          // Routine info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Đang tập luyện',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  routineName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.fitness_center_rounded,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$exerciseCount bài tập',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Exercise List Item
// ─────────────────────────────────────────────────────────────────────────────

class _ExerciseListItem extends StatelessWidget {
  final int index;
  final ExerciseEntry exercise;
  final bool isCompleted;
  final VoidCallback onTap;

  const _ExerciseListItem({
    required this.index,
    required this.exercise,
    required this.isCompleted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isCompleted
                  ? AppColors.success.withValues(alpha: 0.08)
                  : Colors.white,
              border: Border.all(
                color: isCompleted
                    ? AppColors.success.withValues(alpha: 0.3)
                    : Colors.grey.shade200,
                width: 1.5,
              ),
              boxShadow: isCompleted
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              children: [
                // Exercise number / check icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: isCompleted
                        ? LinearGradient(
                            colors: [
                              AppColors.success,
                              AppColors.success.withValues(alpha: 0.8),
                            ],
                          )
                        : LinearGradient(
                            colors: [
                              Colors.deepOrange.shade400,
                              Colors.deepOrange.shade300,
                            ],
                          ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: (isCompleted ? AppColors.success : Colors.deepOrange)
                            .withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 24,
                          )
                        : Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),

                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.exerciseName,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: isCompleted
                              ? colorScheme.onSurface.withValues(alpha: 0.5)
                              : Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _InfoChip(
                            icon: Icons.repeat_rounded,
                            label: '${exercise.sets}×${exercise.reps}',
                            color: isCompleted ? AppColors.success : Colors.deepOrange,
                          ),
                          const SizedBox(width: 8),
                          if (exercise.weight != null)
                            _InfoChip(
                              icon: Icons.fitness_center_rounded,
                              label: '${exercise.weight!.toStringAsFixed(0)}kg',
                              color: isCompleted ? AppColors.success : Colors.blue,
                            ),
                          if (exercise.weight != null) const SizedBox(width: 8),
                          _InfoChip(
                            icon: Icons.timer_outlined,
                            label: '${exercise.restTime}s',
                            color: isCompleted ? AppColors.success : Colors.grey,
                          ),
                        ],
                      ),
                      if (exercise.primaryMuscle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          exercise.primaryMuscle,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Chevron
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: (isCompleted ? AppColors.success : Colors.deepOrange)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.arrow_forward_ios_rounded,
                    color: isCompleted ? AppColors.success : Colors.deepOrange,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Helper chip widget for exercise info
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color.withValues(alpha: 0.8)),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Set Logging Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _SetLoggingSheet extends StatefulWidget {
  final int exerciseIndex;
  final ExerciseEntry exercise;

  const _SetLoggingSheet({required this.exerciseIndex, required this.exercise});

  @override
  State<_SetLoggingSheet> createState() => _SetLoggingSheetState();
}

class _SetLoggingSheetState extends State<_SetLoggingSheet> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<ActiveWorkoutCubit, ActiveWorkoutState>(
      builder: (context, state) {
        final sets = state.setsData[widget.exerciseIndex] ?? [];
        final completedCount = sets.where((s) => s.isCompleted).length;

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Sheet Header ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.exercise.exerciseName,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (widget.exercise.primaryMuscle.isNotEmpty)
                                Text(
                                  widget.exercise.primaryMuscle,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Progress badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: completedCount >= widget.exercise.sets
                                ? AppColors.success.withValues(alpha: 0.12)
                                : colorScheme.primaryContainer.withValues(
                                    alpha: 0.5,
                                  ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$completedCount / ${widget.exercise.sets} hiệp',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: completedCount >= widget.exercise.sets
                                  ? AppColors.success
                                  : colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Target info ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      children: [
                        _InfoChip(
                          icon: Icons.repeat_rounded,
                          label: '${widget.exercise.reps} lần/hiệp',
                          color: Colors.deepOrange,
                        ),
                        const SizedBox(width: 8),
                        _InfoChip(
                          icon: Icons.timer_rounded,
                          label: 'Nghỉ ${widget.exercise.restTime}s',
                          color: colorScheme.primary,
                        ),
                        if (widget.exercise.weight != null) ...[
                          const SizedBox(width: 8),
                          _InfoChip(
                            icon: Icons.fitness_center_rounded,
                            label:
                                '${widget.exercise.weight!.toStringAsFixed(0)} kg',
                            color: colorScheme.tertiary,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const Divider(height: 24, indent: 20, endIndent: 20),

                  // ── Set rows ──
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: sets.length,
                      itemBuilder: (context, setIndex) {
                        final setData = sets[setIndex];
                        return _SetRow(
                          setNumber: setIndex + 1,
                          setData: setData,
                          defaultReps: widget.exercise.reps,
                          defaultWeight: widget.exercise.weight ?? 0,
                          onToggle: () => context
                              .read<ActiveWorkoutCubit>()
                              .completeSet(widget.exerciseIndex, setIndex),
                          onWeightChanged: (v) => context
                              .read<ActiveWorkoutCubit>()
                              .updateWeight(widget.exerciseIndex, setIndex, v),
                          onRepsChanged: (v) => context
                              .read<ActiveWorkoutCubit>()
                              .updateReps(widget.exerciseIndex, setIndex, v),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Set Row (in logging sheet)
// ─────────────────────────────────────────────────────────────────────────────

class _SetRow extends StatefulWidget {
  final int setNumber;
  final SetData setData;
  final int defaultReps;
  final double defaultWeight;
  final VoidCallback onToggle;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<int> onRepsChanged;

  const _SetRow({
    required this.setNumber,
    required this.setData,
    required this.defaultReps,
    required this.defaultWeight,
    required this.onToggle,
    required this.onWeightChanged,
    required this.onRepsChanged,
  });

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _repsCtrl;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(
      text: widget.defaultWeight > 0
          ? widget.defaultWeight.toStringAsFixed(0)
          : '',
    );
    _repsCtrl = TextEditingController(text: widget.defaultReps.toString());
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCompleted = widget.setData.isCompleted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? AppColors.success.withValues(alpha: 0.4)
              : colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        color: isCompleted
            ? AppColors.success.withValues(alpha: 0.06)
            : colorScheme.surface,
      ),
      child: Row(
        children: [
          // Set number badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.success.withValues(alpha: 0.15)
                  : colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${widget.setNumber}',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isCompleted
                      ? AppColors.success
                      : colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Weight input
          Expanded(
            child: _CompactInput(
              controller: _weightCtrl,
              label: 'Kg',
              isDecimal: true,
              enabled: !isCompleted,
              onChanged: (v) {
                final parsed = double.tryParse(v);
                if (parsed != null) widget.onWeightChanged(parsed);
              },
            ),
          ),
          const SizedBox(width: 8),

          // Reps input
          Expanded(
            child: _CompactInput(
              controller: _repsCtrl,
              label: 'Lần',
              isDecimal: false,
              enabled: !isCompleted,
              onChanged: (v) {
                final parsed = int.tryParse(v);
                if (parsed != null) widget.onRepsChanged(parsed);
              },
            ),
          ),
          const SizedBox(width: 10),

          // Toggle complete button
          GestureDetector(
            onTap: widget.onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.success
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
                border: isCompleted
                    ? null
                    : Border.all(color: colorScheme.outlineVariant),
              ),
              child: Icon(
                isCompleted ? Icons.check_rounded : Icons.check_rounded,
                size: 20,
                color: isCompleted ? Colors.white : colorScheme.outline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compact Input Field
// ─────────────────────────────────────────────────────────────────────────────

class _CompactInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isDecimal;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const _CompactInput({
    required this.controller,
    required this.label,
    required this.isDecimal,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: isDecimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      textAlign: TextAlign.center,
      onChanged: onChanged,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rest Timer Banner
// ─────────────────────────────────────────────────────────────────────────────

class _RestTimerBanner extends StatelessWidget {
  final ActiveWorkoutState state;

  const _RestTimerBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<ActiveWorkoutCubit>();
    final progress = state.restSecondsRemaining / state.restDuration;
    final mins = state.restSecondsRemaining ~/ 60;
    final secs = state.restSecondsRemaining % 60;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.blue.shade600,
            Colors.blue.shade400,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular timer
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 4,
                    strokeCap: StrokeCap.round,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    color: Colors.white,
                  ),
                ),
                Center(
                  child: Text(
                    '$mins:${secs.toString().padLeft(2, '0')}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nghỉ giữa hiệp',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hít thở sâu và thư giãn cơ bắp',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: cubit.skipRest,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Bỏ qua'),
          ),
        ],
      ),
    );
  }
}
