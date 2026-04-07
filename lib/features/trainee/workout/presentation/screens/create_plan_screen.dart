import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/exercise_model.dart';
import '../../data/models/routine_model.dart';
import '../../data/models/workout_plan_model.dart';
import '../../data/repositories/workout_repository.dart';
import '../../logic/plan_detail_cubit.dart';
import '../widgets/plan_statistics_bottom_sheet.dart';

/// Day label mapping: 1=T2, 2=T3, ..., 7=CN.
const _dayLabelsMap = {
  1: 'Thứ 2',
  2: 'Thứ 3',
  3: 'Thứ 4',
  4: 'Thứ 5',
  5: 'Thứ 6',
  6: 'Thứ 7',
  7: 'Chủ nhật',
};

/// Combined screen for creating a new workout plan.
///
/// Step 1: Basic plan info (name, description, weeks, training days).
/// Step 2: Plan detail editor (add exercises, manage routines, save).
class CreatePlanScreen extends StatefulWidget {
  final bool isTemplate;

  const CreatePlanScreen({
    super.key,
    this.isTemplate = false,
  });

  @override
  State<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends State<CreatePlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  int _totalWeeks = 4;
  List<int> _trainingDays = [1, 3, 5];

  /// Current step: 0 = basic info, 1 = plan detail editor.
  int _currentStep = 0;

  /// Cubit instance created when moving to step 2.
  PlanDetailCubit? _planDetailCubit;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _planDetailCubit?.close();
    super.dispose();
  }

  void _toggleDay(int day) {
    setState(() {
      if (_trainingDays.contains(day)) {
        if (_trainingDays.length > 1) {
          _trainingDays = List<int>.from(_trainingDays)..remove(day);
        }
      } else {
        _trainingDays = List<int>.from(_trainingDays)..add(day);
      }
      _trainingDays.sort();
    });
  }

  /// Move from step 1 to step 2: create plan model and cubit.
  void _onContinueToDetail() {
    if (!_formKey.currentState!.validate()) return;

    final sortedDays = List<int>.from(_trainingDays)..sort();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    const uuid = Uuid();

    final routines = <RoutineModel>[];
    for (int week = 0; week < _totalWeeks; week++) {
      for (int i = 0; i < sortedDays.length; i++) {
        final dayOfWeek = sortedDays[i];
        final dayLabel = _dayLabelsMap[dayOfWeek] ?? 'Buổi ${i + 1}';
        routines.add(
          RoutineModel(
            routineId: uuid.v4(),
            name: dayLabel,
            dayOfWeek: dayOfWeek,
            exercises: [],
          ),
        );
      }
    }

    final newPlan = WorkoutPlanModel(
      planId: uuid.v4(),
      userId: userId,
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      totalWeeks: _totalWeeks,
      trainingDays: sortedDays,
      isActive: false,
      isTemplate: widget.isTemplate,
      routines: routines,
      imageUrl: 'assets/images/default_plan.jpg',
      createdAt: DateTime.now(),
    );

    // Create cubit for plan detail editing
    _planDetailCubit = PlanDetailCubit(
      workoutRepository: WorkoutRepository(),
      initialPlan: newPlan,
    );

    setState(() => _currentStep = 1);
  }

  /// Go back from step 2 to step 1.
  void _onBackToBasicInfo() {
    _planDetailCubit?.close();
    _planDetailCubit = null;
    setState(() => _currentStep = 0);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStep == 0) {
      return _buildBasicInfoStep();
    }
    // Step 1: Plan detail editor, provide cubit via BlocProvider.value
    return BlocProvider<PlanDetailCubit>.value(
      value: _planDetailCubit!,
      child: _PlanDetailStep(
        onBack: _onBackToBasicInfo,
        onSavedSuccessfully: () {
          if (mounted) context.pop(true);
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step 1: Basic Info
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildBasicInfoStep() {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: FilledButton(
            onPressed: _onContinueToDetail,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF92A3FD),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
            ),
            child: Text(
              'Next',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _CreatePlanHeader(
              onBack: () => context.pop(),
              title: widget.isTemplate ? 'New Template' : 'New Plan',
            ),
            // Step indicator
            _StepIndicator(currentStep: 0),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        'Plan Information',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        style: GoogleFonts.inter(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Plan name',
                          hintStyle: GoogleFonts.inter(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.fitness_center_rounded,
                            color: Colors.grey.shade400,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF7F8F8),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter a plan name'
                            : null,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descController,
                        style: GoogleFonts.inter(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Description (optional)',
                          hintStyle: GoogleFonts.inter(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(bottom: 60),
                            child: Icon(
                              Icons.description_outlined,
                              color: Colors.grey.shade400,
                              size: 22,
                            ),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF7F8F8),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        maxLines: 4,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Repeat',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF92A3FD),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'Weekly',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildWeekNumberField(),
                      const SizedBox(height: 24),
                      Text(
                        'Training Days',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDaySelectorField(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekNumberField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.fitness_center_rounded,
            color: Colors.grey.shade400,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Weeks: $_totalWeeks',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          _ControlButton(
            icon: Icons.remove_rounded,
            onTap: _totalWeeks > 1 ? () => setState(() => _totalWeeks--) : null,
          ),
          const SizedBox(width: 8),
          _ControlButton(
            icon: Icons.add_rounded,
            onTap: _totalWeeks < 52 ? () => setState(() => _totalWeeks++) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelectorField() {
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (i) {
          final dayValue = i + 1;
          final isSelected = _trainingDays.contains(dayValue);

          return GestureDetector(
            onTap: () => _toggleDay(dayValue),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF92A3FD) : Colors.white,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF92A3FD).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              alignment: Alignment.center,
              child: Text(
                dayLabels[i],
                style: GoogleFonts.inter(
                  color: isSelected ? Colors.white : Colors.grey.shade500,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 2: Plan Detail Editor (merged from addplan_detail_screen.dart)
// ─────────────────────────────────────────────────────────────────────────────

class _PlanDetailStep extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onSavedSuccessfully;

  const _PlanDetailStep({
    required this.onBack,
    required this.onSavedSuccessfully,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PlanDetailCubit, PlanDetailState>(
      listener: (context, state) {
        if (state.savedSuccessfully) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Plan saved successfully!')),
          );
          onSavedSuccessfully();
        }
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
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
                onPressed: state.isSaving
                    ? null
                    : () => context.read<PlanDetailCubit>().savePlan(),
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
                        'Save',
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
                // ── Header ──
                _CompactHeader(
                  plan: plan,
                  onBack: onBack,
                  onStatistics: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => PlanStatisticsBottomSheet(plan: plan),
                    );
                  },
                ),
                // Step indicator
                const _StepIndicator(currentStep: 1),
                const SizedBox(height: 12),

                // ── Plan Banner ──
                _PlanBannerSection(
                  imageUrl: plan.imageUrl,
                  onEdit: () => _showBannerDialog(context, plan.imageUrl),
                ),
                const SizedBox(height: 12),

                // ── Active Routine Card ──
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
                  onEdit: (i, updatedEx) =>
                      context.read<PlanDetailCubit>().updateExercise(i, updatedEx),
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
          ),
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
        title: const Text('Rename Routine'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'New name',
            hintText: 'E.g. Chest & Triceps',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                context.read<PlanDetailCubit>().renameCurrentRoutine(name);
              }
              Navigator.pop(dialogCtx);
            },
            child: const Text('Save'),
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
        title: const Text('Copy to day'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Copy all exercises from the current routine to another routine.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Theme.of(dialogCtx)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.text,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Routine numbers',
                hintText: 'E.g. 3, 4, 5',
                helperText: 'Enter numbers from 1 to $totalRoutines, separated by commas',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
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
                    content: Text('Copied to routines: ${targets.join(', ')}'),
                  ),
                );
              }
            },
            child: const Text('Copy'),
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
        title: const Text('Update banner image'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Image URL',
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
              child: const Text('Remove'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context
                  .read<PlanDetailCubit>()
                  .updateBannerUrl(controller.text);
              Navigator.pop(dialogCtx);
            },
            child: const Text('Save'),
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
      SnackBar(content: Text('Added ${result.length} exercises')),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Step indicator showing progress between step 1 (info) and step 2 (detail).
class _StepIndicator extends StatelessWidget {
  final int currentStep; // 0 or 1

  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
      child: Row(
        children: [
          _buildDot(0),
          Expanded(child: _buildLine(0)),
          _buildDot(1),
        ],
      ),
    );
  }

  Widget _buildDot(int step) {
    final isActive = step <= currentStep;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? const Color(0xFF92A3FD) : const Color(0xFFE8E8E8),
      ),
      child: Center(
        child: isActive && step < currentStep
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
            : Text(
                '${step + 1}',
                style: GoogleFonts.inter(
                  color: isActive ? Colors.white : Colors.grey.shade500,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  Widget _buildLine(int afterStep) {
    final isActive = afterStep < currentStep;
    return Container(
      height: 3,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF92A3FD) : const Color(0xFFE8E8E8),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _CreatePlanHeader extends StatelessWidget {
  final VoidCallback onBack;
  final String title;

  const _CreatePlanHeader({
    required this.onBack,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSquareBtn(Icons.close_rounded, onBack),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          _buildSquareBtn(Icons.more_horiz_rounded, () {}),
        ],
      ),
    );
  }

  Widget _buildSquareBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F5F5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: Colors.black87, size: 20),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _ControlButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isEnabled ? Colors.white : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isEnabled ? Colors.black87 : Colors.grey.shade400,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Plan Detail Sub-Widgets (from addplan_detail_screen.dart)
// ─────────────────────────────────────────────────────────────────────────────

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
                'Banner Image',
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
                  imageUrl.isEmpty ? 'Add image' : 'Edit image',
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
        const Icon(Icons.image_rounded, size: 28, color: Colors.grey),
        const SizedBox(height: 8),
        Text(
          'No banner image',
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
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_ios, size: 16, color: Colors.black),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Plan Details',
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
        OutlinedButton.icon(
          onPressed: onStatistics,
          icon: const Icon(Icons.bar_chart_rounded, size: 16),
          label: const Text('Stats'),
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
                        routine?.name ?? 'Routine',
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
                        '${routine?.exercises.length ?? 0} exercises',
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              _CompactActionButton(
                icon: Icons.edit_outlined,
                label: 'Rename',
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

class _NotesSection extends StatelessWidget {
  const _NotesSection();

  @override
  Widget build(BuildContext context) {
    return TextField(
      maxLines: 2,
      style: GoogleFonts.inter(fontSize: 13),
      decoration: InputDecoration(
        hintText: 'Notes',
        hintStyle:
            GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500),
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
          borderSide: const BorderSide(color: Color(0xFF92A3FD)),
        ),
      ),
    );
  }
}

class _AddExerciseButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddExerciseButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF92A3FD),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 20),
            SizedBox(height: 2),
            Text(
              'Add exercise',
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

class _ExerciseList extends StatelessWidget {
  final List<ExerciseEntry> exercises;
  final ValueChanged<int> onRemove;
  final VoidCallback onAddTap;
  final void Function(int index, ExerciseEntry entry) onEdit;

  const _ExerciseList({
    required this.exercises,
    required this.onRemove,
    required this.onAddTap,
    required this.onEdit,
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
                'No exercises yet',
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
                  'Open library to add exercises',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF92A3FD),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: const Color(0xFF92A3FD),
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
          'Exercise List',
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
              onTap: () => _showEditExerciseSheet(context, i, ex),
              leading: CircleAvatar(
                radius: 18,
                backgroundColor:
                    colorScheme.primaryContainer.withValues(alpha: 0.5),
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
                '${ex.sets} sets × ${ex.reps} reps · Rest ${ex.restTime}s',
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
                tooltip: 'Remove exercise',
              ),
            ),
          );
        }),
      ],
    );
  }

  void _showEditExerciseSheet(BuildContext context, int index, ExerciseEntry ex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _EditExerciseForm(
        initialEntry: ex,
        onSave: (updatedEx) {
          onEdit(index, updatedEx);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _EditExerciseForm extends StatefulWidget {
  final ExerciseEntry initialEntry;
  final ValueChanged<ExerciseEntry> onSave;

  const _EditExerciseForm({required this.initialEntry, required this.onSave});

  @override
  State<_EditExerciseForm> createState() => _EditExerciseFormState();
}

class _EditExerciseFormState extends State<_EditExerciseForm> {
  late int _sets;
  late int _reps;
  late int _restTime;

  @override
  void initState() {
    super.initState();
    _sets = widget.initialEntry.sets;
    _reps = widget.initialEntry.reps;
    _restTime = widget.initialEntry.restTime;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Edit ${widget.initialEntry.exerciseName}',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            _buildCounter('Sets', _sets, (v) => setState(() => _sets = v)),
            const SizedBox(height: 16),
            _buildCounter('Reps', _reps, (v) => setState(() => _reps = v)),
            const SizedBox(height: 16),
            _buildCounter(
                'Rest (seconds)', _restTime, (v) => setState(() => _restTime = v),
                step: 15),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: () {
                  widget.onSave(
                    widget.initialEntry.copyWith(
                      sets: _sets,
                      reps: _reps,
                      restTime: _restTime,
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF92A3FD),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(
                  'Save',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounter(String label, int value, ValueChanged<int> onChanged,
      {int step = 1}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        Row(
          children: [
            _ControlButton(
              icon: Icons.remove_rounded,
              onTap: value > step ? () => onChanged(value - step) : null,
            ),
            SizedBox(
              width: 50,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
            _ControlButton(
              icon: Icons.add_rounded,
              onTap: () => onChanged(value + step),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Plan Structure
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

  static const List<String> _dayNames = [
    'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su',
  ];

  @override
  void initState() {
    super.initState();
    final routinesPerWeek = widget.plan.trainingDays.isNotEmpty
        ? widget.plan.trainingDays.length
        : 1;
    final initialWeekIndex = widget.currentIndex ~/ routinesPerWeek;
    _currentWeek = initialWeekIndex + 1;
    _pageController = PageController(initialPage: initialWeekIndex);
  }

  @override
  void didUpdateWidget(covariant _PlanStructure oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      final routinesPerWeek = widget.plan.trainingDays.isNotEmpty
          ? widget.plan.trainingDays.length
          : 1;
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
    final routinesPerWeek = widget.plan.trainingDays.isNotEmpty
        ? widget.plan.trainingDays.length
        : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Plan Structure',
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
                      color: _currentWeek > 1
                          ? const Color(0xFF92A3FD)
                          : Colors.grey.shade300,
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
                      color: _currentWeek < totalWeeks
                          ? const Color(0xFF92A3FD)
                          : Colors.grey.shade300,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // PageView
        SizedBox(
          height: 600,
          child: PageView.builder(
            controller: _pageController,
            itemCount: totalWeeks,
            onPageChanged: (index) {
              setState(() => _currentWeek = index + 1);
            },
            itemBuilder: (context, index) {
              final weekNumber = index + 1;
              final weekStart = index * routinesPerWeek;

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
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
                              color: const Color(0xFF92A3FD),
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
                            final isWorkout = widget.plan.trainingDays
                                .contains(dotIndex + 1);
                            return Container(
                              margin: const EdgeInsets.only(left: 6),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isWorkout
                                    ? const Color(0xFF92A3FD)
                                    : Colors.grey.shade300,
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
                        final int realDayIndex = dayIndex + 1;
                        final bool hasWorkout =
                            widget.plan.trainingDays.contains(realDayIndex);

                        if (!hasWorkout) return const SizedBox.shrink();

                        final dayPositionInWeek =
                            widget.plan.trainingDays.indexOf(realDayIndex);
                        final globalRoutineIndex =
                            weekStart + dayPositionInWeek;
                        final isSelected =
                            widget.currentIndex == globalRoutineIndex;

                        final routineName =
                            (globalRoutineIndex < routines.length)
                                ? routines[globalRoutineIndex].name
                                : 'Workout';

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
                                  onTap: () => widget
                                      .onRoutineSelected(globalRoutineIndex),
                                  borderRadius: BorderRadius.circular(12),
                                  child: _buildWorkoutCard(
                                    routineName,
                                    isSelected,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
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
        color: isSelected
            ? const Color(0xFF92A3FD).withValues(alpha: 0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: const Color(0xFF92A3FD), width: 1.5)
            : null,
        boxShadow: isSelected
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF92A3FD).withValues(alpha: 0.15)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                Icons.fitness_center_rounded,
                size: 20,
                color: isSelected ? const Color(0xFF92A3FD) : Colors.grey,
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
                color: isSelected
                    ? const Color(0xFF92A3FD)
                    : Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isSelected) ...[
            const SizedBox(width: 8),
            const Icon(Icons.check_circle_rounded,
                color: Color(0xFF92A3FD), size: 20),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
