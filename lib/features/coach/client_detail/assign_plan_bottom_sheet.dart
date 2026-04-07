import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../trainee/workout/data/models/workout_plan_model.dart';
import '../data/plan_assignment_repository.dart';

/// Bottom sheet for a coach to pick a workout plan and assign it to a client.
///
/// Shows two tabs:
/// - **Tab 1**: Workout plans created by the coach.
/// - **Tab 2**: Nutrition plans (placeholder — coming soon).
class AssignPlanBottomSheet extends StatelessWidget {
  final String clientId;
  final String clientName;

  const AssignPlanBottomSheet({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // ── Handle ──
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // ── Title ──
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.assignment_outlined,
                        color: Colors.deepOrange, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Giao giáo án cho $clientName',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Tab Bar ──
              TabBar(
                labelColor: Colors.deepOrange,
                unselectedLabelColor: Colors.grey.shade500,
                indicatorColor: Colors.deepOrange,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(text: 'Giáo án Tập luyện'),
                  Tab(text: 'Thực đơn Dinh dưỡng'),
                ],
              ),

              // ── Tab Content ──
              Expanded(
                child: TabBarView(
                  children: [
                    _WorkoutPlanTab(
                      clientId: clientId,
                      scrollController: scrollController,
                    ),
                    _NutritionPlaceholderTab(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Workout Plan Tab
// ─────────────────────────────────────────────────────────────────────────────

class _WorkoutPlanTab extends StatefulWidget {
  final String clientId;
  final ScrollController scrollController;

  const _WorkoutPlanTab({
    required this.clientId,
    required this.scrollController,
  });

  @override
  State<_WorkoutPlanTab> createState() => _WorkoutPlanTabState();
}

class _WorkoutPlanTabState extends State<_WorkoutPlanTab> {
  final _repo = PlanAssignmentRepository();
  late final Future<List<WorkoutPlanModel>> _plansFuture;
  bool _assigning = false;

  @override
  void initState() {
    super.initState();
    final coachId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _plansFuture = _repo.getCoachPlans(coachId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<WorkoutPlanModel>>(
      future: _plansFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Lỗi: ${snapshot.error}',
              style: TextStyle(color: Colors.red.shade400),
            ),
          );
        }

        final plans = snapshot.data ?? [];
        if (plans.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 56, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Bạn chưa tạo giáo án nào.\nHãy tạo giáo án trong mục "Giáo án" trước nhé!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          controller: widget.scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: plans.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final plan = plans[index];
            return _PlanItemCard(
              plan: plan,
              isAssigning: _assigning,
              onAssign: () => _assignPlan(plan),
            );
          },
        );
      },
    );
  }

  Future<void> _assignPlan(WorkoutPlanModel plan) async {
    if (_assigning) return;
    setState(() => _assigning = true);

    try {
      final coachId = FirebaseAuth.instance.currentUser?.uid ?? '';
      await _repo.assignPlanToClient(
        coachId: coachId,
        clientId: widget.clientId,
        templatePlan: plan,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close bottom sheet
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Đã giao giáo án "${plan.name}" thành công!'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green.shade600,
            ),
          );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Giao giáo án thất bại: $e'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red.shade600,
            ),
          );
      }
    } finally {
      if (mounted) setState(() => _assigning = false);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Plan Item Card
// ─────────────────────────────────────────────────────────────────────────────

class _PlanItemCard extends StatelessWidget {
  final WorkoutPlanModel plan;
  final bool isAssigning;
  final VoidCallback onAssign;

  const _PlanItemCard({
    required this.plan,
    required this.isAssigning,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plan name + weeks
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.fitness_center_rounded,
                    size: 22, color: Colors.blue.shade600),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${plan.totalWeeks} tuần • ${plan.sessionsPerWeek} buổi/tuần',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Description
          if (plan.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              plan.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Routines summary
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: plan.routines.take(4).map((r) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  r.name,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          // Assign button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isAssigning ? null : onAssign,
              icon: isAssigning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(isAssigning ? 'Đang giao...' : 'Giao cho học viên'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nutrition Placeholder Tab
// ─────────────────────────────────────────────────────────────────────────────

class _NutritionPlaceholderTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_rounded,
                size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Tính năng đang phát triển',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Chức năng giao thực đơn dinh dưỡng\nsẽ sớm ra mắt trong bản cập nhật tiếp theo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
