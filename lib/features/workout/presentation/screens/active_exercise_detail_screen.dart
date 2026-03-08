import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/exercise_model.dart';
import '../../data/models/routine_model.dart';
import '../../logic/active_exercise_cubit.dart';
import 'exercise_detail_screen.dart';

/// Detail screen for performing a single exercise during a workout.
///
/// Shows target info, rest timer, set logging form, and history.
class ActiveExerciseDetailScreen extends StatefulWidget {
  final ExerciseModel exercise;
  final ExerciseEntry entry;

  const ActiveExerciseDetailScreen({
    super.key,
    required this.exercise,
    required this.entry,
  });

  @override
  State<ActiveExerciseDetailScreen> createState() =>
      _ActiveExerciseDetailScreenState();
}

class _ActiveExerciseDetailScreenState
    extends State<ActiveExerciseDetailScreen> {
  final _kgController = TextEditingController();
  final _repsController = TextEditingController();

  @override
  void dispose() {
    _kgController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  void _addSet(BuildContext context) {
    final kg = double.tryParse(_kgController.text.trim()) ?? 0;
    final reps = int.tryParse(_repsController.text.trim()) ?? 0;
    if (reps <= 0) return;

    context.read<ActiveExerciseCubit>().logSet(kg, reps);
    _kgController.clear();
    _repsController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final exercise = widget.exercise;

    return BlocBuilder<ActiveExerciseCubit, ActiveExerciseState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              '${widget.entry.sets} Hiệp${exercise.primaryMuscle.isNotEmpty ? ' · ${exercise.primaryMuscle}' : ''}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Làm mới',
              ),
              IconButton(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => DraggableScrollableSheet(
                      initialChildSize: 0.9,
                      minChildSize: 0.5,
                      maxChildSize: 0.95,
                      expand: false,
                      builder: (ctx, scrollCtrl) {
                        return ExerciseDetailScreen(exercise: exercise);
                      },
                    ),
                  );
                },
                icon: const Icon(
                  Icons.info_outline_rounded,
                  color: Colors.cyan,
                ),
                tooltip: 'Chi tiết bài tập',
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            children: [
              // ── Placeholder Image ──
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Icon(
                    Icons.fitness_center,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Title & Instructions ──
              Text(
                exercise.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Recommended weight: ${widget.entry.weight != null ? '${widget.entry.weight} kg' : 'Tự do'}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (exercise.instructions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  exercise.instructions,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // ── 3 Status Circles ──
              _ThreeCircles(state: state),
              const SizedBox(height: 28),

              // ── Logging Form ──
              _LoggingForm(
                kgController: _kgController,
                repsController: _repsController,
                onAdd: () => _addSet(context),
              ),
              const SizedBox(height: 20),

              // ── History List ──
              if (state.loggedSets.isNotEmpty) ...[
                Text(
                  'Lịch sử hiệp tập',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...state.loggedSets.reversed.map(
                  (s) => _HistoryItem(loggedSet: s),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3 Status Circles
// ─────────────────────────────────────────────────────────────────────────────

class _ThreeCircles extends StatelessWidget {
  final ActiveExerciseState state;

  const _ThreeCircles({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cubit = context.read<ActiveExerciseCubit>();

    final mins = state.restRemaining ~/ 60;
    final secs = state.restRemaining % 60;
    final timerLabel =
        '${mins.toString().padLeft(2, '0')}:'
        '${secs.toString().padLeft(2, '0')}';
    final timerProgress = state.restTimeSeconds > 0
        ? state.restRemaining / state.restTimeSeconds
        : 0.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // ── Circle 1: Target Reps ──
        _CircleWidget(
          size: 90,
          borderColor: Colors.teal,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${state.targetReps}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              Text(
                'Repeats required',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),

        // ── Circle 2: Rest Timer ──
        GestureDetector(
          onTap: cubit.toggleTimer,
          child: SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: timerProgress,
                  strokeWidth: 5,
                  backgroundColor: Colors.teal.withValues(alpha: 0.12),
                  color: Colors.teal,
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        timerLabel,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Icon(
                        state.isTimerRunning
                            ? Icons.stop_rounded
                            : Icons.play_arrow_rounded,
                        size: 20,
                        color: Colors.teal.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Circle 3: Sets Progress ──
        _CircleWidget(
          size: 90,
          progress: state.progress,
          borderColor: Colors.orange,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${state.completedSets}/${state.targetSets}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              Text(
                'Sets done',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Reusable bordered circle with optional progress ring.
class _CircleWidget extends StatelessWidget {
  final double size;
  final Color borderColor;
  final Widget child;
  final double? progress;

  const _CircleWidget({
    required this.size,
    required this.borderColor,
    required this.child,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (progress != null)
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 4,
              backgroundColor: borderColor.withValues(alpha: 0.12),
              color: borderColor,
            )
          else
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 3),
              ),
            ),
          Center(child: child),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logging Form
// ─────────────────────────────────────────────────────────────────────────────

class _LoggingForm extends StatelessWidget {
  final TextEditingController kgController;
  final TextEditingController repsController;
  final VoidCallback onAdd;

  const _LoggingForm({
    required this.kgController,
    required this.repsController,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // Kg input
        Expanded(
          child: TextField(
            controller: kgController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Kilograms',
              hintText: '0',
              isDense: true,
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 14,
              ),
            ),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Reps input
        Expanded(
          child: TextField(
            controller: repsController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Repeats',
              hintText: '0',
              isDense: true,
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 14,
              ),
            ),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Add button
        Material(
          color: Colors.teal,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onAdd,
            borderRadius: BorderRadius.circular(12),
            child: const SizedBox(
              width: 52,
              height: 52,
              child: Icon(Icons.add_rounded, color: Colors.white, size: 28),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// History Item
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryItem extends StatelessWidget {
  final LoggedSet loggedSet;

  const _HistoryItem({required this.loggedSet});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final t = loggedSet.loggedAt;
    final time =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Set number badge
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.deepOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '#${loggedSet.setNumber}',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Weight x Reps
          Expanded(
            child: Text(
              '${loggedSet.weight.toStringAsFixed(loggedSet.weight.truncateToDouble() == loggedSet.weight ? 0 : 1)}'
              ' kg × ${loggedSet.reps} reps',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Time
          Text(
            time,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}
