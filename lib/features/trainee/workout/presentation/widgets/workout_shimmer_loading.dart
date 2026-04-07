import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Reusable shimmer loading placeholders for the Workout Dashboard.
class WorkoutShimmerLoading extends StatelessWidget {
  const WorkoutShimmerLoading({super.key});

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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Header shimmer
            _shimmerBox(width: 200, height: 24),
            const SizedBox(height: 6),
            _shimmerBox(width: 140, height: 16),
            const SizedBox(height: 24),

            // Next workout card shimmer
            _shimmerCard(height: 140),
            const SizedBox(height: 20),

            // Calendar row shimmer
            _shimmerBox(width: 160, height: 18),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                7,
                (_) => _shimmerBox(width: 40, height: 56, radius: 12),
              ),
            ),
            const SizedBox(height: 24),

            // PR section shimmer
            _shimmerBox(width: 180, height: 18),
            const SizedBox(height: 12),
            _shimmerCard(height: 80),
            const SizedBox(height: 10),
            _shimmerCard(height: 80),
          ],
        ),
      ),
    );
  }

  /// Rounded rectangle placeholder.
  static Widget _shimmerBox({
    required double width,
    required double height,
    double radius = 8,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  /// Card-shaped placeholder.
  static Widget _shimmerCard({required double height}) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
