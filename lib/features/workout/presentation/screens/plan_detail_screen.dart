import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/routine_model.dart';
import '../../data/models/workout_plan_model.dart';
import '../../data/repositories/workout_repository.dart';
import '../../logic/plan_detail_cubit.dart';
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
          context.pop();
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
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                // ── Custom Header ──
                _CompactHeader(
                  plan: plan,
                  isSaving: state.isSaving,
                  onBack: () => context.pop(),
                  onStatistics: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => PlanStatisticsBottomSheet(plan: plan),
                    );
                  },
                  onSave: () => context.read<PlanDetailCubit>().savePlan(),
                ),
                const SizedBox(height: 12),

                // ── Active Routine Card (compact) ──
                _ActiveRoutineCard(
                  routine: routine,
                  onRename: () => _showRenameDialog(context, routine),
                  onCopy: () => _showCopyDialog(
                    context,
                    plan.routines.length,
                    state.currentRoutineIndex,
                  ),
                ),
                const SizedBox(height: 12),

                // ── Notes (compact) ──
                const _NotesSection(),
                const SizedBox(height: 12),

                // ── Add Exercise Button ──
                _AddExerciseButton(
                  onPressed: () => _navigateToExerciseLibrary(context),
                ),
                const SizedBox(height: 12),

                // ── Exercise List ──
                _ExerciseList(
                  exercises: routine?.exercises ?? [],
                  onRemove: (i) =>
                      context.read<PlanDetailCubit>().removeExercise(i),
                  onAddTap: () => _navigateToExerciseLibrary(context),
                ),
                const SizedBox(height: 16),

                // ── Plan Structure ──
                _PlanStructure(
                  plan: plan,
                  currentIndex: state.currentRoutineIndex,
                  onRoutineSelected: (i) =>
                      context.read<PlanDetailCubit>().selectRoutine(i),
                ),
                const SizedBox(height: 24),
              ],
            ),
          )
        );
      },
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
              keyboardType: TextInputType.text,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Các buổi số',
                hintText: 'VD: 3, 4, 5',
                helperText: 'Nhập số từ 1 đến $totalRoutines, cách nhau bởi dấu phẩy',
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
              final text = controller.text.trim();
              if (text.isEmpty) return;
              
              final targets = text
                  .split(',')
                  .map((e) => int.tryParse(e.trim()))
                  .where((e) => e != null && e >= 1 && e <= totalRoutines)
                  .map((e) => e!)
                  .toSet()
                  .toList();
                  
              if (targets.isNotEmpty) {
                for (final target in targets) {
                  if (target - 1 != currentIdx) {
                    context.read<PlanDetailCubit>().copyToRoutine(target - 1);
                  }
                }
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã sao chép sang các Buổi: ${targets.join(', ')}'),
                  ),
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
// Compact Header
// ─────────────────────────────────────────────────────────────────────────────

class _CompactHeader extends StatelessWidget {
  final WorkoutPlanModel plan;
  final bool isSaving;
  final VoidCallback onBack;
  final VoidCallback onStatistics;
  final VoidCallback onSave;

  const _CompactHeader({
    required this.plan,
    required this.isSaving,
    required this.onBack,
    required this.onStatistics,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Back button
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey.shade100,
          ),
        ),
        const SizedBox(width: 8),

        // Title & Subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GA: ${plan.name}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1C29),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '${plan.totalWeeks} tuần'),
                    TextSpan(
                      text: '  •  ',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    TextSpan(text: '${plan.trainingDays.length} buổi/tuần'),
                  ],
                ),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // Action buttons
        OutlinedButton.icon(
          onPressed: onStatistics,
          icon: const Icon(Icons.bar_chart_rounded, size: 16),
          label: const Text('Thống kê'),
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            textStyle: const TextStyle(fontSize: 12),
            side: BorderSide(color: Colors.grey.shade300),
            foregroundColor: Colors.grey.shade700,
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: isSaving ? null : onSave,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFF03613),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            visualDensity: VisualDensity.compact,
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          child: isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Lưu'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Active Routine Card (Compact horizontal layout)
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveRoutineCard extends StatelessWidget {
  final RoutineModel? routine;
  final VoidCallback onRename;
  final VoidCallback onCopy;

  const _ActiveRoutineCard({
    required this.routine,
    required this.onRename,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left column: Info
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDECE8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    color: Color(0xFFF03613),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        routine?.name ?? 'Buổi tập',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1C29),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${routine?.exercises.length ?? 0} động tác',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Right column: Actions
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              _CompactActionButton(
                icon: Icons.edit_outlined,
                label: 'Đổi tên',
                onTap: onRename,
              ),
              const SizedBox(height: 4),
              _CompactActionButton(
                icon: Icons.copy_rounded,
                label: 'Copy',
                onTap: onCopy,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CompactActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.grey.shade700),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notes Section (Compact)
// ─────────────────────────────────────────────────────────────────────────────

class _NotesSection extends StatelessWidget {
  const _NotesSection();

  @override
  Widget build(BuildContext context) {
    return TextField(
      maxLines: 2,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: 'Thêm ghi chú khởi động...',
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFF03613)),
        ),
      ),
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

