import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/workout_history_model.dart';
import '../../data/repositories/workout_repository.dart';

/// Displays the result summary of a completed workout session.
///
/// Shows stats, exercise breakdown, and action buttons (share / delete).
class WorkoutResultScreen extends StatelessWidget {
  final WorkoutHistoryModel history;

  const WorkoutResultScreen({super.key, required this.history});

  String _formatDuration(int totalSeconds) {
    if (totalSeconds == 0) return "00:00";
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      final hStr = hours.toString().padLeft(2, '0');
      return "$hStr:$mStr:$sStr";
    }
    return "$mStr:$sStr";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          },
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fitness_center, color: Colors.teal),
            SizedBox(width: 8),
            Text(
              'Nutrifit',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.black),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đang chuẩn bị ảnh chia sẻ...'),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            const Text(
              'Kết quả tập luyện',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd MMMM yyyy, HH:mm').format(history.date),
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),

            // ── Main Info Card ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ngày ${history.date.weekday} trong tuần',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          history.routineName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: history.completionPercentage / 100,
                          strokeWidth: 6,
                          backgroundColor: Colors.grey.shade200,
                          color: Colors.redAccent,
                        ),
                        Center(
                          child: Text(
                            '${history.completionPercentage.round()}%',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Motivation Text ──
            Text(
              "Bạn đã quyết định cạnh tranh với chính mình. Chỉ trong trường hợp này, bạn mới trở nên tốt hơn ngày hôm qua!",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // ── Duration & Rest Time Grid ──
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Thời gian tập',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatDuration(history.durationSeconds),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Thời gian nghỉ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatDuration(history.restTimeSeconds),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Icon Stats Row ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _IconStat(
                  icon: Icons.local_fire_department,
                  value: '${history.caloriesBurned} kcal',
                  color: Colors.orange,
                ),
                _IconStat(
                  icon: Icons.fitness_center,
                  value: '${history.totalWeightLifted.toStringAsFixed(1)} kg',
                  color: Colors.blue,
                ),
                _IconStat(
                  icon: Icons.repeat,
                  value: '${history.totalReps} reps',
                  color: Colors.red,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ── Detail Stats ──
            _DetailItem(
              title: 'Số hiệp đã tập',
              subtitle: '${history.totalReps} tổng cộng',
              progress: history.completionPercentage / 100,
            ),
            _DetailItem(
              title: 'Tổng tạ nâng',
              subtitle:
                  '${history.totalWeightLifted.toStringAsFixed(1)} kg',
              progress: 1.0,
            ),
            _DetailItem(
              title: 'Thời lượng',
              subtitle: '${history.durationSeconds}s',
              progress: 1.0,
            ),

            const SizedBox(height: 32),

            // ── Exercise Breakdown Header ──
            const Text(
              'Chi tiết bài tập',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // ── Exercise Breakdown List ──
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.exercises.length,
              itemBuilder: (context, index) {
                final exercise = history.exercises[index];

                // Mock performance delta
                final mockDeltas = [-57, 15, -12, 30, -5, 22, 8, -3];
                final delta = mockDeltas[index % mockDeltas.length];
                final isPositive = delta >= 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Leading: exercise icon placeholder
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.fitness_center_rounded,
                          color: Colors.teal.shade400,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Title & subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exercise.exerciseName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Hiệp: ${exercise.sets}  Tạ: ${exercise.weight?.toStringAsFixed(0) ?? "0"} kg',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.teal.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Trailing: performance indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isPositive
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isPositive ? '+$delta% ↑' : '$delta% ↓',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isPositive
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // ── SHARE SUMMARY Button ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đang chuẩn bị ảnh chia sẻ...'),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'SHARE SUMMARY',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Delete Button ──
            Center(
              child: TextButton(
                onPressed: () => _showDeleteDialog(context),
                child: Text(
                  'Delete workout result',
                  style: TextStyle(
                    color: Colors.teal.shade600,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Shows confirmation dialog before deleting the workout history.
  void _showDeleteDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa kết quả?'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa kết quả buổi tập này không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop(); // Dismiss dialog

              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) =>
                    const Center(child: CircularProgressIndicator()),
              );

              try {
                await WorkoutRepository()
                    .deleteWorkoutHistory(history.id);
              } catch (e) {
                // Ignore failure for UI
              }

              if (context.mounted) {
                Navigator.of(context).pop(); // Dismiss loading
                Navigator.of(context).pop(true); // Pop result screen, signal deletion
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private Widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Circular icon + value stat widget.
class _IconStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _IconStat({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }
}

/// Progress circle + title/subtitle detail row.
class _DetailItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final double progress;

  const _DetailItem({
    required this.title,
    required this.subtitle,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 4,
              backgroundColor: Colors.grey.shade200,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style:
                      TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
