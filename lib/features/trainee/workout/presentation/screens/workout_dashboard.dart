import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/routes/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../data/models/workout_plan_model.dart';
import '../../data/models/workout_history_model.dart';
import '../../logic/workout_bloc.dart';
import '../../logic/workout_event.dart';
import '../../logic/workout_state.dart';
import '../../logic/active_workout_cubit.dart';
import '../widgets/workout_grid_calendar.dart';
import '../widgets/workout_shimmer_loading.dart';

/// Main Workout tab screen.
/// Displays greeting, plan selector, today's routine, vertical calendar,
/// and personal records.
class WorkoutDashboard extends StatelessWidget {
  const WorkoutDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // Trigger initial data load
    context.read<WorkoutBloc>().add(const WorkoutLoadRequested());

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<WorkoutBloc, WorkoutState>(
          builder: (context, state) {
            if (state is WorkoutLoading || state is WorkoutInitial) {
              return const SingleChildScrollView(
                child: WorkoutShimmerLoading(),
              );
            }

            if (state is WorkoutError) {
              return _ErrorBody(
                message: state.message,
                onRetry: () => context.read<WorkoutBloc>().add(
                  const WorkoutLoadRequested(),
                ),
              );
            }

            final loaded = state as WorkoutLoaded;

            // If no plans at all, show empty state
            if (loaded.allPlans.isEmpty) {
              return const _EmptyState();
            }

            // If plans exist but none is active, show "no active plan" state
            if (loaded.activePlans.isEmpty) {
              return const _NoActivePlanState();
            }

            return _ActiveDashboard(
              allPlans: loaded.allPlans,
              activePlans: loaded.activePlans,
              histories: loaded.histories,
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Illustration circle
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.15),
                    colorScheme.primary.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                Icons.fitness_center_rounded,
                size: 56,
                color: colorScheme.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 32),

            Text(
              'Bạn chưa có chương trình tập nào',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Hãy tạo giáo án đầu tiên để bắt đầu\nhành trình tập luyện của bạn!',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: () async {
                  await context.push('/create-plan');
                  if (context.mounted) {
                    context.read<WorkoutBloc>().add(const WorkoutLoadRequested());
                  }
                },
                icon: const Icon(Icons.add_rounded, size: 24),
                label: const Text('Tạo giáo án ngay'),
                style: FilledButton.styleFrom(
                  textStyle: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// No Active Plan State — plans exist but none is active
// ─────────────────────────────────────────────────────────────────────────────

class _NoActivePlanState extends StatelessWidget {
  const _NoActivePlanState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Icon(
                Icons.add_circle_outline_rounded,
                size: 72,
                color: Colors.deepOrange,
              ),
              const SizedBox(height: 24),

              Text(
                'Bạn chưa áp dụng giáo án nào',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Hãy chọn một giáo án để bắt đầu\nlịch tập luyện hàng tuần!',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: () => context.push('/workout-templates'),
                  icon: const Icon(Icons.library_books_outlined, size: 22),
                  label: const Text('Chọn giáo án ngay'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Active Dashboard — has plans
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveDashboard extends StatefulWidget {
  final List<WorkoutPlanModel> allPlans;
  final List<WorkoutPlanModel> activePlans;
  final List<WorkoutHistoryModel> histories;

  const _ActiveDashboard({
    required this.allPlans,
    required this.activePlans,
    required this.histories,
  });

  @override
  State<_ActiveDashboard> createState() => _ActiveDashboardState();
}

class _ActiveDashboardState extends State<_ActiveDashboard> {
  late WorkoutPlanModel _selectedPlan;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Default to first active plan, or first plan overall
    _selectedPlan = widget.activePlans.isNotEmpty
        ? widget.activePlans.first
        : widget.allPlans.first;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _ActiveDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep selection valid after data reload
    final stillExists = widget.allPlans.any(
      (p) => p.planId == _selectedPlan.planId,
    );
    if (!stillExists) {
      _selectedPlan = widget.activePlans.isNotEmpty
          ? widget.activePlans.first
          : widget.allPlans.first;
    }
  }

  void _showPlanSelector() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) {
        final theme = Theme.of(sheetCtx);
        final colorScheme = theme.colorScheme;

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Chọn giáo án',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...widget.allPlans.map((plan) {
                final isSelected = plan.planId == _selectedPlan.planId;
                return ListTile(
                  onTap: () {
                    setState(() => _selectedPlan = plan);
                    Navigator.pop(sheetCtx);
                  },
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: isSelected
                        ? colorScheme.primary
                        : colorScheme.primaryContainer,
                    child: Icon(
                      isSelected
                          ? Icons.check_rounded
                          : Icons.fitness_center_rounded,
                      size: 18,
                      color: isSelected
                          ? Colors.white
                          : colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text(
                    plan.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    '${plan.totalWeeks} tuần · ${plan.trainingDays.length} buổi/tuần'
                    '${plan.isActive ? ' · Đang hoạt động' : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: colorScheme.primary,
                          size: 22,
                        )
                      : null,
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = FirebaseAuth.instance.currentUser?.displayName ?? 'Bạn';

    return RefreshIndicator(
      onRefresh: () async {
        context.read<WorkoutBloc>().add(const WorkoutLoadRequested());
      },
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Custom Top Bar (Bodify style) ──
          SliverToBoxAdapter(
            child: _BodifyTopBar(),
          ),

          // ── Main Content ──
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Greeting Section ──
                const SizedBox(height: 24),
                _GreetingSection(userName: userName),
                const SizedBox(height: 20),

                // ── Action Row (Plan Selector + Create New) ──
                _ActionRow(
                  selectedPlan: _selectedPlan,
                  onSelectPlan: _showPlanSelector,
                  onCreatePlan: () async {
                    await context.push('/create-plan');
                    if (context.mounted) {
                      context.read<WorkoutBloc>().add(const WorkoutLoadRequested());
                    }
                  },
                ),
                const SizedBox(height: 24),

                // ── Today's Workout Card ──
                _TodayWorkoutCard(
                  plan: _selectedPlan,
                  histories: widget.histories,
                ),
                const SizedBox(height: 24),

                // ── Grid Calendar ──
                WorkoutGridCalendar(
                  plan: _selectedPlan,
                  histories: widget.histories,
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bodify Custom Top Bar
// ─────────────────────────────────────────────────────────────────────────────

class _BodifyTopBar extends StatelessWidget {
  const _BodifyTopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // App Logo
          const Text(
            'NUTRIFIT',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
              fontSize: 24,
              letterSpacing: 1.2,
            ),
          ),
          // Icon buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  // TODO: Navigate to chat/messages
                },
                icon: Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.grey.shade700,
                ),
              ),
              IconButton(
                onPressed: () {
                  context.push(AppRouter.notifications);
                },
                icon: Icon(
                  Icons.notifications_none,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Greeting Section (Bodify style)
// ─────────────────────────────────────────────────────────────────────────────

class _GreetingSection extends StatelessWidget {
  final String userName;

  const _GreetingSection({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Xin chào, $userName!',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A1C29),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Hãy cùng nhau tập luyện nào.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action Row (Plan Selector + Create New button)
// ─────────────────────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  final WorkoutPlanModel selectedPlan;
  final VoidCallback onSelectPlan;
  final VoidCallback onCreatePlan;

  const _ActionRow({
    required this.selectedPlan,
    required this.onSelectPlan,
    required this.onCreatePlan,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Plan Selector (left side)
        Expanded(
          child: GestureDetector(
            onTap: onSelectPlan,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFDECE8),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      'Chương trình tập: ${selectedPlan.name}',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.redAccent,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Create New button (right side)
        GestureDetector(
          onTap: onCreatePlan,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF03613),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Text(
              '+ Tạo mới',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}



// ─────────────────────────────────────────────────────────────────────────────
// Today's Workout Card
// ─────────────────────────────────────────────────────────────────────────────

class _TodayWorkoutCard extends StatelessWidget {
  final WorkoutPlanModel plan;
  final List<WorkoutHistoryModel> histories;

  const _TodayWorkoutCard({
    required this.plan,
    required this.histories,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final todayDow = DateTime.now().weekday;
    final now = DateTime.now();

    // Find today's routine
    final todayRoutine = plan.routines
        .where((r) => r.dayOfWeek == todayDow)
        .toList();

    // If no routine today, show rest day
    if (todayRoutine.isEmpty) {
      return _RestDayCard(theme: theme, colorScheme: colorScheme);
    }

    final routine = todayRoutine.first;

    // Check if today's workout is already completed
    final todayHistory = histories.where((h) =>
        h.date.year == now.year &&
        h.date.month == now.month &&
        h.date.day == now.day &&
        h.routineName == routine.name,
    ).toList();
    final isCompletedToday = todayHistory.isNotEmpty;
    final completionPct = isCompletedToday
        ? todayHistory.first.completionPercentage.round()
        : 0;

    // Light styled card (Bodify style - no heavy shadow)
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: isCompletedToday
            ? null
            : () {
                context.read<ActiveWorkoutCubit>().loadRoutine(
                  routine,
                  planId: plan.planId,
                );
                context.push('/active-workout');
              },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isCompletedToday
                          ? Colors.teal.withValues(alpha: 0.15)
                          : AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCompletedToday) ...[
                          const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.teal,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          isCompletedToday
                              ? 'Đã hoàn thành'
                              : 'Buổi tập hôm nay',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: isCompletedToday
                                ? Colors.teal
                                : AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${routine.exercises.length} bài tập',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Routine name
              Text(
                routine.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              // Completion percentage (only when completed)
              if (isCompletedToday) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.emoji_events_rounded,
                        color: Colors.teal,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Bạn đã hoàn thành $completionPct% bài tập',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.teal.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when there is no routine scheduled for today.
class _RestDayCard extends StatelessWidget {
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _RestDayCard({required this.theme, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text(
              'Ngày nghỉ ngơi 🧘',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Hôm nay không có buổi tập nào.\nHãy nghỉ ngơi và phục hồi!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error Body
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
