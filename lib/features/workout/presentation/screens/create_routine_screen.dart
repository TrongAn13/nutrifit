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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'Cấu trúc giáo án',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
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
              // ── Day Selector (White container, bottom radius) ──
              _DaySelector(
                trainingDays: widget.trainingDays,
                selectedIndex: _selectedDayIndex,
                routines: state.routines,
                onSelected: (i) => setState(() => _selectedDayIndex = i),
              ),

              // ── Body ──
              Expanded(
                child: routine.exercises.isEmpty
                    ? _EmptyExerciseState(
                        nameCtrl: nameCtrl,
                        dayIndex: _selectedDayIndex,
                        onAddExercise: _addExercise,
                      )
                    : _ExerciseListBody(
                        routine: routine,
                        nameCtrl: nameCtrl,
                        dayIndex: _selectedDayIndex,
                        onAddExercise: _addExercise,
                      ),
              ),
            ],
          );
        },
      ),
      // ── Bottom Sticky Save Button ──
      bottomNavigationBar: _SaveBottomBar(
        onSave: _savePlan,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Day Selector — White container with bottom radius
// ═══════════════════════════════════════════════════════════════════════════════

class _DaySelector extends StatelessWidget {
  final List<int> trainingDays;
  final int selectedIndex;
  final List<RoutineModel> routines;
  final ValueChanged<int> onSelected;

  const _DaySelector({
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(trainingDays.length, (i) {
            final isSelected = i == selectedIndex;
            final dayLabel = _dayLabels[trainingDays[i]] ?? '?';
            final exerciseCount =
                i < routines.length ? routines[i].exercises.length : 0;

            return Padding(
              padding: EdgeInsets.only(
                right: i < trainingDays.length - 1 ? 8 : 0,
              ),
              child: GestureDetector(
                onTap: () => onSelected(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.deepOrange
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dayLabel,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : Colors.grey[600],
                        ),
                      ),
                      if (exerciseCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.25)
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$exerciseCount',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey[700],
                              fontSize: 11,
                            ),
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
// Empty State — No exercises for the selected day
// ═══════════════════════════════════════════════════════════════════════════════

class _EmptyExerciseState extends StatelessWidget {
  final TextEditingController nameCtrl;
  final int dayIndex;
  final VoidCallback onAddExercise;

  const _EmptyExerciseState({
    required this.nameCtrl,
    required this.dayIndex,
    required this.onAddExercise,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Routine name field
          _RoutineNameField(controller: nameCtrl, dayIndex: dayIndex),
          const SizedBox(height: 64),

          // Empty state illustration
          Icon(
            Icons.fitness_center_rounded,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có bài tập nào cho ngày này.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Add exercise button
          _AddExerciseButton(onPressed: onAddExercise),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Exercise List Body — Has exercises
// ═══════════════════════════════════════════════════════════════════════════════

class _ExerciseListBody extends StatelessWidget {
  final RoutineModel routine;
  final TextEditingController nameCtrl;
  final int dayIndex;
  final VoidCallback onAddExercise;

  const _ExerciseListBody({
    required this.routine,
    required this.nameCtrl,
    required this.dayIndex,
    required this.onAddExercise,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // Routine name field
        _RoutineNameField(controller: nameCtrl, dayIndex: dayIndex),
        Text(
          '${routine.exercises.length} bài tập',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 20),

        // Exercise cards (Reorderable)
        _ExerciseReorderableList(
          exercises: routine.exercises,
          routineIndex: dayIndex,
        ),
        const SizedBox(height: 16),

        // Add exercise button
        _AddExerciseButton(onPressed: onAddExercise),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Routine Name Field
// ═══════════════════════════════════════════════════════════════════════════════

class _RoutineNameField extends StatelessWidget {
  final TextEditingController controller;
  final int dayIndex;

  const _RoutineNameField({
    required this.controller,
    required this.dayIndex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      onChanged: (v) => context
          .read<CreatePlanCubit>()
          .updateRoutineName(dayIndex, v),
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      decoration: InputDecoration(
        hintText: 'Tên buổi tập (VD: Ngực - Tay sau)',
        hintStyle: theme.textTheme.titleLarge?.copyWith(
          color: Colors.grey[350],
          fontWeight: FontWeight.bold,
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
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

  const _ExerciseReorderableList({
    required this.exercises,
    required this.routineIndex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            elevation: 6,
            borderRadius: BorderRadius.circular(16),
            shadowColor: Colors.black26,
            child: child,
          ),
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final ex = exercises[index];

        return Container(
          key: ValueKey('$routineIndex-$index-${ex.exerciseName}'),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
            child: Row(
              children: [
                // Drag handle
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      color: Colors.grey[350],
                      size: 22,
                    ),
                  ),
                ),

                // Exercise icon placeholder
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.fitness_center_rounded,
                    color: Colors.grey[400],
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),

                // Exercise name + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ex.exerciseName,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        ex.primaryMuscle.isNotEmpty
                            ? '${ex.sets} hiệp × ${ex.reps} lần • ${ex.primaryMuscle}'
                            : '${ex.sets} hiệp × ${ex.reps} lần',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),

                // Delete button
                IconButton(
                  onPressed: () => context
                      .read<CreatePlanCubit>()
                      .removeExercise(routineIndex, index),
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: Colors.red[300],
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
// Add Exercise Button — Outlined / dashed style
// ═══════════════════════════════════════════════════════════════════════════════

class _AddExerciseButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddExerciseButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          Icons.add_rounded,
          size: 22,
          color: Colors.deepOrange[400],
        ),
        label: Text(
          'Thêm bài tập',
          style: TextStyle(
            color: Colors.deepOrange[400],
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: Colors.deepOrange.withValues(alpha: 0.3),
            width: 1.5,
          ),
          backgroundColor: Colors.deepOrange.withValues(alpha: 0.03),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Bottom Sticky Save Bar
// ═══════════════════════════════════════════════════════════════════════════════

class _SaveBottomBar extends StatelessWidget {
  final VoidCallback onSave;

  const _SaveBottomBar({required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: BlocBuilder<CreatePlanCubit, CreatePlanState>(
          builder: (context, state) {
            return SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: state.isSaving ? null : onSave,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
                child: state.isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text('LƯU VÀ ÁP DỤNG'),
              ),
            );
          },
        ),
      ),
    );
  }
}
