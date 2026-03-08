import 'package:flutter/material.dart';

import '../../data/models/exercise_model.dart';

/// Full detail screen for a single [ExerciseModel].
///
/// Shows placeholder image, muscle/equipment tags, and step-by-step
/// instructions. Opened from [ExerciseLibraryScreen] on item tap.
class ExerciseDetailScreen extends StatelessWidget {
  final ExerciseModel exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  /// Splits [instructions] string into ordered steps by '.' or '\n'.
  List<String> _parseSteps(String raw) {
    if (raw.trim().isEmpty) return [];
    // Split on newlines first, then on '.'
    final parts = raw
        .split(RegExp(r'\n|(?<=\.)\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s != '.')
        .toList();
    return parts;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final steps = _parseSteps(exercise.instructions);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          exercise.name,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Đóng',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          // ── Placeholder Image ──
          Container(
            height: 250,
            color: Colors.grey.shade100,
            child: Center(
              child: Icon(
                Icons.fitness_center,
                size: 80,
                color: Colors.grey.shade300,
              ),
            ),
          ),
          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Tags Section ──
                _TagSection(exercise: exercise),
                const SizedBox(height: 28),

                // ── Instructions Section ──
                Text(
                  'Hướng dẫn thực hiện',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),

                if (steps.isEmpty)
                  Text(
                    'Chưa có hướng dẫn cho bài tập này.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  )
                else
                  ...steps.asMap().entries.map(
                    (e) => _StepItem(stepNumber: e.key + 1, text: e.value),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tag Section  (Nhóm cơ chính, nhóm cơ phụ, dụng cụ, bộ phận)
// ─────────────────────────────────────────────────────────────────────────────

class _TagSection extends StatelessWidget {
  final ExerciseModel exercise;

  const _TagSection({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // NHÓM CƠ CHÍNH
        if (exercise.primaryMuscle.isNotEmpty) ...[
          _sectionLabel('NHÓM CƠ CHÍNH', theme),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _Tag(
                label: exercise.primaryMuscle,
                icon: Icons.favorite_rounded,
                backgroundColor: Colors.red.shade50,
                textColor: Colors.red.shade700,
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],

        // NHÓM CƠ PHỤ
        if (exercise.secondaryMuscles.isNotEmpty) ...[
          _sectionLabel('NHÓM CƠ PHỤ', theme),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: exercise.secondaryMuscles
                .map(
                  (m) => _Tag(
                    label: m,
                    icon: Icons.spa_rounded,
                    backgroundColor: Colors.orange.shade50,
                    textColor: Colors.deepOrange.shade600,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
        ],

        // DỤNG CỤ + BỘ PHẬN (side by side)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (exercise.equipment.isNotEmpty)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('DỤNG CỤ', theme),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _Tag(
                          label: exercise.equipment,
                          icon: Icons.fitness_center_rounded,
                          backgroundColor: Colors.grey.shade100,
                          textColor: Colors.grey.shade800,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            if (exercise.equipment.isNotEmpty && exercise.bodyPart.isNotEmpty)
              const SizedBox(width: 16),
            if (exercise.bodyPart.isNotEmpty)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('BỘ PHẬN', theme),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _Tag(
                          label: exercise.bodyPart,
                          icon: Icons.person_rounded,
                          backgroundColor: Colors.blue.shade50,
                          textColor: Colors.blue.shade800,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

Widget _sectionLabel(String text, ThemeData theme) => Text(
  text,
  style: theme.textTheme.labelSmall?.copyWith(
    color: Colors.grey,
    letterSpacing: 0.8,
    fontWeight: FontWeight.w600,
  ),
);

// ─────────────────────────────────────────────────────────────────────────────
// Tag Chip
// ─────────────────────────────────────────────────────────────────────────────

class _Tag extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;

  const _Tag({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step Item
// ─────────────────────────────────────────────────────────────────────────────

class _StepItem extends StatelessWidget {
  final int stepNumber;
  final String text;

  const _StepItem({required this.stepNumber, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.deepOrange.withValues(alpha: 0.12),
            child: Text(
              '$stepNumber',
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.deepOrange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
