import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../logic/active_plan_cubit.dart';
import '../../../workout/data/models/workout_history_model.dart';
import '../../../workout/data/models/workout_plan_model.dart';
import '../../../workout/data/repositories/workout_repository.dart';
import '../../../workout/presentation/screens/workout_record_screen.dart';
import '../../../workout/presentation/screens/workout_ready_screen.dart';
import '../../../../../core/routes/app_router.dart';
import '../../../../../shared/Screens/plans/user_plan_detail_screen.dart' show MyPlanDetailScreen;
import 'trainee_schedule_screen.dart';

class TraineeDashboardScreen extends StatefulWidget {
  const TraineeDashboardScreen({super.key});

  static const Color _backgroundColor = Color(0xFF060708);
  static const Color _cardColor = Color(0xFF1B1D22);
  static const Color _limeColor = Color(0xFFD7FF1F);

  @override
  State<TraineeDashboardScreen> createState() => _TraineeDashboardScreenState();
}

class _TraineeDashboardScreenState extends State<TraineeDashboardScreen>
    with WidgetsBindingObserver {
  late final ActivePlanCubit _activePlanCubit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _activePlanCubit = ActivePlanCubit(
      workoutRepository: WorkoutRepository(),
    )..loadActivePlan();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _activePlanCubit.close();
    super.dispose();
  }

  /// Reload active plan when the app comes back to foreground.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _activePlanCubit.loadActivePlan();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reload every time build is called (e.g. switching back to this tab)
    _activePlanCubit.loadActivePlan();

    return BlocProvider.value(
      value: _activePlanCubit,
      child: Scaffold(
        backgroundColor: TraineeDashboardScreen._backgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _DashboardHeader(),
                const SizedBox(height: 20),
                const _TodayWorkoutCard(),
                const SizedBox(height: 24),
                _SectionHeader(
                  title: 'My Schedule',
                  actionLabel: 'Show All',
                  onTap: () => context.push(AppRouter.traineeSchedule),
                ),
                const SizedBox(height: 12),
                const _ScheduleCard(),
                const SizedBox(height: 24),
                const _SectionHeader(title: 'Following Plans', actionLabel: 'Show All'),
                const SizedBox(height: 12),
                const _FollowingPlansCard(),
                const SizedBox(height: 24),
                _SectionHeader(
                  title: 'History',
                  actionLabel: 'Show All',
                  onTap: () => context.push(AppRouter.workoutHistory),
                ),
                const SizedBox(height: 12),
                const _HistoryCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper to get time-based greeting
// ─────────────────────────────────────────────────────────────────────────────

String _getGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good Morning!';
  if (hour < 18) return 'Good Afternoon!';
  return 'Good Evening!';
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    final displayName =
        FirebaseAuth.instance.currentUser?.displayName?.trim().isNotEmpty == true
            ? FirebaseAuth.instance.currentUser!.displayName!.trim()
            : 'Trainee';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
              ),
              Text(
                displayName,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HeaderIconButton(
                  icon: PhosphorIcons.bell(),
                  onPressed: () {},
                ),
                const SizedBox(width: 4),
                _HeaderIconButton(
                  icon: PhosphorIcons.chatCircle(),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 8),
            const _WeekStatusStrip(),
          ],
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 24),
      constraints: const BoxConstraints(
        minWidth: 28,
        minHeight: 28,
      ),
      padding: EdgeInsets.zero,
    );
  }
}

class _WeekStatusStrip extends StatelessWidget {
  const _WeekStatusStrip();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActivePlanCubit, ActivePlanState>(
      builder: (context, state) {
        final plan = state.plan;
        final todayWeekday = DateTime.now().weekday; // 1=Mon ... 7=Sun
        const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const MyScheduleScreen(),
              ),
            );
          },
          child: FutureBuilder<List<WorkoutHistoryModel>>(
            future: WorkoutRepository().getWorkoutHistories(),
            builder: (context, snapshot) {
              final histories = snapshot.data ?? [];
              final now = DateTime.now();
              final monday = now.subtract(Duration(days: now.weekday - 1));

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(7, (i) {
                  final dayNum = i + 1;
                  final isToday = dayNum == todayWeekday;
                  final dayDate = monday.add(Duration(days: i));
                  final isCompleted = histories.any((h) =>
                    h.date.year == dayDate.year &&
                    h.date.month == dayDate.month &&
                    h.date.day == dayDate.day &&
                    h.completionPercentage != -1.0
                  );

                  Color bgColor;
                  Color borderColor;
                  Widget child;

                  if (isCompleted) {
                    // Completed day: green bg + tick
                    bgColor = TraineeDashboardScreen._limeColor;
                    borderColor = TraineeDashboardScreen._limeColor;
                    child = const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.black,
                    );
                  } else if (isToday) {
                    // Today (not completed): transparent bg + green border + label
                    bgColor = Colors.transparent;
                    borderColor = TraineeDashboardScreen._limeColor;
                    child = Text(
                      labels[i],
                      style: GoogleFonts.inter(
                        fontSize: 7,
                        color: TraineeDashboardScreen._limeColor,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  } else {
                    // Normal rest day / uncompleted day: transparent bg, subtle white border
                    bgColor = Colors.transparent;
                    borderColor = Colors.white.withValues(alpha: 0.2);
                    child = Text(
                      labels[i],
                      style: GoogleFonts.inter(
                        fontSize: 7,
                        color: Colors.white.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.only(left: 3),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor, width: 1),
                      ),
                      child: Center(child: child),
                    ),
                  );
                }),
              );
            },
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Today Workout Card — Dynamic from ActivePlanCubit
// ─────────────────────────────────────────────────────────────────────────────

class _TodayWorkoutCard extends StatelessWidget {
  const _TodayWorkoutCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActivePlanCubit, ActivePlanState>(
      builder: (context, state) {
        if (state.isLoading) {
          return Container(
            height: 420,
            decoration: BoxDecoration(
              color: TraineeDashboardScreen._cardColor,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final plan = state.plan;
        final todayRoutine = state.todayRoutine;
        final isRestDay = state.isRestDay;

        // Plan name & today's routine name
        final planName = plan?.name ?? 'No Active Plan';
        final routineName = todayRoutine?.name ?? (isRestDay ? 'REST DAY' : 'No workout');
        final exerciseCount = todayRoutine?.exercises.length ?? 0;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: TraineeDashboardScreen._limeColor.withValues(alpha: 0.16),
                blurRadius: 80,
                spreadRadius: 8,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 420,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image: plan image or fallback
                  _buildBackground(plan),

                  // Dark gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.58),
                          Colors.black.withValues(alpha: 0.72),
                          Colors.black.withValues(alpha: 0.86),
                        ],
                      ),
                    ),
                  ),

                  // FOR TODAY badge
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.9),
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(18),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isRestDay ? Icons.hotel_rounded : Icons.adjust_rounded,
                            size: 18,
                            color: TraineeDashboardScreen._limeColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'FOR TODAY',
                            style: GoogleFonts.inter(
                              color: TraineeDashboardScreen._limeColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom section
                  Positioned(
                    left: 22,
                    right: 22,
                    bottom: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          planName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 19,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          routineName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: isRestDay
                                ? Colors.white.withValues(alpha: 0.6)
                                : const Color(0xFFE7A627),
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (exerciseCount > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            '$exerciseCount exercises',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: plan == null || isRestDay || todayRoutine == null
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => WorkoutReadyScreen(
                                        routine: todayRoutine!,
                                        planId: plan!.planId,
                                      ),
                                    ),
                                  );
                                },
                          icon: Icon(
                            isRestDay
                                ? Icons.self_improvement_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.black,
                            size: 24,
                          ),
                          label: Text(
                            isRestDay ? 'Rest and Recover' : 'Start Workout',
                            style: GoogleFonts.inter(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            backgroundColor: isRestDay
                                ? Colors.white.withValues(alpha: 0.5)
                                : TraineeDashboardScreen._limeColor,
                            disabledBackgroundColor:
                                Colors.white.withValues(alpha: 0.3),
                            disabledForegroundColor: Colors.black54,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build background image from plan's imageUrl or a fallback asset.
  Widget _buildBackground(WorkoutPlanModel? plan) {
    if (plan != null && plan.imageUrl.isNotEmpty) {
      if (plan.imageUrl.startsWith('assets/')) {
        return Image.asset(
          plan.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Image.asset(
            'assets/images/back.jfif',
            fit: BoxFit.cover,
          ),
        );
      }
      return Image.asset(
        plan.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/images/back.jfif',
          fit: BoxFit.cover,
        ),
      );
    }
    return Image.asset(
      'assets/images/back.jfif',
      fit: BoxFit.cover,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    this.onTap,
  });

  final String title;
  final String actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            actionLabel,
            style: GoogleFonts.inter(
              color: TraineeDashboardScreen._limeColor,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Schedule Card
// ─────────────────────────────────────────────────────────────────────────────

class _ScheduleCard extends StatefulWidget {
  const _ScheduleCard();

  @override
  State<_ScheduleCard> createState() => _ScheduleCardState();
}

class _ScheduleCardState extends State<_ScheduleCard> {
  late final WorkoutRepository _repo;
  late Future<List<WorkoutHistoryModel>> _historiesFuture;

  @override
  void initState() {
    super.initState();
    _repo = WorkoutRepository();
    _historiesFuture = _repo.getWorkoutHistories();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActivePlanCubit, ActivePlanState>(
      builder: (context, state) {
        final plan = state.plan;

        return FutureBuilder<List<WorkoutHistoryModel>>(
          future: _historiesFuture,
          builder: (context, snapshot) {
            final histories = snapshot.data ?? [];

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 16, 10, 14),
              decoration: BoxDecoration(
                color: TraineeDashboardScreen._cardColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date range + Legend row
                  _buildHeaderRow(),
                  const SizedBox(height: 14),
                  // Calendar + Consistency
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _DynamicCalendarGrid(
                          plan: plan,
                          histories: histories,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _DynamicConsistency(
                        plan: plan,
                        histories: histories,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Divider(color: Colors.white.withValues(alpha: 0.12), height: 1),
                  const SizedBox(height: 14),
                  const _SchedulePlanTile(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeaderRow() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final endDate = monday.add(const Duration(days: 27));

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateRange = '${months[monday.month - 1]} ${monday.day} - ${months[endDate.month - 1]} ${endDate.day}';

    return Row(
      children: [
        Text(
          dateRange,
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        const Wrap(
          spacing: 12,
          children: [
            _LegendItem(color: TraineeDashboardScreen._limeColor, label: 'Finish'),
            _LegendItem(color: Colors.white, label: 'Scheduled'),
            _LegendItem(color: Color(0xFFFF4B45), label: 'Skip'),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dynamic Calendar Grid
// ─────────────────────────────────────────────────────────────────────────────

class _DynamicCalendarGrid extends StatelessWidget {
  const _DynamicCalendarGrid({required this.plan, required this.histories});

  final WorkoutPlanModel? plan;
  final List<WorkoutHistoryModel> histories;

  static const List<String> _weekLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: now.weekday - 1));
    final days = List.generate(28, (i) => monday.add(Duration(days: i)));
    final todayWeekdayIndex = now.weekday - 1;

    return Column(
      children: [
        // Week headers row — all centered within their 1/7 slot
        Row(
          children: List.generate(7, (i) {
            final isHighlighted = i == todayWeekdayIndex;
            return Expanded(
              child: Center(
                child: Text(
                  _weekLabels[i],
                  style: GoogleFonts.inter(
                    color: isHighlighted
                        ? TraineeDashboardScreen._limeColor
                        : Colors.white.withValues(alpha: 0.55),
                    fontSize: 13,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        // Day cells - 4 rows of 7 centered slots
        Column(
          children: List.generate(4, (rowIndex) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: List.generate(7, (colIndex) {
                  final dayIndex = rowIndex * 7 + colIndex;
                  final date = days[dayIndex];

                  final history = histories.where((h) =>
                    h.date.year == date.year &&
                    h.date.month == date.month &&
                    h.date.day == date.day &&
                    h.completionPercentage != -1.0
                  ).firstOrNull;

                  final skipHistory = histories.where((h) =>
                    h.date.year == date.year &&
                    h.date.month == date.month &&
                    h.date.day == date.day &&
                    h.completionPercentage == -1.0
                  ).firstOrNull;

                  final isCompleted = history != null;
                  final isSkipped = skipHistory != null;
                  final isToday = date == today;
                  final isScheduled = plan?.trainingDays.contains(date.weekday) ?? false;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0.5),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: _DynamicDayCell(
                          day: date.day,
                          width: double.infinity,
                          isToday: isToday,
                          isCompleted: isCompleted,
                          isSkipped: isSkipped,
                          isScheduled: isScheduled,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dynamic Day Cell
// ─────────────────────────────────────────────────────────────────────────────

class _DynamicDayCell extends StatelessWidget {
  const _DynamicDayCell({
    required this.day,
    required this.width,
    required this.isToday,
    required this.isCompleted,
    required this.isSkipped,
    required this.isScheduled,
  });

  final int day;
  final double width;
  final bool isToday;
  final bool isCompleted;
  final bool isSkipped;
  final bool isScheduled;

  @override
  Widget build(BuildContext context) {
    Color textColor = Colors.white;
    Color? fillColor;
    Border? border;

    if (isSkipped) {
      // Red fill for skipped
      fillColor = const Color(0xFF6B2625);
      textColor = const Color(0xFFFF5F57);
    } else if (isCompleted && isToday) {
      // Green fill + green border for today completed
      fillColor = const Color(0xFF2D3908);
      textColor = TraineeDashboardScreen._limeColor;
      border = Border.all(color: TraineeDashboardScreen._limeColor, width: 1.2);
    } else if (isCompleted) {
      // Green fill for completed
      fillColor = const Color(0xFF55670D);
      textColor = TraineeDashboardScreen._limeColor;
    } else if (isToday) {
      // Green border only for today (no fill color)
      textColor = TraineeDashboardScreen._limeColor;
      border = Border.all(color: TraineeDashboardScreen._limeColor, width: 1.2);
    }

    return SizedBox(
      width: width,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Square day cell
          Container(
            width: width,
            height: width,
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(8),
              border: border,
            ),
            alignment: Alignment.center,
            child: Text(
              day.toString(),
              style: GoogleFonts.inter(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          // Dot at the top right corner
          if (isScheduled)
            Positioned(
              top: 3,
              right: 3,
              child: Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dynamic Consistency Summary
// ─────────────────────────────────────────────────────────────────────────────

class _DynamicConsistency extends StatelessWidget {
  const _DynamicConsistency({required this.plan, required this.histories});

  final WorkoutPlanModel? plan;
  final List<WorkoutHistoryModel> histories;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final fourWeeksAgo = today.subtract(const Duration(days: 28));

    final completedInRange = histories.where((h) =>
      h.completionPercentage >= 0 &&
      h.date.isAfter(fourWeeksAgo) &&
      !h.date.isAfter(today)
    ).length;

    int scheduledCount = 0;
    if (plan != null) {
      for (int i = 0; i < 28; i++) {
        final d = fourWeeksAgo.add(Duration(days: i + 1));
        if (plan!.trainingDays.contains(d.weekday)) {
          scheduledCount++;
        }
      }
    }

    final consistency = scheduledCount > 0 ? completedInRange / scheduledCount : 0.0;
    final consistencyPercent = (consistency * 100).round();

    // Active days = days since plan was activated
    int activeDays = 0;
    if (plan != null) {
      activeDays = today.difference(DateTime(
        plan!.createdAt.year, plan!.createdAt.month, plan!.createdAt.day,
      )).inDays;
      if (activeDays < 0) activeDays = 0;
    }

    return SizedBox(
      width: 76,
      child: Column(
        children: [
          Text(
            'Last 4 wks',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          // Semicircle gauge
          SizedBox(
            width: 64,
            height: 40,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CustomPaint(
                  size: const Size(64, 40),
                  painter: _SemiCircleGaugePainter(
                    progress: consistency,
                    trackColor: Colors.white.withValues(alpha: 0.2),
                    progressColor: TraineeDashboardScreen._limeColor,
                    strokeWidth: 5,
                  ),
                ),
                // Info icon top-right
                Positioned(
                  right: -4,
                  top: -2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
                    ),
                    child: Icon(
                      Icons.info_outline_rounded,
                      color: Colors.white.withValues(alpha: 0.6),
                      size: 8,
                    ),
                  ),
                ),
                // Percentage text
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Center(
                    child: Text(
                      '$consistencyPercent%',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFF9A227),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Consistency',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '$activeDays',
            style: GoogleFonts.inter(
              color: TraineeDashboardScreen._limeColor,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            'active days',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for a semicircle gauge (bottom half open).
class _SemiCircleGaugePainter extends CustomPainter {
  _SemiCircleGaugePainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - strokeWidth / 2;

    // Track arc (semicircle from left to right, sweeping 180 degrees)
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi, // start at left
      math.pi, // sweep 180 degrees (semicircle)
      false,
      trackPaint,
    );

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        math.pi,
        math.pi * progress.clamp(0.0, 1.0),
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SemiCircleGaugePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated Play Button
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedPlayButton extends StatefulWidget {
  const _AnimatedPlayButton();

  @override
  State<_AnimatedPlayButton> createState() => _AnimatedPlayButtonState();
}

class _AnimatedPlayButtonState extends State<_AnimatedPlayButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated outer halo
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_controller.value * 0.1),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12 + (_controller.value * 0.08)),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
          // Inner solid white circle
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.play_arrow_rounded,
                color: Colors.black,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Schedule Plan Tile
// ─────────────────────────────────────────────────────────────────────────────

class _SchedulePlanTile extends StatelessWidget {
  const _SchedulePlanTile();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActivePlanCubit, ActivePlanState>(
      builder: (context, state) {
        final plan = state.plan;
        final todayRoutine = state.todayRoutine;

        final displayTitle = plan != null && todayRoutine != null
            ? todayRoutine.name
            : plan != null
                ? plan.name
                : 'No active plan';

        final displaySubtitle = plan?.description ?? 'Add a workout plan to get started.';

        return Row(
          children: [
            const _AnimatedPlayButton(),
            const SizedBox(width: 8),
            SizedBox(
              width: 56,
              height: 56,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: plan != null && plan.imageUrl.isNotEmpty
                    ? Image.asset(
                        plan.imageUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/images/back.jfif',
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        'assets/images/back.jfif',
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displaySubtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.52),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}



// ─────────────────────────────────────────────────────────────────────────────
// Following Plans Card
// ─────────────────────────────────────────────────────────────────────────────

class _FollowingPlansCard extends StatelessWidget {
  const _FollowingPlansCard();

  int _countCompletedSessions(WorkoutPlanModel plan, List<WorkoutHistoryModel> histories) {
    final matched = histories.where((h) => h.planId == plan.planId).length;
    final total = plan.totalWeeks * plan.sessionsPerWeek;
    if (total <= 0) return 0;
    return matched > total ? total : matched;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActivePlanCubit, ActivePlanState>(
      builder: (context, state) {
        final plan = state.plan;

        if (plan == null) {
          return Container(
            decoration: BoxDecoration(
              color: TraineeDashboardScreen._cardColor,
              borderRadius: BorderRadius.circular(22),
            ),
            padding: const EdgeInsets.all(16),
            child: Text(
              'Apply a plan to track your progress',
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
          );
        }

        return FutureBuilder<List<WorkoutHistoryModel>>(
          future: WorkoutRepository().getWorkoutHistories(),
          builder: (context, snapshot) {
            final histories = snapshot.data ?? const <WorkoutHistoryModel>[];
            final totalSessions = plan.totalWeeks * plan.sessionsPerWeek;
            final completedSessions = _countCompletedSessions(plan, histories);
            final progress = totalSessions > 0 ? (completedSessions / totalSessions).clamp(0.0, 1.0) : 0.0;
            final progressPercent = (progress * 100).round();

            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MyPlanDetailScreen(plan: plan),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: TraineeDashboardScreen._cardColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                child: Row(
                  children: [
                    SizedBox(
                      width: 83,
                      height: 130,
                      child: plan.imageUrl.isNotEmpty
                          ? Image.asset(
                              plan.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Image.asset(
                                'assets/images/default_plan.jpg',
                                fit: BoxFit.cover,
                              ),
                            )
                          : Image.asset(
                              'assets/images/default_plan.jpg',
                              fit: BoxFit.cover,
                            ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              plan.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: [
                                _MetaChip(label: '${plan.totalWeeks} weeks'),
                                _MetaChip(label: '${plan.sessionsPerWeek} workout/week'),
                                _MetaChip(label: plan.equipment),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Progress: $progressPercent%',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                minHeight: 5,
                                value: progress,
                                backgroundColor: Colors.white.withValues(alpha: 0.5),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  TraineeDashboardScreen._limeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF4A451D),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: const Color(0xFFF4CB43),
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// History Card
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  const _HistoryCard();

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dayStr = date.day.toString().padLeft(2, '0');
    return '${months[date.month - 1]} $dayStr, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActivePlanCubit, ActivePlanState>(
      builder: (context, state) {
        return FutureBuilder<List<WorkoutHistoryModel>>(
          future: WorkoutRepository().getWorkoutHistories(),
          builder: (context, snapshot) {
            final histories = snapshot.data ?? const <WorkoutHistoryModel>[];
            if (histories.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TraineeDashboardScreen._cardColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: state.plan != null && state.plan!.imageUrl.isNotEmpty
                          ? Image.asset(
                              state.plan!.imageUrl,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Image.asset(
                                'assets/images/back.jfif',
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Image.asset(
                              'assets/images/back.jfif',
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No workout history yet',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Complete a workout to see history',
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            final recent = histories.take(3).toList();
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TraineeDashboardScreen._cardColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: recent.map((history) {
                  // Estimate kcal: roughly 8 kcal per minute of exercise
                  final estimatedKcal = ((history.durationSeconds / 60) * 8).round();

                  final bool isCurrentPlan = state.plan != null && history.planId == state.plan!.planId;
                  final String imageUrl = isCurrentPlan ? state.plan!.imageUrl : '';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => WorkoutRecordScreen(history: history),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: imageUrl.isNotEmpty
                                ? Image.asset(
                                    imageUrl,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Image.asset(
                                      'assets/images/back.jfif',
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Image.asset(
                                    'assets/images/back.jfif',
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  history.routineName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_formatDuration(history.durationSeconds)} time • $estimatedKcal kcal',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    color: TraineeDashboardScreen._limeColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _formatDate(history.date),
                            style: GoogleFonts.inter(
                              color: Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }
}
