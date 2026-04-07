import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

const Color _kPrimary = Color(0xFF6B4EFF);
const Color _kPrimaryLight = Color(0xFFEDE9FF);

/// Workout tab content for [ClientDetailScreen].
///
/// Displays the active training plan card, a weekly calendar,
/// and today's exercise list with status indicators.
class WorkoutTab extends StatelessWidget {
  final String clientId;

  const WorkoutTab({super.key, required this.clientId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildActivePlanCard(),
        const SizedBox(height: 16),
        _buildWeeklyCalendar(),
        const SizedBox(height: 16),
        _buildTodayExercises(),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 1. Active Plan Card
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildActivePlanCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2FC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _kPrimary.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.fitness_center_rounded,
                  color: _kPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tăng cơ siêu tốc',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Tuần 3 / 8 tuần',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _kPrimary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'ĐANG CHẠY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: 3 / 8,
              backgroundColor: Colors.white,
              valueColor: const AlwaysStoppedAnimation<Color>(_kPrimary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '37.5% hoàn thành',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. Weekly Calendar Card
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildWeeklyCalendar() {
    // Mock data — active day is Wednesday (index 2)
    const activeIndex = 2;
    const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    const dates = [16, 17, 18, 19, 20, 21, 22];
    // Days that have workouts scheduled (mock icons)
    const workoutDays = {2, 4}; // Wed, Fri

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with month + navigation
          Row(
            children: [
              const Text(
                'Tháng 10, 2023',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              _calNavBtn(Icons.chevron_left),
              const SizedBox(width: 4),
              _calNavBtn(Icons.chevron_right),
            ],
          ),
          const SizedBox(height: 14),

          // Day row
          Row(
            children: List.generate(7, (i) {
              final isActive = i == activeIndex;
              return Expanded(
                child: Column(
                  children: [
                    Text(
                      days[i],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isActive ? _kPrimary : Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isActive ? _kPrimary : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${dates[i]}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isActive ? Colors.white : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (workoutDays.contains(i))
                      Icon(
                        Icons.fitness_center,
                        size: 10,
                        color: isActive ? _kPrimary : Colors.grey.shade400,
                      )
                    else
                      const SizedBox(height: 10),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _calNavBtn(IconData icon) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Icon(icon, size: 16, color: Colors.grey.shade600),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. Today's Exercises
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildTodayExercises() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row
        Row(
          children: [
            const Text(
              'Bài tập hôm nay',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _kPrimaryLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'STRENGTH DAY',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: _kPrimary,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Exercise cards
        _ExerciseCard(
          icon: Icons.fitness_center,
          name: 'Squat',
          detail: '4 sets × 8 reps • 80kg',
          isDone: true,
          hasPR: true,
        ),
        const SizedBox(height: 10),
        _ExerciseCard(
          icon: Icons.timer_outlined,
          name: 'Push-up',
          detail: '3 sets × 15 reps',
          isDone: true,
          hasPR: false,
        ),
        const SizedBox(height: 10),
        _ExerciseCard(
          icon: Icons.fitness_center,
          name: 'Deadlift',
          detail: '4 sets × 6 reps • 100kg',
          isDone: false,
          hasPR: false,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Exercise Card
// ─────────────────────────────────────────────────────────────────────────────

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.icon,
    required this.name,
    required this.detail,
    required this.isDone,
    required this.hasPR,
  });

  final IconData icon;
  final String name;
  final String detail;
  final bool isDone;
  final bool hasPR;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon circle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: Colors.grey.shade600),
              ),
              const SizedBox(width: 14),
              // Name + detail
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      detail,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              // Done check
              if (isDone)
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.green.shade600,
                  ),
                ),
            ],
          ),
        ),
        // PR badge
        if (hasPR)
          Positioned(
            top: -4,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _kPrimary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'PR',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
