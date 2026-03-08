import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/routine_model.dart';
import '../../data/models/workout_plan_model.dart';
import '../../data/repositories/workout_repository.dart';
import '../../logic/plan_detail_cubit.dart';
import '../../logic/workout_template_bloc.dart';
import '../../logic/workout_template_event.dart';
import '../widgets/plan_statistics_bottom_sheet.dart';

/// Displays full detail of a [WorkoutPlanModel], allowing editing
/// routines, exercises, notes, renaming and copying between days.
class PlanDetailScreen extends StatelessWidget {
  const PlanDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PlanDetailCubit, PlanDetailState>(
      listener: (context, state) {
        if (state.savedSuccessfully) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã lưu giáo án thành công!')),
          );
        }
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      builder: (context, state) {
        final plan = state.plan;
        final routine = state.currentRoutine;

        return Scaffold(
          appBar: _buildAppBar(context, plan, state.isSaving),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // ── Section 1: Routine Header ──
              _RoutineHeader(routine: routine),
              const SizedBox(height: 16),

              // ── Section 2: Action Buttons ──
              _ActionButtons(
                onRename: () => _showRenameDialog(context, routine),
                onCopy: () => _showCopyDialog(
                  context,
                  plan.routines.length,
                  state.currentRoutineIndex,
                ),
              ),
              const SizedBox(height: 20),

              // ── Section 3: Notes ──
              const _NotesSection(),
              const SizedBox(height: 20),

              // ── Section 4: Add Exercise Button ──
              _AddExerciseButton(
                onPressed: () => _navigateToExerciseLibrary(context),
              ),
              const SizedBox(height: 16),

              // ── Section 5: Exercise List ──
              _ExerciseList(
                exercises: routine?.exercises ?? [],
                onRemove: (i) =>
                    context.read<PlanDetailCubit>().removeExercise(i),
                onAddTap: () => _navigateToExerciseLibrary(context),
              ),
              const SizedBox(height: 24),

              // ── Section 6: Plan Structure ──
              _PlanStructure(
                plan: plan,
                currentIndex: state.currentRoutineIndex,
                onRoutineSelected: (i) =>
                    context.read<PlanDetailCubit>().selectRoutine(i),
              ),
              const SizedBox(height: 32),
            ],
          ),
          bottomNavigationBar: _ActivatePlanBar(
            plan: plan,
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    WorkoutPlanModel plan,
    bool isSaving,
  ) {
    final theme = Theme.of(context);

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plan.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${plan.totalWeeks} tuần - ${plan.trainingDays.length} buổi/tuần',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
      actions: [
        OutlinedButton.icon(
          onPressed: () {
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => PlanStatisticsBottomSheet(plan: plan),
            );
          },
          icon: const Icon(Icons.bar_chart_rounded, size: 18),
          label: const Text('Thống kê'),
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: isSaving
              ? null
              : () => context.read<PlanDetailCubit>().savePlan(),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            visualDensity: VisualDensity.compact,
          ),
          child: isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Lưu'),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  // ── Dialogs ──

  void _showRenameDialog(BuildContext context, RoutineModel? routine) {
    if (routine == null) return;
    final controller = TextEditingController(text: routine.name);

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Đổi tên buổi tập'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Tên mới',
            hintText: 'VD: Ngực - Tay sau',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                context.read<PlanDetailCubit>().renameCurrentRoutine(name);
              }
              Navigator.pop(dialogCtx);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showCopyDialog(
    BuildContext context,
    int totalRoutines,
    int currentIdx,
  ) {
    final controller = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Copy qua ngày'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sao chép toàn bộ bài tập của buổi hiện tại sang buổi khác.',
              style: Theme.of(dialogCtx).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  dialogCtx,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Buổi số',
                hintText: 'VD: 3',
                helperText: 'Nhập số từ 1 đến $totalRoutines',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final target = int.tryParse(controller.text.trim());
              if (target != null && target >= 1 && target <= totalRoutines) {
                context.read<PlanDetailCubit>().copyToRoutine(
                  target - 1,
                ); // 0-indexed
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã sao chép sang Buổi tập $target')),
                );
              }
            },
            child: const Text('Sao chép'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToExerciseLibrary(BuildContext context) async {
    final result = await context.push<List<ExerciseModel>>(
      '/exercise-library?mode=selection',
    );
    if (result == null || result.isEmpty || !context.mounted) return;

    final cubit = context.read<PlanDetailCubit>();
    for (final selected in result) {
      final entry = ExerciseEntry(
        exerciseName: selected.name,
        primaryMuscle: selected.primaryMuscle,
        sets: 3,
        reps: 10,
        restTime: 60,
      );
      cubit.addExercise(entry);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã thêm ${result.length} bài tập')),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section 1: Routine Header
// ─────────────────────────────────────────────────────────────────────────────

class _RoutineHeader extends StatelessWidget {
  final RoutineModel? routine;

  const _RoutineHeader({this.routine});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.deepOrange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.calendar_today_rounded,
            color: Colors.deepOrange,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                routine?.name ?? 'Buổi tập',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${routine?.exercises.length ?? 0} động tác',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section 2: Action Buttons
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final VoidCallback onRename;
  final VoidCallback onCopy;

  const _ActionButtons({required this.onRename, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onRename,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Đổi tên'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Copy qua ngày'),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section 3: Notes
// ─────────────────────────────────────────────────────────────────────────────

class _NotesSection extends StatelessWidget {
  const _NotesSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 18, color: AppColors.error),
            const SizedBox(width: 6),
            Text(
              'Ghi chú buổi tập',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Thêm các lưu ý khởi động...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section 4: Add Exercise Button
// ─────────────────────────────────────────────────────────────────────────────

class _AddExerciseButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddExerciseButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text('Thêm Bài Tập'),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.deepOrange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section 5: Exercise List
// ─────────────────────────────────────────────────────────────────────────────

class _ExerciseList extends StatelessWidget {
  final List<ExerciseEntry> exercises;
  final ValueChanged<int> onRemove;
  final VoidCallback onAddTap;

  const _ExerciseList({
    required this.exercises,
    required this.onRemove,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (exercises.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.fitness_center_rounded,
                size: 40,
                color: colorScheme.onSurface.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 12),
              Text(
                'Chưa có bài tập nào',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: onAddTap,
                child: Text(
                  'Mở thư viện chọn bài tập',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.deepOrange,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.deepOrange,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Danh sách bài tập',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...exercises.asMap().entries.map((entry) {
          final i = entry.key;
          final ex = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: colorScheme.primaryContainer.withValues(
                  alpha: 0.5,
                ),
                child: Text(
                  '${i + 1}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              title: Text(
                ex.exerciseName,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                '${ex.sets} hiệp × ${ex.reps} lần · Nghỉ ${ex.restTime}s',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              trailing: IconButton(
                onPressed: () => onRemove(i),
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                tooltip: 'Xóa bài tập',
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section 6: Plan Structure
// ─────────────────────────────────────────────────────────────────────────────

class _PlanStructure extends StatelessWidget {
  final WorkoutPlanModel plan;
  final int currentIndex;
  final ValueChanged<int> onRoutineSelected;

  const _PlanStructure({
    required this.plan,
    required this.currentIndex,
    required this.onRoutineSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final routines = plan.routines;

    // Group routines into weeks
    final routinesPerWeek = plan.trainingDays.isNotEmpty
        ? plan.trainingDays.length
        : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cấu trúc giáo án',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: plan.totalWeeks,
          itemBuilder: (context, weekIdx) {
            final weekStart = weekIdx * routinesPerWeek;
            final weekEnd = (weekStart + routinesPerWeek).clamp(
              0,
              routines.length,
            );
            final weekRoutines = routines.sublist(
              weekStart.clamp(0, routines.length),
              weekEnd,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Week label
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 6),
                  child: Text(
                    'Tuần ${weekIdx + 1}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                // Routines in this week
                ...weekRoutines.asMap().entries.map((entry) {
                  final globalIdx = weekStart + entry.key;
                  final r = entry.value;
                  final isSelected = globalIdx == currentIndex;

                  return InkWell(
                    onTap: () => onRoutineSelected(globalIdx),
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.deepOrange.withValues(alpha: 0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          // Indicator dot
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? Colors.deepOrange
                                  : colorScheme.outline.withValues(alpha: 0.3),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              r.name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Colors.deepOrange
                                    : colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Text(
                            '${r.exercises.length} bài',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isSelected
                                  ? Colors.deepOrange.withValues(alpha: 0.7)
                                  : colorScheme.onSurface.withValues(
                                      alpha: 0.4,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Activate Plan Bar
// ═══════════════════════════════════════════════════════════════════════════════

class _ActivatePlanBar extends StatefulWidget {
  final WorkoutPlanModel plan;

  const _ActivatePlanBar({required this.plan});

  @override
  State<_ActivatePlanBar> createState() => _ActivatePlanBarState();
}

class _ActivatePlanBarState extends State<_ActivatePlanBar> {
  bool _isActivating = false;

  Future<void> _activate() async {
    setState(() => _isActivating = true);
    try {
      await WorkoutRepository().setActivePlan(widget.plan.planId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã áp dụng "${widget.plan.name}"'),
          ),
        );
        // Pop back so the list/dashboard refreshes
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
        setState(() => _isActivating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.plan.isActive;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.3),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: isActive
              ? FilledButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Đang áp dụng'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    disabledBackgroundColor:
                        AppColors.success.withValues(alpha: 0.3),
                    disabledForegroundColor:
                        AppColors.success,
                  ),
                )
              : FilledButton.icon(
                  onPressed: _isActivating ? null : _activate,
                  icon: _isActivating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.play_arrow_rounded),
                  label: const Text('Áp dụng Giáo án này'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
