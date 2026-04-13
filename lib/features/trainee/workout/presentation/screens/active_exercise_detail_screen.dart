import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/screens/library/exercise_detail_screen.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/routine_model.dart';
import '../../logic/active_exercise_cubit.dart';

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
                      builder: (_, __) {
                        return ExerciseDetailScreen(
                          exercise: exercise,
                          groupName: exercise.primaryMuscle.isNotEmpty
                              ? exercise.primaryMuscle
                              : 'Exercise',
                        );
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
              // ── Exercise Image with gradient overlay ──
              Stack(
                children: [
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.deepOrange.shade50,
                          Colors.orange.shade50,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepOrange.withValues(alpha: 0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.fitness_center_rounded,
                          size: 48,
                          color: Colors.deepOrange.shade400,
                        ),
                      ),
                    ),
                  ),
                  // Muscle badge
                  if (exercise.primaryMuscle.isNotEmpty)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Text(
                          exercise.primaryMuscle,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Title ──
              Text(
                exercise.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.scale_rounded,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.entry.weight != null
                        ? '${widget.entry.weight} kg'
                        : 'Bodyweight',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.repeat_rounded,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.entry.sets} hiệp × ${widget.entry.reps} lần',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
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
                Row(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Lịch sử hiệp tập',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
    final cubit = context.read<ActiveExerciseCubit>();

    final mins = state.restRemaining ~/ 60;
    final secs = state.restRemaining % 60;
    final timerLabel =
        '${mins.toString().padLeft(2, '0')}:'
        '${secs.toString().padLeft(2, '0')}';
    final timerProgress = state.restTimeSeconds > 0
        ? state.restRemaining / state.restTimeSeconds
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // ── Circle 1: Target Reps ──
          _StatCircle(
            size: 85,
            value: '${state.targetReps}',
            label: 'Lần/hiệp',
            color: Colors.teal,
            icon: Icons.repeat_rounded,
          ),

          // ── Circle 2: Rest Timer ──
          GestureDetector(
            onTap: cubit.toggleTimer,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.deepOrange.withValues(alpha: 0.08),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: CircularProgressIndicator(
                      value: timerProgress,
                      strokeWidth: 6,
                      strokeCap: StrokeCap.round,
                      backgroundColor: Colors.deepOrange.withValues(alpha: 0.15),
                      color: Colors.deepOrange,
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          timerLabel,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            state.isTimerRunning
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 16,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Circle 3: Sets Progress ──
          _StatCircle(
            size: 85,
            value: '${state.completedSets}/${state.targetSets}',
            label: 'Hiệp xong',
            color: Colors.orange,
            icon: Icons.check_circle_outline_rounded,
            progress: state.progress,
          ),
        ],
      ),
    );
  }
}

/// Reusable stat circle widget.
class _StatCircle extends StatelessWidget {
  final double size;
  final String value;
  final String label;
  final Color color;
  final IconData icon;
  final double? progress;

  const _StatCircle({
    required this.size,
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              strokeCap: StrokeCap.round,
              backgroundColor: color.withValues(alpha: 0.12),
              color: color,
            )
          else
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.3), width: 3),
              ),
            ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                  ),
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit_note_rounded,
                size: 18,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                'Ghi lại hiệp tập',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Kg input
              Expanded(
                child: _InputField(
                  controller: kgController,
                  label: 'Kg',
                  hint: '0',
                  icon: Icons.fitness_center_rounded,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 12),

              // Reps input
              Expanded(
                child: _InputField(
                  controller: repsController,
                  label: 'Lần',
                  hint: '0',
                  icon: Icons.repeat_rounded,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),

              // Add button
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepOrange, Colors.orange.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepOrange.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onAdd,
                    borderRadius: BorderRadius.circular(14),
                    child: const SizedBox(
                      width: 56,
                      height: 56,
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Styled input field widget.
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          isDense: true,
          prefixIcon: Icon(
            icon,
            size: 18,
            color: Colors.grey.shade400,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 14,
          ),
        ),
        textAlign: TextAlign.center,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
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
    final t = loggedSet.loggedAt;
    final time =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Set number badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepOrange.withValues(alpha: 0.15),
                  Colors.orange.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${loggedSet.setNumber}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Weight x Reps
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${loggedSet.weight.toStringAsFixed(loggedSet.weight.truncateToDouble() == loggedSet.weight ? 0 : 1)} kg',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${loggedSet.reps} lần',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),

          // Time
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              time,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
