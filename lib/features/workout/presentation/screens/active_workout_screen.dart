import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/theme/app_colors.dart';
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
                    builder: (_) => WorkoutResultScreen(history: history),
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
          appBar: AppBar(
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            centerTitle: true,
            title: Text(
              routine.name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Text(
                    _formattedTime(state.workoutElapsedSeconds),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: state.isTimerRunning
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: state.isTimerRunning
                          ? Colors.deepOrange
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // ── Rest Timer Banner ──
              if (state.restSecondsRemaining > 0)
                _RestTimerBanner(state: state),

              Expanded(
                child: exercises.isEmpty
                    ? _EmptyExercisesPlaceholder(routineName: routine.name)
                    : ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        children: [
                          // ── Header Card ──
                          _ProgressHeaderCard(
                            routineName: routine.name,
                            progress: progress,
                            progressPct: progressPct,
                            timeLabel: timeLabel,
                            exerciseCount: exercises.length,
                          ),
                          const SizedBox(height: 20),

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
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                height: 54,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: state.isTimerRunning
                      ? () => _showFinishDialog(context)
                      : () => context.read<ActiveWorkoutCubit>().beginWorkout(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: state.isTimerRunning
                        ? Colors.red
                        : Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    state.isTimerRunning
                        ? 'KẾT THÚC TẬP LUYỆN'
                        : 'BẮT ĐẦU TẬP LUYỆN',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
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
    // Show a loading indicator while fetching
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    // 1. Fetch the full ExerciseModel to get instructions and tags
    ExerciseModel? model;
    try {
      final repo = WorkoutRepository();
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final allExercises = await repo.getExercises(uid);
      model = allExercises.firstWhere(
        (e) => e.name == entry.exerciseName,
        orElse: () => ExerciseModel(
          exerciseId: '',
          name: entry.exerciseName,
          primaryMuscle: entry.primaryMuscle,
          createdAt: DateTime.now(),
        ),
      );
    } catch (_) {
      model = ExerciseModel(
        exerciseId: '',
        name: entry.exerciseName,
        primaryMuscle: entry.primaryMuscle,
        createdAt: DateTime.now(),
      );
    }

    if (context.mounted) {
      Navigator.of(context).pop(); // dismiss loading
    }

    if (!context.mounted) return;

    // 2. Wrap the detail screen in ActiveExerciseCubit linking it to the workout sets
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
          child: ActiveExerciseDetailScreen(exercise: model!, entry: entry),
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
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        color: colorScheme.surface,
      ),
      child: Row(
        children: [
          // Circular progress
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: Colors.deepOrange.withValues(alpha: 0.12),
                  color: Colors.deepOrange,
                ),
                Center(
                  child: Text(
                    '$progressPct%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Routine info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hôm nay',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  routineName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$exerciseCount bài tập',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),

          // Estimated time
          Column(
            children: [
              Icon(
                Icons.timer_outlined,
                size: 20,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 4),
              Text(
                timeLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
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
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isCompleted
                  ? AppColors.success.withValues(alpha: 0.4)
                  : colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
            color: isCompleted
                ? AppColors.success.withValues(alpha: 0.06)
                : colorScheme.surfaceContainerLowest,
          ),
          child: Row(
            children: [
              // Exercise icon / check
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.success.withValues(alpha: 0.12)
                      : colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.fitness_center_rounded,
                  size: 26,
                  color: isCompleted
                      ? AppColors.success
                      : colorScheme.onPrimaryContainer,
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
                            : null,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${exercise.sets} hiệp × ${exercise.reps} lần'
                      '${exercise.weight != null ? ' · ${exercise.weight!.toStringAsFixed(0)} kg' : ''}'
                      ' · Nghỉ ${exercise.restTime}s',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isCompleted
                            ? AppColors.success.withValues(alpha: 0.7)
                            : colorScheme.primary.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (exercise.primaryMuscle.isNotEmpty) ...[
                      const SizedBox(height: 2),
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
              Icon(
                isCompleted
                    ? Icons.check_circle_outline_rounded
                    : Icons.chevron_right_rounded,
                color: isCompleted
                    ? AppColors.success
                    : colorScheme.primary.withValues(alpha: 0.5),
                size: 24,
              ),
            ],
          ),
        ),
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
// Info Chip
// ─────────────────────────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                  color: AppColors.accent,
                ),
                Center(
                  child: Text(
                    '$mins:${secs.toString().padLeft(2, '0')}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Nghỉ giữa hiệp',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(onPressed: cubit.skipRest, child: const Text('Bỏ qua')),
        ],
      ),
    );
  }
}
