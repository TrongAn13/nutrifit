import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../data/models/workout_history_model.dart';
import '../../data/models/routine_model.dart';
import '../../data/repositories/workout_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

const Color _kBg = Color(0xFF000000);
const Color _kLime = Color(0xFFD7FF1F);
const Color _kCardBg = Color(0xFF1C1C1E);
const Color _kCardBgLight = Color(0xFF2C2C2E);

/// Displays the result summary of a completed workout session.
///
/// Dark-themed design with sections: Summary, Insights, Volume, Details.
class WorkoutResultScreen extends StatefulWidget {
  final WorkoutHistoryModel history;
  final VoidCallback? onClose;
  final bool showSaveButton;
  final bool showBackButton;
  final IconData topRightIcon;

  const WorkoutResultScreen({
    super.key,
    required this.history,
    this.onClose,
    this.showSaveButton = true,
    this.showBackButton = false,
    this.topRightIcon = Icons.more_horiz_rounded,
  });

  @override
  State<WorkoutResultScreen> createState() => _WorkoutResultScreenState();
}

class _WorkoutResultScreenState extends State<WorkoutResultScreen> {
  /// Effort slider value: 0.0 (No Effort) to 1.0 (Max Effort).
  double _effortValue = 0.5;

  WorkoutHistoryModel get history => widget.history;

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return '${hours.toString()}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatRestTime(int seconds) {
    if (seconds >= 60) {
      final m = seconds ~/ 60;
      final s = seconds % 60;
      return s > 0 ? '${m}m' : '${m}m';
    }
    return '${seconds}s';
  }

  /// Compute per-exercise volume data for the insights and volume sections.
  List<_ExerciseVolumeData> _computeVolumeData() {
    final List<_ExerciseVolumeData> result = [];
    double grandTotal = 0;

    for (final ex in history.exercises) {
      final volume = (ex.weight ?? 0) * ex.reps * ex.sets;
      grandTotal += volume;
      result.add(_ExerciseVolumeData(
        exercise: ex,
        totalVolume: volume,
        maxWeight: ex.weight ?? 0,
      ));
    }

    // Sort by volume descending
    result.sort((a, b) => b.totalVolume.compareTo(a.totalVolume));

    // Compute percentage
    for (final item in result) {
      item.percentage = grandTotal > 0 ? (item.totalVolume / grandTotal * 100) : 0;
    }

    return result;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final volumeData = _computeVolumeData();

    // Compute insights
    int totalSets = 0;
    final int totalReps = history.totalReps;
    double heaviestLift = 0;
    String heaviestExercise = '';
    int heaviestExerciseReps = 0;

    for (final ex in history.exercises) {
      totalSets += ex.sets;
      final w = ex.weight ?? 0;
      if (w > heaviestLift) {
        heaviestLift = w;
        heaviestExercise = ex.exerciseName;
        heaviestExerciseReps = ex.reps;
      }
    }

    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          // ── Section 1: Summary Header ──
          SliverToBoxAdapter(child: _buildSummaryHeader(context)),

          // ── Section 2: Workout Insights ──
          SliverToBoxAdapter(
            child: _buildInsightsCard(
              totalSets: totalSets,
              totalReps: totalReps,
              heaviestLift: heaviestLift,
              heaviestExercise: heaviestExercise,
              highestVolumeSetWeight: heaviestLift,
              highestVolumeSetReps: heaviestExerciseReps,
              highestVolumeExercise: heaviestExercise,
            ),
          ),

          // ── Section 3: Volume by Exercise ──
          SliverToBoxAdapter(
            child: _buildVolumeCard(volumeData),
          ),

          // ── Section 4: Workout Details ──
          SliverToBoxAdapter(
            child: _buildWorkoutDetails(),
          ),

          if (widget.showSaveButton)
            SliverToBoxAdapter(
              child: _buildSaveButton(context),
            ),

          // Bottom spacing
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Section 1: Summary Header
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSummaryHeader(BuildContext context) {
    final dateStr = DateFormat('MMMM dd, yyyy').format(history.date);
    final startTimeStr = DateFormat('HH:mm').format(history.date);
    final endTime = history.date.add(Duration(seconds: history.durationSeconds));
    final endTimeStr = DateFormat('HH:mm').format(endTime);

    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8),
      child: Column(
        children: [
          // ── Top bar: Date + menu ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.showBackButton)
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  )
                else
                  const SizedBox(width: 40),
                Text(
                  dateStr,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: () => _showOptionsMenu(context),
                  child: Icon(widget.topRightIcon, color: Colors.white, size: 24),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Workout plan card visual (with confetti) ──
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Confetti particles
                ..._buildConfettiParticles(),
                // Plan card
                Container(
                  width: 140,
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF3A3A3A), Color(0xFF1E1E1E)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kLime.withValues(alpha: 0.3), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: _kLime.withValues(alpha: 0.1),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fitness_center_rounded, color: _kLime.withValues(alpha: 0.5), size: 32),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            history.routineName,
                            style: GoogleFonts.inter(
                              color: _kLime,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Add your photo button ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _kCardBgLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_photo_alternate_outlined, color: Colors.white.withValues(alpha: 0.7), size: 18),
                const SizedBox(width: 6),
                Text(
                  'Add your photo',
                  style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Routine name with edit icon ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                history.routineName,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.edit_rounded, color: _kLime, size: 16),
            ],
          ),

          const SizedBox(height: 4),

          // ── Date and time ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${DateFormat('MMMM dd, yyyy').format(history.date)} • $startTimeStr',
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
              ),
              Text(
                ' ★',
                style: GoogleFonts.inter(color: _kLime, fontSize: 13),
              ),
              Text(
                endTimeStr,
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(width: 4),
              Icon(Icons.edit_rounded, color: _kLime, size: 12),
            ],
          ),

          const SizedBox(height: 16),

          // ── Week status strip ──
          _buildWeekStrip(),

          const SizedBox(height: 20),

          // ── Stats grid ──
          _buildStatsGrid(),

          const SizedBox(height: 20),

          // ── Effort slider ──
          _buildEffortSlider(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  List<Widget> _buildConfettiParticles() {
    final random = Random(42); // Fixed seed for deterministic layout
    final colors = [
      _kLime,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.cyan,
    ];

    return List.generate(20, (i) {
      final left = random.nextDouble() * 300 + 20;
      final top = random.nextDouble() * 180;
      final color = colors[random.nextInt(colors.length)];
      final size = random.nextDouble() * 8 + 4;
      final isCircle = random.nextBool();

      return Positioned(
        left: left,
        top: top,
        child: Transform.rotate(
          angle: random.nextDouble() * pi * 2,
          child: Container(
            width: size,
            height: isCircle ? size : size * 0.4,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(isCircle ? size : 1),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildWeekStrip() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final today = history.date.weekday; // 1=Mon, 7=Sun

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(7, (i) {
        final dayNum = i + 1;
        final isToday = dayNum == today;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            children: [
              if (isToday)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _kLime,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.black, size: 20),
                )
              else
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 1.5),
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                days[i],
                style: GoogleFonts.inter(
                  color: isToday ? _kLime : Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatGridItem(
                    label: 'Duration',
                    value: _formatDuration(history.durationSeconds),
                    valueColor: _kLime,
                  ),
                ),
                Expanded(
                  child: _StatGridItem(
                    label: 'Est. Kilocalories',
                    value: '${history.caloriesBurned}',
                    unit: 'KCAL',
                    valueColor: _kLime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatGridItem(
                    label: 'Volume',
                    value: '${history.totalWeightLifted.toStringAsFixed(0)}',
                    unit: 'kg',
                    valueColor: _kLime,
                  ),
                ),
                Expanded(
                  child: _StatGridItem(
                    label: 'Number of Exercises',
                    value: '${history.exercises.length}',
                    valueColor: _kLime,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEffortSlider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bolt_rounded, color: _kLime, size: 18),
                const SizedBox(width: 4),
                Text(
                  'How do you feel about the workout?',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Gradient slider
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 8,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                thumbColor: Colors.white,
                overlayColor: Colors.white.withValues(alpha: 0.1),
                activeTrackColor: Colors.transparent,
                inactiveTrackColor: Colors.transparent,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Gradient track
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF2196F3), // Blue
                          Color(0xFF4CAF50), // Green
                          Color(0xFFFFEB3B), // Yellow
                          Color(0xFFFF9800), // Orange
                          Color(0xFFF44336), // Red
                        ],
                      ),
                    ),
                  ),
                  Slider(
                    value: _effortValue,
                    onChanged: (v) => setState(() => _effortValue = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('No Effort', style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
                Text('Easy', style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
                Text('Ideal', style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
                Text('Hard', style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
                Text('Max Effort', style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Section 2: Workout Insights
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildInsightsCard({
    required int totalSets,
    required int totalReps,
    required double heaviestLift,
    required String heaviestExercise,
    required double highestVolumeSetWeight,
    required int highestVolumeSetReps,
    required String highestVolumeExercise,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _kCardBgLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: _kLime, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  'Workout Insights',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Insight rows
            _InsightRow(
              badgeText: '$totalSets\nsets',
              title: 'Sets Completed',
              subtitle: 'You knocked out $totalSets sets during this session.',
            ),
            const SizedBox(height: 16),
            _InsightRow(
              badgeText: '$totalReps\nreps',
              title: 'Total Reps',
              subtitle: 'Good workout volume for building strength.',
            ),
            const SizedBox(height: 16),
            _InsightRow(
              badgeText: '${highestVolumeSetWeight.toStringAsFixed(0)} kg\n×$highestVolumeSetReps',
              title: 'Highest Volume Set',
              subtitle: highestVolumeExercise,
            ),
            const SizedBox(height: 16),
            _InsightRow(
              badgeText: '${heaviestLift.toStringAsFixed(1)}\nkg',
              title: 'Heaviest Lift',
              subtitle: heaviestExercise,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Section 3: Volume by Exercise
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildVolumeCard(List<_ExerciseVolumeData> volumeData) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _kCardBgLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.trending_up_rounded, color: _kLime, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  'Volume by exercise',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Exercise volume items
            ...List.generate(volumeData.length, (i) {
              final data = volumeData[i];
              return Padding(
                padding: EdgeInsets.only(bottom: i < volumeData.length - 1 ? 20 : 0),
                child: _VolumeExerciseRow(
                  rank: i + 1,
                  data: data,
                  maxPercentage: volumeData.isNotEmpty ? volumeData.first.percentage : 100,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Section 4: Workout Details
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildWorkoutDetails() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Workout Details',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(Icons.edit_rounded, color: _kLime, size: 20),
            ],
          ),
          const SizedBox(height: 12),

          // Exercise detail cards
          ...history.exercises.map((ex) => _buildExerciseDetailCard(ex)),
        ],
      ),
    );
  }

  Widget _buildExerciseDetailCard(ExerciseEntry exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise header with image
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Exercise thumbnail
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.fitness_center_rounded,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.exerciseName,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exercise.primaryMuscle.isNotEmpty
                          ? exercise.primaryMuscle
                          : 'Target muscle group',
                      style: GoogleFonts.inter(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Set rows
          ...List.generate(exercise.sets, (setIndex) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  // Check icon
                  const Icon(Icons.check_circle_rounded, color: _kLime, size: 18),
                  const SizedBox(width: 8),
                  // Set number or lightning icon
                  if (setIndex == 0)
                    Icon(Icons.bolt_rounded, color: Colors.amber, size: 16)
                  else
                    SizedBox(
                      width: 16,
                      child: Text(
                        '${setIndex}',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(width: 8),
                  // Set details
                  Expanded(
                    child: Text(
                      '${exercise.weight?.toStringAsFixed(0) ?? '0'} kg • '
                      '${exercise.reps} reps • '
                      'Rest ${_formatRestTime(exercise.restTime)}',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 4),
          // Session badge
          Text(
            '🏆 Session',
            style: GoogleFonts.inter(
              color: Colors.amber,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Save Button
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSaveButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          onPressed: () {
            widget.onClose?.call();
            if (context.mounted) {
              context.pop(true);
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: _kLime,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
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
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Options menu
  // ─────────────────────────────────────────────────────────────────────────

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
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
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.share_rounded, color: Colors.white70),
              title: Text('Share Results', style: GoogleFonts.inter(color: Colors.white)),
              onTap: () {
                Navigator.of(ctx).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              title: Text('Delete Workout', style: GoogleFonts.inter(color: Colors.redAccent)),
              onTap: () {
                Navigator.of(ctx).pop();
                _showDeleteDialog(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kCardBg,
        title: Text(
          'Delete Workout?',
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete this workout result?',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator(color: _kLime)),
              );
              try {
                await WorkoutRepository().deleteWorkoutHistory(history.id);
              } catch (e) {
                // Ignore failure
              }
              if (context.mounted) {
                Navigator.of(context).pop(); // Dismiss loading
                widget.onClose?.call();
                context.pop(true);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data class for volume computation
// ─────────────────────────────────────────────────────────────────────────────

class _ExerciseVolumeData {
  final ExerciseEntry exercise;
  final double totalVolume;
  final double maxWeight;
  double percentage;

  _ExerciseVolumeData({
    required this.exercise,
    required this.totalVolume,
    required this.maxWeight,
    this.percentage = 0,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Private Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StatGridItem extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final Color valueColor;

  const _StatGridItem({
    required this.label,
    required this.value,
    this.unit,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                color: valueColor,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (unit != null) ...[
              Text(
                unit!,
                style: GoogleFonts.inter(
                  color: valueColor.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Insight row with lime badge, title, and subtitle.
class _InsightRow extends StatelessWidget {
  final String badgeText;
  final String title;
  final String subtitle;

  const _InsightRow({
    required this.badgeText,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Badge
        Container(
          width: 64,
          height: 52,
          decoration: BoxDecoration(
            color: _kLime.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kLime.withValues(alpha: 0.3), width: 1),
          ),
          child: Center(
            child: Text(
              badgeText,
              style: GoogleFonts.inter(
                color: _kLime,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(width: 14),
        // Title + subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  color: Colors.white38,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Volume row for a single exercise.
class _VolumeExerciseRow extends StatelessWidget {
  final int rank;
  final _ExerciseVolumeData data;
  final double maxPercentage;

  const _VolumeExerciseRow({
    required this.rank,
    required this.data,
    required this.maxPercentage,
  });

  @override
  Widget build(BuildContext context) {
    final ex = data.exercise;
    final barWidth = maxPercentage > 0 ? data.percentage / maxPercentage : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rank circle
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _kLime.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: GoogleFonts.inter(
                    color: _kLime,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Exercise info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ex.exerciseName,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.layers_rounded, color: Colors.white38, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${ex.sets} x ${ex.reps}',
                        style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.bar_chart_rounded, color: Colors.white38, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${data.totalVolume.toStringAsFixed(0)} kg',
                        style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.arrow_upward_rounded, color: Colors.white38, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${data.maxWeight.toStringAsFixed(1)} kg',
                        style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Percentage badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _kLime.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${data.percentage.round()}%',
                style: GoogleFonts.inter(
                  color: _kLime,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Volume progress bar
        Padding(
          padding: const EdgeInsets.only(left: 40),
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: barWidth.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: _kLime,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
