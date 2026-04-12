import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../../core/routes/app_router.dart';
import '../../../../../shared/widgets/static_gif_thumbnail.dart';
import '../../data/models/workout_history_model.dart';
import '../../data/models/routine_model.dart';
import '../../logic/workout_result_cubit.dart';
import '../widgets/workout_volume_progress_bar.dart';

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
  const WorkoutResultScreen({
    super.key,
    required this.history,
    this.onClose,
    this.showSaveButton = true,
    this.showBackButton = false,
  });

  @override
  State<WorkoutResultScreen> createState() => _WorkoutResultScreenState();
}

class _WorkoutResultScreenState extends State<WorkoutResultScreen>
    with SingleTickerProviderStateMixin {
  /// Effort slider value: 0.0 (No Effort) to 1.0 (Max Effort).
  double _effortValue = 0.5;

  late final WorkoutResultCubit _resultCubit;
  late final AnimationController _confettiController;
  final List<_ConfettiParticle> _confettiParticles = [];
  bool _showConfetti = true;

  WorkoutHistoryModel get history => widget.history;

  @override
  void initState() {
    super.initState();
    _resultCubit = WorkoutResultCubit.fromContext(
      context: context,
      history: widget.history,
    )..loadAssets();

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _showConfetti = false);
        }
      });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_confettiParticles.isEmpty) {
        final size = MediaQuery.of(context).size;
        _confettiParticles.addAll(_generateConfettiParticles(size));
      }
      if (mounted) {
        _confettiController.forward();
      }
    });
  }

  @override
  void dispose() {
    _resultCubit.close();
    _confettiController.dispose();
    super.dispose();
  }

  List<_ConfettiParticle> _generateConfettiParticles(Size canvasSize) {
    final random = math.Random();
    final burstOrigin = Offset(
      canvasSize.width / 2,
      math.min(220, canvasSize.height * 0.30),
    );
    final palette = [
      _kLime,
      const Color(0xFFFFB703),
      const Color(0xFF5CE1E6),
      const Color(0xFFFF5D8F),
      Colors.white,
    ];

    return List.generate(72, (_) {
      final angle = (-math.pi / 2) + (random.nextDouble() - 0.5) * 1.9;
      final speed = 130 + random.nextDouble() * 150;
      final velocity = Offset(
        math.cos(angle) * speed,
        math.sin(angle) * speed,
      );

      return _ConfettiParticle(
        origin: burstOrigin,
        velocity: velocity,
        size: 3.5 + random.nextDouble() * 4.5,
        color: palette[random.nextInt(palette.length)],
        rotation: random.nextDouble() * math.pi * 2,
        rotationSpeed: (random.nextDouble() - 0.5) * 5,
        isCircle: random.nextBool(),
      );
    });
  }

  Widget _buildFullScreenConfettiBurst(Size canvasSize) {
    if (!_showConfetti) {
      return const SizedBox.shrink();
    }

    if (_confettiParticles.isEmpty) {
      _confettiParticles.addAll(_generateConfettiParticles(canvasSize));
    }

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _confettiController,
        builder: (context, _) {
          return RepaintBoundary(
            child: CustomPaint(
              size: canvasSize,
              isComplex: false,
              willChange: true,
              painter: _ConfettiPainter(
                progress: Curves.easeOutCubic.transform(_confettiController.value),
                particles: _confettiParticles,
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GIF Widgets
  // ─────────────────────────────────────────────────────────────────────────

  /// Builds a static GIF thumbnail for an exercise detail card.
  Widget _buildExerciseGif(
    String exerciseName,
    double size,
    Map<String, String> exerciseGifs,
  ) {
    final gifUrl = exerciseGifs[exerciseName];

    if (gifUrl != null && gifUrl.isNotEmpty) {
      return StaticGifThumbnail(
        url: gifUrl,
        size: size,
        errorIcon: Icons.fitness_center_rounded,
        errorIconColor: Colors.white.withValues(alpha: 0.3),
        errorIconSize: size * 0.45,
      );
    }

    return Icon(
      Icons.fitness_center_rounded,
      color: Colors.white.withValues(alpha: 0.3),
      size: size * 0.45,
    );
  }

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
  List<_ExerciseVolumeData> _computeVolumeData(WorkoutHistoryModel workoutHistory) {
    final List<_ExerciseVolumeData> result = [];
    double grandTotal = 0;

    for (final ex in workoutHistory.exercises) {
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
    return BlocBuilder<WorkoutResultCubit, WorkoutResultState>(
      bloc: _resultCubit,
      builder: (context, resultState) {
        final currentHistory = resultState.history;
        final volumeData = _computeVolumeData(currentHistory);

        // Compute insights
        int totalSets = 0;
        final int totalReps = currentHistory.totalReps;
        double heaviestLift = 0;
        String heaviestExercise = '';
        int heaviestExerciseReps = 0;

        for (final ex in currentHistory.exercises) {
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
          body: LayoutBuilder(
            builder: (context, constraints) {
              final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);

              return Stack(
                children: [
                  CustomScrollView(
                    slivers: [
                      // ── Section 1: Summary Header ──
                      SliverToBoxAdapter(
                        child: _buildSummaryHeader(
                          context,
                          resultState.summaryImageUrl,
                        ),
                      ),

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
                        child: _buildWorkoutDetails(resultState.exerciseGifs),
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
                  Positioned.fill(
                    child: _buildFullScreenConfettiBurst(canvasSize),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Section 1: Summary Header
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSummaryHeader(BuildContext context, String? summaryImageUrl) {
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
            child: SizedBox(
              height: 40,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (widget.showBackButton)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  Text(
                    dateStr,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Workout plan card visual (with confetti) ──
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Plan card
                Container(
                  width: 140,
                  height: 180,
                  decoration: BoxDecoration(
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildSummaryCardImage(summaryImageUrl),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.15),
                                Colors.black.withValues(alpha: 0.55),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 6,
                  child: Container(
                    width: 108,
                    height: 5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(
                        colors: [
                          _kLime.withValues(alpha: 0.0),
                          _kLime.withValues(alpha: 0.95),
                          _kLime.withValues(alpha: 0.0),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _kLime.withValues(alpha: 0.6),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
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
            ],
          ),

          const SizedBox(height: 4),

          // ── Date and time ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${DateFormat('MMMM dd, yyyy').format(history.date)} • $startTimeStr - ',
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
              ),

              Text(
                endTimeStr,
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),

          const SizedBox(height: 16),

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

  Widget _buildSummaryCardImage(String? imageUrl) {

    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('assets/')) {
        return Image.asset(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildSummaryFallbackVisual(),
        );
      }

      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildSummaryFallbackVisual(),
      );
    }

    return _buildSummaryFallbackVisual();
  }

  Widget _buildSummaryFallbackVisual() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A3A3A), Color(0xFF1E1E1E)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.fitness_center_rounded,
          color: _kLime.withValues(alpha: 0.5),
          size: 32,
        ),
      ),
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

  Widget _buildWorkoutDetails(Map<String, String> exerciseGifs) {
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
            ],
          ),
          const SizedBox(height: 12),

          // Exercise detail cards
          ...history.exercises.map(
            (ex) => _buildExerciseDetailCard(ex, exerciseGifs),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseDetailCard(
    ExerciseEntry exercise,
    Map<String, String> exerciseGifs,
  ) {
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
              // Exercise thumbnail with GIF
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildExerciseGif(
                  exercise.exerciseName,
                  56,
                  exerciseGifs,
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
              context.go(AppRouter.main);
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

class _ConfettiParticle {
  final Offset origin;
  final Offset velocity;
  final double size;
  final Color color;
  final double rotation;
  final double rotationSpeed;
  final bool isCircle;

  const _ConfettiParticle({
    required this.origin,
    required this.velocity,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
    required this.isCircle,
  });
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_ConfettiParticle> particles;

  const _ConfettiPainter({
    required this.progress,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.clamp(0.0, 1.0);
    final fadeOut = (1 - t).clamp(0.0, 1.0);
    final fadeIn = (t / 0.14).clamp(0.0, 1.0);
    final fade = fadeOut * fadeIn;

    for (final p in particles) {
      final x = p.origin.dx + (p.velocity.dx * t);
      final y = p.origin.dy + (p.velocity.dy * t) + (560 * t * t);

      if (x < -20 || x > size.width + 20 || y < -20 || y > size.height + 40) {
        continue;
      }

      final paint = Paint()
        ..color = p.color.withValues(alpha: fade);

      if (p.isCircle) {
        canvas.drawCircle(Offset(x, y), p.size * 0.42, paint);
      } else {
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: p.size, height: p.size * 0.58),
          const Radius.circular(1.4),
        );
        canvas.drawRRect(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.particles != particles;
  }
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
          child: WorkoutVolumeProgressBar(
            value: barWidth,
            fillColor: _kLime,
            backgroundColor: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ],
    );
  }
}
