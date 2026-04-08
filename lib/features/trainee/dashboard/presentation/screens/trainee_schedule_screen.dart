import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/routes/app_router.dart';

import '../../logic/active_plan_cubit.dart';
import '../../../workout/data/models/routine_model.dart';
import '../../../workout/data/models/workout_history_model.dart';
import '../../../workout/data/models/workout_plan_model.dart';
import '../../../workout/data/repositories/workout_repository.dart';
import '../../../workout/presentation/screens/workout_ready_screen.dart';
import '../../../workout/presentation/screens/workout_record_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

const Color _kBg = Color(0xFF060708);
const Color _kCardBg = Color(0xFF1B1D22);
const Color _kLime = Color(0xFFD7FF1F);
const Color _kSkipRed = Color(0xFFFF3B30);
const Color _kTextGrey = Color(0xFFA0A0A0);
const Color _kBorderColor = Color(0xFF333333);

const List<String> _kWeekHeaders = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
const List<String> _kMonthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// Full-month calendar schedule screen.
class MyScheduleScreen extends StatefulWidget {
  const MyScheduleScreen({super.key});

  @override
  State<MyScheduleScreen> createState() => _MyScheduleScreenState();
}

class _MyScheduleScreenState extends State<MyScheduleScreen> {
  late DateTime _displayedMonth;
  late DateTime _selectedDate;
  late final ActivePlanCubit _activePlanCubit;
  late final WorkoutRepository _workoutRepository;
  late Future<List<WorkoutHistoryModel>> _historiesFuture;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month);
    _selectedDate = DateTime(now.year, now.month, now.day);
    _workoutRepository = WorkoutRepository();
    _historiesFuture = _workoutRepository.getWorkoutHistories();
    _activePlanCubit = ActivePlanCubit(
      workoutRepository: _workoutRepository,
    )..loadActivePlan();
  }

  void _reloadAllHistories() {
    setState(() {
      _historiesFuture = _workoutRepository.getWorkoutHistories();
    });
  }

  @override
  void dispose() {
    _activePlanCubit.close();
    super.dispose();
  }

  void _goToPreviousMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1);
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _displayedMonth = DateTime(now.year, now.month);
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _activePlanCubit,
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: _kBg,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
          title: Text(
            'My Schedule',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: BlocBuilder<ActivePlanCubit, ActivePlanState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator(color: _kLime));
            }
            final plan = state.plan;

            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                children: [
                  // Legend
                  _buildLegend(),
                  const SizedBox(height: 24),
                  // Month navigation
                  _buildMonthNavigation(),
                  const SizedBox(height: 16),
                  // Calendar grid + Bottom card share histories
                  FutureBuilder<List<WorkoutHistoryModel>>(
                    future: _historiesFuture,
                    builder: (context, snapshot) {
                      final histories = snapshot.data ?? [];
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _CalendarMonthGrid(
                              displayedMonth: _displayedMonth,
                              plan: plan,
                              selectedDate: _selectedDate,
                              onDateSelected: (date) {
                                setState(() => _selectedDate = date);
                              },
                              histories: histories,
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (plan != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: _TodayWorkoutBottomCard(
                                plan: plan,
                                selectedDate: _selectedDate,
                                histories: histories,
                                onHistoriesChanged: _reloadAllHistories,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LegendDot(color: _kLime, label: 'Finish'),
          const SizedBox(width: 20),
          _LegendDot(color: Colors.white, label: 'Scheduled'),
          const SizedBox(width: 20),
          _LegendDot(color: _kSkipRed, label: 'Skip'),
        ],
      ),
    );
  }

  Widget _buildMonthNavigation() {
    final now = DateTime.now();
    final isCurrentMonth =
        _displayedMonth.year == now.year && _displayedMonth.month == now.month;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_kMonthNames[_displayedMonth.month - 1]} ${_displayedMonth.year}',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              // Today button
              GestureDetector(
                onTap: isCurrentMonth ? null : _goToToday,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isCurrentMonth ? _kLime : Colors.white54,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Today',
                    style: GoogleFonts.inter(
                      color: isCurrentMonth ? _kLime : Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _goToPreviousMonth,
                child: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: _goToNextMonth,
                child: const Icon(Icons.chevron_right, color: Colors.white, size: 28),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Legend Dot
// ─────────────────────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Calendar Month Grid
// ─────────────────────────────────────────────────────────────────────────────

class _CalendarMonthGrid extends StatelessWidget {
  const _CalendarMonthGrid({
    required this.displayedMonth,
    required this.plan,
    required this.selectedDate,
    required this.onDateSelected,
    required this.histories,
  });

  final DateTime displayedMonth;
  final WorkoutPlanModel? plan;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final List<WorkoutHistoryModel> histories;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final firstDayOfMonth = DateTime(displayedMonth.year, displayedMonth.month, 1);
    final daysInMonth = DateTime(displayedMonth.year, displayedMonth.month + 1, 0).day;
    final lastDayOfPrevMonth = DateTime(displayedMonth.year, displayedMonth.month, 0).day;

    // Monday = 1, so offset = (weekday - 1)
    final startWeekday = firstDayOfMonth.weekday; // 1=Mon ... 7=Sun
    final leadingBlanks = startWeekday - 1;

    final totalCells = leadingBlanks + daysInMonth;
    int totalRows = (totalCells / 7).ceil();
    if (totalRows > 5) totalRows = 5;

    final Map<int, List<String>> routinesByDay = {};
    if (plan != null) {
      for (final routine in plan!.routines) {
        routinesByDay.putIfAbsent(routine.dayOfWeek, () => []);
        routinesByDay[routine.dayOfWeek]!.add(routine.name);
      }
    }

    return Column(
      children: [
        // Week headers
        Row(
          children: List.generate(7, (i) {
            final isSunday = i == 6;
            return Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _kWeekHeaders[i],
                    style: GoogleFonts.inter(
                      color: isSunday ? _kLime : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        // Calendar Table
        Table(
          border: TableBorder.all(color: _kBorderColor, width: 0.5),
          children: List.generate(totalRows, (row) {
            return TableRow(
              children: List.generate(7, (col) {
                final cellIndex = row * 7 + col;
                
                int dayNumber;
                bool isCurrentMonth = true;
                
                if (cellIndex < leadingBlanks) {
                  // Previous month
                  isCurrentMonth = false;
                  dayNumber = lastDayOfPrevMonth - leadingBlanks + cellIndex + 1;
                } else if (cellIndex >= leadingBlanks + daysInMonth) {
                  // Next month
                  isCurrentMonth = false;
                  dayNumber = cellIndex - (leadingBlanks + daysInMonth) + 1;
                } else {
                  // Current month
                  dayNumber = cellIndex - leadingBlanks + 1;
                }

                DateTime date;
                if (cellIndex < leadingBlanks) {
                  date = DateTime(displayedMonth.year, displayedMonth.month - 1, dayNumber);
                } else if (cellIndex >= leadingBlanks + daysInMonth) {
                  date = DateTime(displayedMonth.year, displayedMonth.month + 1, dayNumber);
                } else {
                  date = DateTime(displayedMonth.year, displayedMonth.month, dayNumber);
                }

                final isToday = date == today;
                final isSelected = date.year == selectedDate.year && date.month == selectedDate.month && date.day == selectedDate.day;
                final weekday = date.weekday; 

                final routines = routinesByDay[weekday] ?? [];
                final showRoutines = plan != null && plan!.trainingDays.contains(weekday);
                
                // Find status for this date
                final history = histories.firstWhere(
                  (h) => h.date.year == date.year && h.date.month == date.month && h.date.day == date.day,
                  orElse: () => WorkoutHistoryModel(id: '', userId: '', routineName: '', date: DateTime(2000), durationSeconds: 0, restTimeSeconds: 0, caloriesBurned: 0, completionPercentage: 0, totalWeightLifted: 0, totalReps: 0),
                );

                final bool hasHistory = history.id.isNotEmpty;
                final bool completed = hasHistory && history.completionPercentage >= 0.0;
                final bool explicitSkipped = hasHistory && history.completionPercentage == -1.0;
                
                final dateOnly = DateTime(date.year, date.month, date.day);
                final todayOnly = DateTime(today.year, today.month, today.day);
                final planStartOnly = plan != null ? DateTime(plan!.createdAt.year, plan!.createdAt.month, plan!.createdAt.day) : DateTime(2000);
                
                final bool isPast = dateOnly.isBefore(todayOnly);
                final bool isAfterStart = !dateOnly.isBefore(planStartOnly);
                final bool isMissed = isPast && isAfterStart && showRoutines && !completed && !explicitSkipped;
                final bool skipped = explicitSkipped || isMissed;

                return GestureDetector(
                  onTap: () => onDateSelected(date),
                  child: _CalendarDayCell(
                    date: date,
                    day: dayNumber,
                    isCurrentMonth: isCurrentMonth,
                    isToday: isToday,
                    isSelected: isSelected,
                    routineNames: (showRoutines && isAfterStart) ? routines : [],
                    isSunday: col == 6,
                    isCompleted: completed,
                    isSkipped: skipped,
                  ),
                );
              }),
            );
          }),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Calendar Day Cell
// ─────────────────────────────────────────────────────────────────────────────

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.date,
    required this.day,
    required this.isCurrentMonth,
    required this.isToday,
    required this.isSelected,
    required this.routineNames,
    required this.isSunday,
    this.isCompleted = false,
    this.isSkipped = false,
  });

  final DateTime date;
  final int day;
  final bool isCurrentMonth;
  final bool isToday;
  final bool isSelected;
  final List<String> routineNames;
  final bool isSunday;
  final bool isCompleted;
  final bool isSkipped;

  @override
  Widget build(BuildContext context) {
    // Determine number color
    Color numColor;
    if (isToday) {
      numColor = isSelected ? Colors.black : _kLime;
    } else if (!isCurrentMonth) {
      numColor = Colors.white30;
    } else {
      numColor = Colors.white;
    }

    return Container(
      height: 70, // Slightly smaller height
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: isSelected ? Border.all(color: _kLime, width: 1.5) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Day number with "Today" circle logic
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isToday ? _kLime : Colors.transparent,
            ),
            child: Center(
              child: Text(
                '$day',
                style: GoogleFonts.inter(
                  color: isToday ? Colors.black : (isCurrentMonth ? Colors.white : Colors.white30),
                  fontSize: 13,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          // Routines or Status
          if (routineNames.isNotEmpty) ...[
            _RoutineChip(
              name: routineNames.first,
              isCompleted: isCompleted,
              isSkipped: isSkipped,
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Routine Chip
// ─────────────────────────────────────────────────────────────────────────────

class _RoutineChip extends StatelessWidget {
  const _RoutineChip({
    required this.name,
    this.isCompleted = false,
    this.isSkipped = false,
  });

  final String name;
  final bool isCompleted;
  final bool isSkipped;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      decoration: BoxDecoration(
        color: isSkipped ? _kSkipRed : (isCompleted ? _kLime : Colors.white),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        name,
        style: GoogleFonts.inter(
          color: isSkipped ? Colors.white : Colors.black,
          fontSize: 8,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Card — Today's Workout
// ─────────────────────────────────────────────────────────────────────────────

class _TodayWorkoutBottomCard extends StatefulWidget {
  const _TodayWorkoutBottomCard({
    required this.plan,
    required this.selectedDate,
    required this.histories,
    required this.onHistoriesChanged,
  });
  final WorkoutPlanModel plan;
  final DateTime selectedDate;
  final List<WorkoutHistoryModel> histories;
  final VoidCallback onHistoriesChanged;

  @override
  State<_TodayWorkoutBottomCard> createState() => _TodayWorkoutBottomCardState();
}

class _TodayWorkoutBottomCardState extends State<_TodayWorkoutBottomCard> {
  late final WorkoutRepository _workoutRepository;

  @override
  void initState() {
    super.initState();
    _workoutRepository = WorkoutRepository();
  }

  void _reloadHistories() {
    widget.onHistoriesChanged();
  }

  Future<void> _skipWorkout(RoutineModel routine) async {
    final skipHistory = WorkoutHistoryModel(
      id: 'skip_${DateTime.now().millisecondsSinceEpoch}',
      userId: FirebaseAuth.instance.currentUser!.uid,
      planId: widget.plan.planId,
      routineName: routine.name,
      date: widget.selectedDate, // Record skip for the selected date
      durationSeconds: 0,
      restTimeSeconds: 0,
      caloriesBurned: 0,
      completionPercentage: -1.0, // Special value for skip
      totalWeightLifted: 0,
      totalReps: 0,
    );

    try {
      await _workoutRepository.saveWorkoutHistory(skipHistory);
      _reloadHistories();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể bỏ qua buổi tập')),
        );
      }
    }
  }

  Future<void> _unskipWorkout(WorkoutHistoryModel history) async {
    try {
      await _workoutRepository.deleteWorkoutHistory(history.id);
      _reloadHistories();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể hoàn tác')),
        );
      }
    }
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  WorkoutHistoryModel? _findTodayHistory(List<WorkoutHistoryModel> histories, RoutineModel routine) {
    final List<WorkoutHistoryModel> matched = histories.where((h) {
      final sameDay = _isSameDate(h.date, widget.selectedDate);
      final sameRoutine = h.routineName == routine.name;
      final samePlan = h.planId == widget.plan.planId;
      return sameDay && sameRoutine && samePlan;
    }).toList();

    if (matched.isEmpty) return null;
    matched.sort((a, b) => b.date.compareTo(a.date));
    return matched.first;
  }

  void _openRoutine(RoutineModel routine, WorkoutHistoryModel? todayHistory) {
    if (todayHistory != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WorkoutRecordScreen(
            history: todayHistory,
          ),
        ),
      ).then((_) => _reloadHistories());
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkoutReadyScreen(
          routine: routine,
          planId: widget.plan.planId,
        ),
      ),
    ).then((_) => _reloadHistories());
  }

  Future<void> _deleteRecord(WorkoutHistoryModel history) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kCardBg,
        title: Text(
          'Xóa record?',
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Bạn có chắc muốn xóa kết quả buổi tập này?',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Hủy', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: _kSkipRed),
            child: Text('Xóa', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: _kLime)),
    );

    try {
      await _workoutRepository.deleteWorkoutHistory(history.id);
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể xóa record')),
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    _reloadHistories();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xóa record')),
    );
  }

  void _showRecordMenu(RoutineModel routine, WorkoutHistoryModel? todayHistory) {
    final bool isSkipped = todayHistory != null && todayHistory.completionPercentage == -1.0;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _kCardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        if (todayHistory == null || isSkipped) {
          // Uncompleted or Skipped workout menu
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Header
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 64,
                          height: 64,
                          child: _buildThumbnail(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              routine.name,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            RichText(
                              text: TextSpan(
                                text: 'This workout is from ',
                                style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
                                children: [
                                  TextSpan(
                                    text: 'this plan',
                                    style: GoogleFonts.inter(color: _kLime, fontSize: 14, fontWeight: FontWeight.w500),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.of(ctx).pop();
                                        context.push(AppRouter.myPlanDetail, extra: widget.plan);
                                      },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF23252A),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _MenuTile(
                          icon: Icons.swap_vert_rounded,
                          title: 'Move Workout',
                          hasProBadge: true,
                          onTap: () => Navigator.of(ctx).pop(),
                        ),
                        const Divider(height: 1, color: Colors.white10, indent: 56),
                        _MenuTile(
                          icon: Icons.circle,
                          iconColor: _kSkipRed,
                          title: isSkipped ? 'Unskip Workout' : 'Skip Workout',
                          onTap: () {
                            Navigator.of(ctx).pop();
                            if (isSkipped) {
                              _unskipWorkout(todayHistory!);
                            } else {
                              _skipWorkout(routine);
                            }
                          },
                        ),
                        if (!isSkipped) ...[
                          const Divider(height: 1, color: Colors.white10, indent: 56),
                          _MenuTile(
                            icon: Icons.calendar_today_rounded,
                            title: 'Shift whole plan',
                            onTap: () {
                              Navigator.of(ctx).pop();
                              _showShiftDialog();
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        }

        // Completed workout menu
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.open_in_new_rounded, color: Colors.white70),
                title: Text(
                  'Xem kết quả',
                  style: GoogleFonts.inter(color: Colors.white),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _openRoutine(routine, todayHistory);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: _kSkipRed),
                title: Text(
                  'Xóa record',
                  style: GoogleFonts.inter(color: _kSkipRed),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _deleteRecord(todayHistory);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  /// Shows a dialog letting the user shift the whole plan forward/backward by 1–3 weeks.
  void _showShiftDialog() {
    final fromDate = widget.selectedDate;
    // Generate shift options: +1 wk, +2 wk, +3 wk (and negative if already shifted)
    final List<int> shiftOptions = [-3, -2, -1, 1, 2, 3];
    // Default to +1 wk (index 3 in the list)
    int selectedIndex = 3;

    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    String formatOption(int weeks) {
      final target = fromDate.add(Duration(days: weeks * 7));
      final sign = weeks > 0 ? '+' : '';
      return '${monthNames[target.month - 1]} ${target.day}  ($sign$weeks wk)';
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              backgroundColor: _kCardBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      'Shift Workouts',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Subtitle
                    Text(
                      'Workouts from ${monthNames[fromDate.month - 1]} ${fromDate.day} will move to:',
                      style: GoogleFonts.inter(
                        color: Colors.white60,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    // Scroll picker
                    SizedBox(
                      height: 160,
                      child: ListWheelScrollView.useDelegate(
                        itemExtent: 56,
                        diameterRatio: 2.0,
                        physics: const FixedExtentScrollPhysics(),
                        controller: FixedExtentScrollController(initialItem: selectedIndex),
                        onSelectedItemChanged: (i) {
                          setDialogState(() => selectedIndex = i);
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: shiftOptions.length,
                          builder: (ctx, i) {
                            final isActive = i == selectedIndex;
                            return Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isActive ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                formatOption(shiftOptions[i]),
                                style: GoogleFonts.inter(
                                  color: isActive ? Colors.white : Colors.white38,
                                  fontSize: isActive ? 22 : 18,
                                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white12, height: 1),
                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(
                                color: _kLime,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        Container(width: 1, height: 48, color: Colors.white12),
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              _applyShift(shiftOptions[selectedIndex]);
                            },
                            child: Text(
                              'Shift',
                              style: GoogleFonts.inter(
                                color: _kSkipRed,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Applies the shift by updating the plan's trainingDays in Firestore.
  /// Each training day is rotated by [weeks * 7] days to remap weekdays.
  Future<void> _applyShift(int weeks) async {
    try {
      // Shift training days: rotate weekday numbers
      // e.g. if trainingDays = [1, 3, 5] and shift = +1 week,
      // the days stay the same (Mon, Wed, Fri) since it's a weekly cycle.
      // What actually shifts is the routine-to-day mapping.
      // We rotate the routines list instead of the days.
      final plan = widget.plan;
      final routines = List<RoutineModel>.from(plan.routines);

      // Rotate routine dayOfWeek by shifting
      final shiftDays = (weeks * 7) % 7; // How many weekday positions to shift
      final newRoutines = routines.map((r) {
        int newDay = ((r.dayOfWeek - 1 + shiftDays) % 7) + 1;
        return r.copyWith(dayOfWeek: newDay);
      }).toList();

      final newTrainingDays = plan.trainingDays.map((d) {
        return ((d - 1 + shiftDays) % 7) + 1;
      }).toList()..sort();

      final updatedPlan = plan.copyWith(
        routines: newRoutines,
        trainingDays: newTrainingDays,
      );

      await _workoutRepository.updatePlan(updatedPlan);
      _reloadHistories();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Plan shifted by $weeks week${weeks.abs() > 1 ? 's' : ''}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to shift plan')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayWeekday = widget.selectedDate.weekday;
    final isTrainingDay = widget.plan.trainingDays.contains(todayWeekday);

    RoutineModel? todayRoutine;
    if (isTrainingDay) {
      for (final routine in widget.plan.routines) {
        if (routine.dayOfWeek == todayWeekday) {
          todayRoutine = routine;
          break;
        }
      }
      if (todayRoutine == null) {
        final dayIndex = widget.plan.trainingDays.indexOf(todayWeekday);
        if (dayIndex >= 0 && dayIndex < widget.plan.routines.length) {
          todayRoutine = widget.plan.routines[dayIndex];
        }
      }
    }

    if (!isTrainingDay || todayRoutine == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          "Rest Day",
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    {
        final histories = widget.histories;
        final todayHistory = _findTodayHistory(histories, todayRoutine!);
        final bool hasResult = todayHistory != null && todayHistory.completionPercentage >= 0.0;
        final bool explicitSkipped = todayHistory != null && todayHistory.completionPercentage == -1.0;
        
        final selectedDateOnly = DateTime(widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day);
        final now = DateTime.now();
        final todayOnly = DateTime(now.year, now.month, now.day);
        final planStartOnly = DateTime(widget.plan.createdAt.year, widget.plan.createdAt.month, widget.plan.createdAt.day);
        
        final bool isPast = selectedDateOnly.isBefore(todayOnly);
        final bool isAfterStart = !selectedDateOnly.isBefore(planStartOnly);
        final bool isMissed = isPast && isAfterStart && !hasResult && !explicitSkipped;
        
        final bool isSkipped = explicitSkipped || isMissed;

        return GestureDetector(
          onTap: () => (isSkipped) ? _showRecordMenu(todayRoutine!, todayHistory) : _openRoutine(todayRoutine!, todayHistory),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(16),
              border: hasResult 
                ? Border.all(color: _kLime.withValues(alpha: 0.6)) 
                : (isSkipped ? Border.all(color: _kSkipRed.withValues(alpha: 0.6)) : null),
            ),
            child: Row(
              children: [
                // Status button
                GestureDetector(
                  onTap: () => (isSkipped) ? _showRecordMenu(todayRoutine!, todayHistory) : _openRoutine(todayRoutine!, todayHistory),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: hasResult ? _kLime : (isSkipped ? _kSkipRed : Colors.white),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      hasResult ? Icons.check_rounded : (isSkipped ? Icons.close_rounded : Icons.play_arrow_rounded),
                      color: isSkipped || hasResult ? Colors.white : Colors.black,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: _buildThumbnail(),
                  ),
                ),
                const SizedBox(width: 16),
                // Routine name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        todayRoutine.name,
                        style: GoogleFonts.inter(
                          color: isSkipped ? _kSkipRed : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isSkipped ? 'Bỏ qua buổi tập' : (hasResult ? 'Đã có kết quả buổi tập' : 'Chưa có kết quả buổi tập'),
                        style: GoogleFonts.inter(
                          color: isSkipped ? _kSkipRed : (hasResult ? _kLime : Colors.white54),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showRecordMenu(todayRoutine!, todayHistory),
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildThumbnail() {
    if (widget.plan.imageUrl.isNotEmpty) {
      if (widget.plan.imageUrl.startsWith('assets/')) {
        return Image.asset(widget.plan.imageUrl, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallbackThumbnail());
      }
      return Image.asset(widget.plan.imageUrl, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackThumbnail());
    }
    return _fallbackThumbnail();
  }

  Widget _fallbackThumbnail() {
    return Container(
      color: _kLime.withValues(alpha: 0.3),
      child: const Icon(Icons.fitness_center_rounded, size: 24, color: _kLime),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Menu Tile for Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    this.iconColor = Colors.white,
    this.hasProBadge = false,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Color iconColor;
  final bool hasProBadge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (hasProBadge) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFD9BA8B),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'PRO',
                  style: GoogleFonts.inter(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
