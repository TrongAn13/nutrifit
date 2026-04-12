import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../logic/active_plan_cubit.dart';
import '../../../workout/data/models/workout_history_model.dart';
import '../../../workout/data/models/workout_plan_model.dart';
import '../../../workout/presentation/screens/workout_record_screen.dart';
import '../../../../../shared/Screens/plans/user_plan_detail_screen.dart';

// -----------------------------------------------------------------------------
// Constants
// -----------------------------------------------------------------------------

const Color _kBg = Color(0xFF060708);
const Color _kCardBg = Color(0xFF1B1D22);
const Color _kLime = Color(0xFFD7FF1F);
const Color _kSkipRed = Color(0xFFFF3B30);

// -----------------------------------------------------------------------------
// Workout History Screen
// -----------------------------------------------------------------------------

/// Displays all workout history and plans in two tabs.
class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final ActivePlanCubit _activePlanCubit;
  late Future<List<WorkoutHistoryModel>> _historiesFuture;
  late Future<List<WorkoutPlanModel>> _plansFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _activePlanCubit = ActivePlanCubit.fromContext(context);
    _historiesFuture = _activePlanCubit.getWorkoutHistories();
    _plansFuture = _activePlanCubit.getAllPlans();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _activePlanCubit.close();
    super.dispose();
  }

  void _reloadHistories() {
    setState(() {
      _historiesFuture = _activePlanCubit.getWorkoutHistories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          'History',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _kLime,
          indicatorWeight: 2,
          labelColor: _kLime,
          unselectedLabelColor: Colors.white54,
          labelStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: 'Workout'),
            Tab(text: 'Plan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _WorkoutTab(
            historiesFuture: _historiesFuture,
            onDelete: _reloadHistories,
            onDeleteHistory: _activePlanCubit.deleteWorkoutHistory,
          ),
          _PlanTab(plansFuture: _plansFuture),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Workout Tab
// -----------------------------------------------------------------------------

class _WorkoutTab extends StatelessWidget {
  const _WorkoutTab({
    required this.historiesFuture,
    required this.onDelete,
    required this.onDeleteHistory,
  });

  final Future<List<WorkoutHistoryModel>> historiesFuture;
  final VoidCallback onDelete;
  final Future<void> Function(String historyId) onDeleteHistory;

  String _formatDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    return '${h.toString().padLeft(1, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  static const _kMonthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _formatDate(DateTime date) {
    return '${_kMonthNames[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<WorkoutHistoryModel>>(
      future: historiesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _kLime));
        }

        final histories = snapshot.data ?? [];
        // Filter out skipped workouts (completionPercentage == -1)
        final completed = histories.where((h) => h.completionPercentage >= 0).toList();

        if (completed.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fitness_center_rounded, size: 64, color: Colors.white.withValues(alpha: 0.2)),
                const SizedBox(height: 16),
                Text(
                  'No workout history yet',
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          itemCount: completed.length,
          separatorBuilder: (context, index) => const SizedBox(height: 2),
          itemBuilder: (context, index) {
            final history = completed[index];
            return _WorkoutHistoryTile(
              history: history,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WorkoutRecordScreen(history: history),
                  ),
                );
              },
              onDelete: () async {
                try {
                  await onDeleteHistory(history.id);
                  onDelete();
                } catch (_) {}
              },
              formatDuration: _formatDuration,
              formatDate: _formatDate,
            );
          },
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Workout History Tile
// -----------------------------------------------------------------------------

class _WorkoutHistoryTile extends StatelessWidget {
  const _WorkoutHistoryTile({
    required this.history,
    required this.onTap,
    required this.onDelete,
    required this.formatDuration,
    required this.formatDate,
  });

  final WorkoutHistoryModel history;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final String Function(int) formatDuration;
  final String Function(DateTime) formatDate;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            // Thumbnail: uses plan image if available
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 72,
                height: 72,
                child: Image.asset(
                  'assets/images/back.jfif',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: _kCardBg,
                    child: const Icon(Icons.fitness_center_rounded, color: Colors.white24, size: 28),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
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
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatDate(history.date),
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${formatDuration(history.durationSeconds)} · ${history.caloriesBurned}KCAL',
                    style: GoogleFonts.inter(
                      color: _kLime,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // 3-dot menu
            IconButton(
              onPressed: () => _showOptions(context),
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white54, size: 22),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
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
                  'View Details',
                  style: GoogleFonts.inter(color: Colors.white),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  onTap();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: _kSkipRed),
                title: Text(
                  'Delete Record',
                  style: GoogleFonts.inter(color: _kSkipRed),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  onDelete();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Plan Tab
// -----------------------------------------------------------------------------

class _PlanTab extends StatelessWidget {
  const _PlanTab({required this.plansFuture});

  final Future<List<WorkoutPlanModel>> plansFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<WorkoutPlanModel>>(
      future: plansFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _kLime));
        }

        final plans = snapshot.data ?? [];

        if (plans.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.library_books_rounded, size: 64, color: Colors.white.withValues(alpha: 0.2)),
                const SizedBox(height: 16),
                Text(
                  'No plans yet',
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          itemCount: plans.length,
          separatorBuilder: (context, index) => const SizedBox(height: 2),
          itemBuilder: (context, index) {
            final plan = plans[index];
            return _PlanTile(plan: plan);
          },
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Plan Tile
// -----------------------------------------------------------------------------

class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.plan});

  final WorkoutPlanModel plan;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MyPlanDetailScreen(plan: plan),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 72,
                height: 72,
                child: _buildImage(),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          plan.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (plan.isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _kLime.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Active',
                            style: GoogleFonts.inter(
                              color: _kLime,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${plan.totalWeeks} weeks · ${plan.sessionsPerWeek} days/week',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${plan.level} · ${plan.category}',
                    style: GoogleFonts.inter(
                      color: _kLime.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (plan.imageUrl.isNotEmpty) {
      return Image.asset(
        plan.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      color: _kLime.withValues(alpha: 0.15),
      child: const Icon(Icons.fitness_center_rounded, color: _kLime, size: 28),
    );
  }
}


