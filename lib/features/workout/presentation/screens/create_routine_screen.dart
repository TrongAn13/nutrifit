import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/exercise_model.dart';
import '../../data/models/routine_model.dart';
import '../../logic/create_plan_cubit.dart';

/// Day label mapping: 1=T2, 2=T3, ..., 7=CN.
const _dayLabels = {
  1: 'Thứ 2',
  2: 'Thứ 3',
  3: 'Thứ 4',
  4: 'Thứ 5',
  5: 'Thứ 6',
  6: 'Thứ 7',
  7: 'CN',
};

/// Screen for building routines (sessions) using a horizontal day-tab layout.
///
/// Only builds ONE "base week"; the cubit duplicates it across [totalWeeks]
/// when saving.
class CreateRoutineScreen extends StatefulWidget {
  final String planName;
  final String planDescription;
  final int totalWeeks;
  final List<int> trainingDays;

  const CreateRoutineScreen({
    super.key,
    required this.planName,
    required this.planDescription,
    required this.totalWeeks,
    required this.trainingDays,
  });

  @override
  State<CreateRoutineScreen> createState() => _CreateRoutineScreenState();
}

class _CreateRoutineScreenState extends State<CreateRoutineScreen> {
  int _selectedDayIndex = 0;

  /// One TextEditingController per routine, keyed by index.
  final Map<int, TextEditingController> _nameControllers = {};

  @override
  void initState() {
    super.initState();
    context.read<CreatePlanCubit>().initRoutines(widget.trainingDays);
  }

  @override
  void dispose() {
    for (final c in _nameControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(int index, String initialName) {
    if (!_nameControllers.containsKey(index)) {
      _nameControllers[index] = TextEditingController(text: initialName);
    }
    return _nameControllers[index]!;
  }

  /// Opens the exercise library in multi-select mode, then adds
  /// all selected exercises with default values.
  Future<void> _addExercise() async {
    final result = await context.push<List<ExerciseModel>>(
      '/exercise-library?mode=selection',
    );
    if (result == null || result.isEmpty || !mounted) return;

    final cubit = context.read<CreatePlanCubit>();
    for (final selected in result) {
      final entry = ExerciseEntry(
        exerciseName: selected.name,
        primaryMuscle: selected.primaryMuscle,
        sets: 3,
        reps: 10,
        restTime: 60,
      );
      cubit.addExerciseToRoutine(_selectedDayIndex, entry);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã thêm ${result.length} bài tập')),
      );
    }
  }

  Future<void> _savePlan() async {
    await context.read<CreatePlanCubit>().savePlan(
      name: widget.planName,
      description: widget.planDescription,
      totalWeeks: widget.totalWeeks,
      trainingDays: widget.trainingDays,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cấu trúc giáo án'),
        actions: [
          BlocBuilder<CreatePlanCubit, CreatePlanState>(
            builder: (context, state) {
              return FilledButton(
                onPressed: state.isSaving ? null : _savePlan,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  visualDensity: VisualDensity.compact,
                ),
                child: state.isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Lưu'),
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: BlocConsumer<CreatePlanCubit, CreatePlanState>(
        listener: (context, state) {
          if (state.isSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã tạo giáo án thành công! 🎉')),
            );
            context.go('/main');
          }
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (context, state) {
          if (state.routines.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Clamp selected index
          if (_selectedDayIndex >= state.routines.length) {
            _selectedDayIndex = 0;
          }

          final routine = state.routines[_selectedDayIndex];
          final nameCtrl = _controllerFor(_selectedDayIndex, routine.name);

          return Column(
            children: [
              // ── Day Tabs ──
              _DayTabBar(
                trainingDays: widget.trainingDays,
                selectedIndex: _selectedDayIndex,
                routines: state.routines,
                onSelected: (i) => setState(() => _selectedDayIndex = i),
              ),

              // ── Body ──
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  children: [
                    // Routine name field
                    TextField(
                      controller: nameCtrl,
                      onChanged: (v) => context
                          .read<CreatePlanCubit>()
                          .updateRoutineName(_selectedDayIndex, v),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Tên buổi tập (VD: Ngực - Tay sau)',
                        hintStyle: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.3),
                          fontWeight: FontWeight.bold,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Text(
                      '${routine.exercises.length} bài tập',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Notes button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tính năng ghi chú đang phát triển'),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.note_add_outlined,
                          size: 18,
                          color: Colors.deepOrange.shade400,
                        ),
                        label: Text(
                          'Thêm ghi chú buổi tập',
                          style: TextStyle(color: Colors.deepOrange.shade400),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Exercise list (ReorderableListView)
                    if (routine.exercises.isNotEmpty) ...[
                      _ExerciseReorderableList(
                        exercises: routine.exercises,
                        routineIndex: _selectedDayIndex,
                        theme: theme,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Add exercise button
                    _AddExerciseButton(onPressed: _addExercise),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Day Tab Bar
// ═══════════════════════════════════════════════════════════════════════════════

class _DayTabBar extends StatelessWidget {
  final List<int> trainingDays;
  final int selectedIndex;
  final List<RoutineModel> routines;
  final ValueChanged<int> onSelected;

  const _DayTabBar({
    required this.trainingDays,
    required this.selectedIndex,
    required this.routines,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(trainingDays.length, (i) {
            final isSelected = i == selectedIndex;
            final dayLabel = _dayLabels[trainingDays[i]] ?? '?';
            final exerciseCount = i < routines.length
                ? routines[i].exercises.length
                : 0;

            return Padding(
              padding: EdgeInsets.only(right: i < trainingDays.length - 1 ? 8 : 0),
              child: GestureDetector(
                onTap: () => onSelected(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.deepOrange
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dayLabel,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      if (exerciseCount > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          '$exerciseCount bài',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isSelected
                                ? Colors.white70
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Exercise Reorderable List
// ═══════════════════════════════════════════════════════════════════════════════

class _ExerciseReorderableList extends StatelessWidget {
  final List<ExerciseEntry> exercises;
  final int routineIndex;
  final ThemeData theme;

  const _ExerciseReorderableList({
    required this.exercises,
    required this.routineIndex,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: exercises.length,
      onReorder: (oldIndex, newIndex) {
        context.read<CreatePlanCubit>().reorderExercises(
          routineIndex,
          oldIndex,
          newIndex,
        );
      },
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (ctx, child) => Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(14),
            child: child,
          ),
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final ex = exercises[index];

        return Card(
          key: ValueKey('$routineIndex-$index-${ex.exerciseName}'),
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                // Drag handle
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      color: colorScheme.outline.withValues(alpha: 0.4),
                      size: 22,
                    ),
                  ),
                ),

                // Exercise icon placeholder
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.fitness_center_rounded,
                    color: Colors.deepOrange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Exercise name + muscle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ex.exerciseName,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (ex.primaryMuscle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          ex.primaryMuscle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Delete button
                IconButton(
                  onPressed: () => context
                      .read<CreatePlanCubit>()
                      .removeExercise(routineIndex, index),
                  icon: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: colorScheme.outline.withValues(alpha: 0.5),
                  ),
                  tooltip: 'Xóa bài tập',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Add Exercise Button
// ═══════════════════════════════════════════════════════════════════════════════

class _AddExerciseButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddExerciseButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add_rounded, size: 22, color: Colors.deepOrange),
        label: const Text(
          'Thêm bài tập',
          style: TextStyle(
            color: Colors.deepOrange,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.deepOrange, width: 1.2),
          backgroundColor: Colors.deepOrange.withValues(alpha: 0.04),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
