import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../features/trainee/workout/data/models/exercise_model.dart';
import 'exercise_favorite_store.dart';
import '../../widgets/static_gif_thumbnail.dart';



// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

const Color _kBg = Color(0xFF060708);
const Color _kPurple = Color(0xFF7B61FF);
const Color _kPurpleLight = Color(0xFFEDE8FF);
const Color _kWarningRed = Color(0xFFFF0000);
const Color _kReadMore = Color(0xFFD7FF1F);

/// Detail screen for a single exercise within the coach library.
///
/// Displays a video/image block, exercise header, descriptions,
/// step-by-step instructions (vertical stepper), and a warning section.
/// Now accepts an [ExerciseModel] for real Firebase data.
class ExerciseDetailScreen extends StatefulWidget {
  final ExerciseModel exercise;
  final String groupName;

  const ExerciseDetailScreen({
    super.key,
    required this.exercise,
    required this.groupName,
  });

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  bool _isDescriptionExpanded = false;

  String get _previewImageUrl {
    if (widget.exercise.gifUrl.trim().isNotEmpty) {
      return widget.exercise.gifUrl.trim();
    }
    if (widget.exercise.imageUrl.isNotEmpty) {
      return widget.exercise.imageUrl;
    }
    return '';
  }

  String get _playableGifUrl {
    return widget.exercise.gifUrl.trim();
  }

  /// Parse instructions text into step list.
  /// Each line becomes a step. If instructions is empty, return empty list.
  List<_StepData> get _steps {
    final raw = widget.exercise.instructions.trim();
    if (raw.isEmpty) return [];

    final lines = raw.split('\n').where((l) => l.trim().isNotEmpty).toList();
    return lines.asMap().entries.map((entry) {
      return _StepData(
        title: 'Step ${entry.key + 1}',
        description: entry.value.trim(),
      );
    }).toList();
  }

  /// Build subtitle from primaryMuscle, secondaryMuscles, equipment.
  String get _subtitle {
    final parts = <String>[];

    // Thêm chữ "Cơ chính:" trước Primary Muscle
    if (widget.exercise.primaryMuscle.isNotEmpty) {
      parts.add('Primary Muscles: ${widget.exercise.primaryMuscle}');
    }

    String result = parts.join(' • ');

    // Thêm "Cơ phụ:" và xử lý xuống dòng
    if (widget.exercise.secondaryMuscles.isNotEmpty) {
      result += '\nSecondary Muscles: ${widget.exercise.secondaryMuscles.join(', ')}';
    }

    // Thêm "Dụng cụ:" và xử lý xuống dòng
    if (widget.exercise.equipment.isNotEmpty) {
      result += '\nEquipment: ${widget.exercise.equipment}';
    }

    return result.isEmpty ? 'No information' : result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Video / Image Block ──
            _buildVideoBlock(),
            const SizedBox(height: 24),

            // ── Exercise Header ──
            _buildExerciseHeader(),
            const SizedBox(height: 24),

            // ── Descriptions ──
            if (widget.exercise.description.isNotEmpty) ...[
              _buildDescriptions(),
              const SizedBox(height: 28),
            ],

            // ── How To Do It ──
            if (_steps.isNotEmpty) ...[
              _buildHowToDoIt(),
              const SizedBox(height: 28),
            ],

            // ── Warning ──
            if (widget.exercise.warning.isNotEmpty) _buildWarning(),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AppBar
  // ═══════════════════════════════════════════════════════════════════════════

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: _kBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(
              Icons.arrow_back_ios_new,
              size: 16,
              color: Colors.white,
          ),
        ),
      ),
      title: Text(
        widget.groupName,
        style: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ValueListenableBuilder<Set<String>>(
            valueListenable: ExerciseFavoriteStore.favorites,
            builder: (context, favorites, _) {
              final isFavorite = favorites.contains(widget.exercise.exerciseId);
              return IconButton(
                onPressed: () {
                  setState(() {
                    ExerciseFavoriteStore.toggle(widget.exercise.exerciseId);
                  });
                },
                icon: Icon(
                  isFavorite ? Icons.star : Icons.star_border,
                  color: isFavorite ? const Color(0xFFF6B100) : Colors.white,
                  size: 22,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Video / Image Block
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildVideoBlock() {
    final previewUrl = _previewImageUrl;
    final hasPlayableGif = _playableGifUrl.isNotEmpty;

    return SizedBox(
      height: 220,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (previewUrl.isEmpty)
            _buildGradientPlaceholder()
          else
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.grey.shade200,
              ),
              clipBehavior: Clip.antiAlias,
              child: hasPlayableGif
                  ? StaticGifThumbnail(
                      url: _playableGifUrl,
                      width: double.infinity,
                      height: double.infinity,
                      errorIcon: Icons.fitness_center_rounded,
                      errorIconColor: Colors.white54,
                      errorIconSize: 42,
                    )
                  : previewUrl.startsWith('http')
                      ? Image.network(
                          previewUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildGradientPlaceholder(),
                        )
                      : Image.asset(
                          previewUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildGradientPlaceholder(),
                        ),
            ),
          Center(
            child: GestureDetector(
              onTap: () => _onPlayPressed(hasPlayableGif),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: _kPurple.withAlpha(50),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: hasPlayableGif ? _kPurple : Colors.grey,
                  size: 36,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onPlayPressed(bool hasPlayableGif) {
    if (!hasPlayableGif) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bai tap nay chua co GIF minh hoa')),
      );
      return;
    }

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withAlpha(230),
      builder: (_) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 3,
                    child: Center(
                      child: Image.network(
                        _playableGifUrl,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGradientPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8E7CFF),
            Color(0xFFB5A8FF),
            Color(0xFF6C4FE0),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(20),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Exercise Header
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildExerciseHeader() {
    final levelText = widget.exercise.level.isNotEmpty
        ? widget.exercise.level
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.exercise.name,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          // Show level + muscle info instead of calories
          [
            if (levelText != null) 'Level: $levelText',
            _subtitle,
          ].join(' | '),
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Descriptions
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDescriptions() {
    final desc = widget.exercise.description;
    final displayText = _isDescriptionExpanded
        ? desc
        : desc.substring(0, min(180, desc.length));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        RichText(
          text: TextSpan(
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade500,
              height: 1.6,
            ),
            children: [
              TextSpan(text: displayText),
              if (!_isDescriptionExpanded && desc.length > 180)
                const TextSpan(text: '... '),
            ],
          ),
        ),
        if (desc.length > 180)
          GestureDetector(
            onTap: () =>
                setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _isDescriptionExpanded ? 'Thu gọn' : 'Xem thêm...',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kReadMore,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // How To Do It — Vertical Stepper
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHowToDoIt() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'How To Do It',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              '${_steps.length} Steps',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Steps
        Column(
          children: List.generate(_steps.length, (index) {
            final step = _steps[index];
            final isLast = index == _steps.length - 1;
            return _buildStepItem(
              stepNumber: index + 1,
              title: step.title,
              description: step.description,
              isLast: isLast,
            );
          }),
        ),
      ],
    );
  }

  Widget _buildStepItem({
    required int stepNumber,
    required String title,
    required String description,
    required bool isLast,
  }) {
    final numberStr = stepNumber.toString().padLeft(2, '0');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left indicator column
          SizedBox(
            width: 50,
            child: Column(
              children: [
                // Step number + circle
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      numberStr,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kPurpleLight.withAlpha(200),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Circle indicator
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _kPurple, width: 2),
                      ),
                      child: Center(
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: _kPurple,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Dashed line connector (except on last item)
                if (!isLast)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 32),
                      child: CustomPaint(
                        painter: _DashedLinePainter(color: _kPurple),
                        size: const Size(1, double.infinity),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Right content column
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Warning Section
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildWarning() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Warning',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _kWarningRed,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          widget.exercise.warning,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey.shade500,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashed Line Painter
// ─────────────────────────────────────────────────────────────────────────────

class _DashedLinePainter extends CustomPainter {
  final Color color;

  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withAlpha(120)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashHeight = 5.0;
    const dashSpace = 4.0;
    double startY = 0;
    final x = size.width / 2;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(x, startY),
        Offset(x, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Data Models (internal)
// ─────────────────────────────────────────────────────────────────────────────

class _StepData {
  final String title;
  final String description;

  const _StepData({
    required this.title,
    required this.description,
  });
}
