import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/workout_plan_model.dart';
import '../../data/repositories/workout_repository.dart';
import '../../logic/workout_bloc.dart';
import '../../logic/workout_event.dart';
import '../../logic/workout_template_bloc.dart';
import '../../logic/workout_template_event.dart';
import '../../logic/workout_template_state.dart';

/// Displays all workout plans the user has created.
///
/// Features: search filtering, shimmer loading, plan cards with badges,
/// and navigation to create new plans.
class WorkoutTemplateListScreen extends StatefulWidget {
  const WorkoutTemplateListScreen({super.key});

  @override
  State<WorkoutTemplateListScreen> createState() =>
      _WorkoutTemplateListScreenState();
}

class _WorkoutTemplateListScreenState extends State<WorkoutTemplateListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<WorkoutTemplateBloc>().add(
      const WorkoutTemplateLoadRequested(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chương trình tập'),
            Text(
              'Quản lý và tạo các chương trình tập luyện.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        toolbarHeight: 64,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Create button + Search ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Create button
                FilledButton.icon(
                  onPressed: () => context.push('/create-plan'),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Tạo template mới'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Search bar
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm mẫu giáo án...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            icon: const Icon(Icons.close_rounded, size: 18),
                          )
                        : null,
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.4,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Plan list ──
          Expanded(
            child: BlocBuilder<WorkoutTemplateBloc, WorkoutTemplateState>(
              builder: (context, state) {
                if (state is WorkoutTemplateLoading ||
                    state is WorkoutTemplateInitial) {
                  return const _ShimmerList();
                }
                if (state is WorkoutTemplateError) {
                  return _ErrorBody(
                    message: state.message,
                    onRetry: () => context.read<WorkoutTemplateBloc>().add(
                      const WorkoutTemplateLoadRequested(),
                    ),
                  );
                }

                final plans = (state as WorkoutTemplateLoaded).plans;

                // Apply local search filter
                final filtered = _searchQuery.isEmpty
                    ? plans
                    : plans
                          .where(
                            (p) => p.name.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ),
                          )
                          .toList();

                if (filtered.isEmpty) {
                  return _EmptyState(hasSearch: _searchQuery.isNotEmpty);
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<WorkoutTemplateBloc>().add(
                      const WorkoutTemplateLoadRequested(),
                    );
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _PlanCard(
                      plan: filtered[index],
                      onDelete: () {
                        context.read<WorkoutTemplateBloc>().add(
                          WorkoutTemplateDeleteRequested(
                            filtered[index].planId,
                          ),
                        );
                      },
                      onApply: () async {
                        final plan = filtered[index];
                        if (plan.isActive) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Giáo án này đang được áp dụng rồi'),
                            ),
                          );
                          return;
                        }
                        try {
                          await WorkoutRepository().setActivePlan(plan.planId);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Đã áp dụng "${plan.name}"'),
                              ),
                            );
                            // Reload the list to update badges
                            context.read<WorkoutTemplateBloc>().add(
                              const WorkoutTemplateLoadRequested(),
                            );
                            // Also refresh WorkoutDashboard data
                            context.read<WorkoutBloc>().add(
                              const WorkoutLoadRequested(),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Lỗi: $e')),
                            );
                          }
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Plan Card
// ─────────────────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final WorkoutPlanModel plan;
  final VoidCallback onDelete;
  final VoidCallback onApply;

  const _PlanCard({
    required this.plan,
    required this.onDelete,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      elevation: 0.5,
      child: InkWell(
        onTap: () => context.push('/plan-detail', extra: plan),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Row 1: Title + More button ──
              Row(
                children: [
                  Expanded(
                    child: Text(
                      plan.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                      size: 20,
                    ),
                    onSelected: (value) {
                      if (value == 'apply') {
                        onApply();
                      } else if (value == 'delete') {
                        _confirmDelete(context);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'apply',
                        enabled: !plan.isActive,
                        child: Row(
                          children: [
                            Icon(
                              plan.isActive
                                  ? Icons.check_circle_rounded
                                  : Icons.play_circle_outline_rounded,
                              size: 18,
                              color: plan.isActive
                                  ? AppColors.success
                                  : Colors.deepOrange,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              plan.isActive ? 'Đang áp dụng' : 'Áp dụng',
                              style: TextStyle(
                                color: plan.isActive
                                    ? AppColors.success
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: AppColors.error,
                            ),
                            SizedBox(width: 8),
                            Text('Xóa giáo án'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── Row 2: Badges ──
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Badge(
                    icon: Icons.calendar_month_outlined,
                    label: '${plan.totalWeeks} tuần',
                  ),
                  _Badge(
                    icon: Icons.fitness_center_rounded,
                    label: '${plan.trainingDays.length} buổi/tuần',
                  ),
                  if (plan.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Đang áp dụng',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),

              // ── Divider + Created date ──
              const SizedBox(height: 12),
              Divider(
                height: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 10),
              Text(
                'Tạo ngày: ${_formatDate(plan.createdAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'thg 1',
      'thg 2',
      'thg 3',
      'thg 4',
      'thg 5',
      'thg 6',
      'thg 7',
      'thg 8',
      'thg 9',
      'thg 10',
      'thg 11',
      'thg 12',
    ];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Xóa giáo án?'),
        content: Text('Bạn có chắc muốn xóa "${plan.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              onDelete();
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Badge Widget
// ─────────────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Badge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.deepOrange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.deepOrange),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.deepOrange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasSearch;

  const _EmptyState({this.hasSearch = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasSearch
                  ? Icons.search_off_rounded
                  : Icons.fitness_center_rounded,
              size: 56,
              color: colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              hasSearch
                  ? 'Không tìm thấy giáo án nào.'
                  : 'Chưa có giáo án nào.\nHãy tạo chương trình tập đầu tiên!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shimmer Loading
// ─────────────────────────────────────────────────────────────────────────────

class _ShimmerList extends StatelessWidget {
  const _ShimmerList();

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final baseColor = isLight ? Colors.grey.shade300 : Colors.grey.shade700;
    final highlightColor = isLight
        ? Colors.grey.shade100
        : Colors.grey.shade600;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        itemCount: 5,
        itemBuilder: (context, index) => Container(
          height: 130,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
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
            const Icon(Icons.error_outline, size: 56, color: AppColors.error),
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
