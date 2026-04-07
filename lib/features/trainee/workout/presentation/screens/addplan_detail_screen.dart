import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

import '../../data/models/exercise_model.dart';
import '../../data/models/routine_model.dart';
import '../../data/models/workout_plan_model.dart';
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
          context.pop(true);
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
          backgroundColor: Colors.white,
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: FilledButton(
                onPressed: state.isSaving ? null : () => context.read<PlanDetailCubit>().savePlan(),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF92A3FD),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                ),
                child: state.isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Lưu',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                // ── Custom Header ──
                _CompactHeader(
                  plan: plan,
                  onBack: () => context.pop(),
                  onStatistics: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => PlanStatisticsBottomSheet(plan: plan),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // ── Plan Banner ──
                _PlanBannerSection(
                  imageUrl: plan.imageUrl,
                  onEdit: () => _showBannerDialog(context, plan.imageUrl),
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

                // ── Notes & Add Exercise ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      flex: 2,
                      child: _NotesSection(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: _AddExerciseButton(
                        onPressed: () => _navigateToExerciseLibrary(context),
                      ),
                    ),
                  ],
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
              style: GoogleFonts.inter(
                fontSize: 14,
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

  void _showBannerDialog(BuildContext context, String currentUrl) {
    final controller = TextEditingController(text: currentUrl);

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Cập nhật ảnh banner'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Link ảnh',
            hintText: 'https://example.com/banner.jpg',
          ),
        ),
        actions: [
          if (currentUrl.isNotEmpty)
            TextButton(
              onPressed: () {
                context.read<PlanDetailCubit>().updateBannerUrl('');
                Navigator.pop(dialogCtx);
              },
              child: const Text('Xóa ảnh'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              context.read<PlanDetailCubit>().updateBannerUrl(
                controller.text,
              );
              Navigator.pop(dialogCtx);
            },
            child: const Text('Lưu'),
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

class _PlanBannerSection extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onEdit;

  const _PlanBannerSection({
    required this.imageUrl,
    required this.onEdit,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Ảnh banner',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1C29),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.image_outlined, size: 16),
                label: Text(
                  imageUrl.isEmpty ? 'Thêm ảnh' : 'Sửa ảnh',
                  style: GoogleFonts.inter(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF6F7FB),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: imageUrl.isNotEmpty
                ? Image.asset(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildBannerPlaceholder(),
                  )
                : _buildBannerPlaceholder(),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.image_rounded,
          size: 28,
          color: Colors.grey,
        ),
        const SizedBox(height: 8),
        Text(
          'Chưa có ảnh banner',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compact Header
// ─────────────────────────────────────────────────────────────────────────────

class _CompactHeader extends StatelessWidget {
  final WorkoutPlanModel plan;
  final VoidCallback onBack;
  final VoidCallback onStatistics;

  const _CompactHeader({
    required this.plan,
    required this.onBack,
    required this.onStatistics,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Back button
        IconButton(
          onPressed: onBack,
          icon: const Icon(
            Icons.arrow_back_ios,
            size: 16,
            color: Colors.black,),
        ),
        const SizedBox(width: 8),

        // Title
        Expanded(
          child: Text(
            'New plan detail',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1C29),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        const SizedBox(width: 8),
        // Action buttons
        OutlinedButton.icon(
          onPressed: onStatistics,
          icon: const Icon(Icons.bar_chart_rounded, size: 16),
          label: const Text('Thống kê'),
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            textStyle: GoogleFonts.inter(fontSize: 12),
            side: BorderSide(color: Colors.grey.shade300),
            foregroundColor: Colors.grey.shade700,
          ),
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
                    color: Color(0xFF92A3FD),
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
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1C29),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${routine?.exercises.length ?? 0} động tác',
                        style: GoogleFonts.inter(
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
              style: GoogleFonts.inter(
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
      style: GoogleFonts.inter(fontSize: 13),
      decoration: InputDecoration(
        hintText: 'Ghi chú',
        hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500),
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
      height: 60, // Match typical maxLines: 2 Textfield height
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Color(0xFF92A3FD),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // Match text field radius
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 20),
            SizedBox(height: 2),
            Text(
              'Thêm bài',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
              const SizedBox(height: 12),
              Text(
                'Chưa có bài tập',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: onAddTap,
                child: Text(
                  'Mở thư viện chọn bài tập',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Color(0xFF92A3FD),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF92A3FD),
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
          style: GoogleFonts.inter(
            fontSize: 14,
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
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              title: Text(
                ex.exerciseName,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                '${ex.sets} hiệp × ${ex.reps} lần · Nghỉ ${ex.restTime}s',
                style: GoogleFonts.inter(
                  fontSize: 12,
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

class _PlanStructure extends StatefulWidget {
  final WorkoutPlanModel plan;
  final int currentIndex;
  final ValueChanged<int> onRoutineSelected;

  const _PlanStructure({
    required this.plan,
    required this.currentIndex,
    required this.onRoutineSelected,
  });

  @override
  State<_PlanStructure> createState() => _PlanStructureState();
}

class _PlanStructureState extends State<_PlanStructure> {
  late final PageController _pageController;
  late int _currentWeek;

  // Giả lập ánh xạ thứ ngày
  static const List<String> _dayNames = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

  @override
  void initState() {
    super.initState();
    final routinesPerWeek = widget.plan.trainingDays.isNotEmpty ? widget.plan.trainingDays.length : 1;
    final initialWeekIndex = widget.currentIndex ~/ routinesPerWeek;
    _currentWeek = initialWeekIndex + 1;
    _pageController = PageController(initialPage: initialWeekIndex);
  }

  @override
  void didUpdateWidget(covariant _PlanStructure oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      final routinesPerWeek = widget.plan.trainingDays.isNotEmpty ? widget.plan.trainingDays.length : 1;
      final newWeekIndex = widget.currentIndex ~/ routinesPerWeek;
      if (newWeekIndex + 1 != _currentWeek) {
        setState(() => _currentWeek = newWeekIndex + 1);
        _pageController.animateToPage(
          newWeekIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routines = widget.plan.routines;
    final totalWeeks = widget.plan.totalWeeks;
    final routinesPerWeek = widget.plan.trainingDays.isNotEmpty ? widget.plan.trainingDays.length : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Cấu trúc giáo án',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8F8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (_currentWeek > 1) {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Icon(
                      Icons.chevron_left,
                      color: _currentWeek > 1 ? const Color(0xFF92A3FD) : Colors.grey.shade300,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Week $_currentWeek / $totalWeeks',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      if (_currentWeek < totalWeeks) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Icon(
                      Icons.chevron_right,
                      color: _currentWeek < totalWeeks ? const Color(0xFF92A3FD) : Colors.grey.shade300,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // PageView (Các thẻ kéo sang ngang được)
        SizedBox(
          height: 600,
          child: PageView.builder(
            controller: _pageController,
            itemCount: totalWeeks,
            onPageChanged: (index) {
              setState(() {
                _currentWeek = index + 1;
              });
            },
            itemBuilder: (context, index) {
              final weekNumber = index + 1;
              final weekStart = index * routinesPerWeek;

              return Container(
                margin: const EdgeInsets.only(bottom: 20, left: 0, right: 0),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04), // Cực kỳ mờ và mịn
                      blurRadius: 15,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sub-header
                    Row(
                      children: [
                        Transform.rotate(
                          angle: pi / 4,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF92A3FD), // Tím pastel
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Transform.rotate(
                              angle: -pi / 4,
                              child: Center(
                                child: Text(
                                  '$weekNumber',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'Week $weekNumber',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: List.generate(7, (dotIndex) {
                            final isWorkout = widget.plan.trainingDays.contains(dotIndex + 1);
                            return Container(
                              margin: const EdgeInsets.only(left: 6),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isWorkout ? const Color(0xFF92A3FD) : Colors.grey.shade300,
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Day list
                    Column(
                      children: List.generate(7, (dayIndex) {
                        final int realDayIndex = dayIndex + 1; // 1 to 7
                        final bool hasWorkout = widget.plan.trainingDays.contains(realDayIndex);

                        if (!hasWorkout) {
                          return const SizedBox.shrink();
                        } else {
                          final dayPositionInWeek = widget.plan.trainingDays.indexOf(realDayIndex);
                          final globalRoutineIndex = weekStart + dayPositionInWeek;
                          final isSelected = widget.currentIndex == globalRoutineIndex;

                          final routineName = (globalRoutineIndex < routines.length) 
                                ? routines[globalRoutineIndex].name 
                                : 'Bài tập';
                                
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 30,
                                  child: Text(
                                    _dayNames[dayIndex],
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600,
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => widget.onRoutineSelected(globalRoutineIndex),
                                    borderRadius: BorderRadius.circular(12),
                                    child: _buildWorkoutCard(routineName, isSelected),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      }),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWorkoutCard(String title, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.deepOrange.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? Border.all(color: Colors.deepOrange.shade300, width: 1.5) : null,
        boxShadow: isSelected ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected ? Colors.deepOrange.withValues(alpha: 0.15) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              image: const DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=200&h=200&fit=crop',
                ),
                fit: BoxFit.cover,
                opacity: 0.8,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.fitness_center_rounded,
                size: 20,
                color: isSelected ? Colors.deepOrange : Colors.white70,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                color: isSelected ? Colors.deepOrange.shade800 : Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isSelected) ...[
            const SizedBox(width: 8),
            const Icon(Icons.check_circle_rounded, color: Colors.deepOrange, size: 20),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }


}

