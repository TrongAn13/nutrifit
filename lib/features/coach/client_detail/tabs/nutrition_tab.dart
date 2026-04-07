import 'dart:math';

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

const Color _kPrimary = Color(0xFF6B4EFF);
const Color _kPrimaryLight = Color(0xFFEDE9FF);

/// Nutrition tab content for [ClientDetailScreen].
///
/// Displays a date picker, macro donut chart with linear bars,
/// current diet card, meal diary with comment buttons,
/// and a water + supplements footer row.
class NutritionTab extends StatelessWidget {
  final String clientId;

  const NutritionTab({super.key, required this.clientId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDateSelector(),
        const SizedBox(height: 16),
        _buildMacrosCard(),
        const SizedBox(height: 16),
        _buildDietCard(),
        const SizedBox(height: 16),
        _buildMealDiary(),
        const SizedBox(height: 16),
        _buildWaterAndSupplements(),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 1. Date Selector
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildDateSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.chevron_left, color: Colors.grey.shade500, size: 22),
        const SizedBox(width: 12),
        const Text(
          'HÔM NAY  26/03/2026',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 12),
        Icon(Icons.chevron_right, color: Colors.grey.shade500, size: 22),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. Macros Card
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildMacrosCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          // Donut chart
          Expanded(
            flex: 5,
            child: SizedBox(
              height: 130,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Custom donut painter
                  CustomPaint(
                    size: const Size(120, 120),
                    painter: _DonutPainter(
                      proteinPct: 0.30,
                      carbsPct: 0.45,
                      fatsPct: 0.25,
                    ),
                  ),
                  // Center text
                  const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '1840',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        '/ 2450 KCAL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Macro bars
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _MacroBar(
                  label: 'Protein',
                  value: '138g',
                  progress: 0.72,
                  color: const Color(0xFF3F51B5),
                ),
                const SizedBox(height: 14),
                _MacroBar(
                  label: 'Carbs',
                  value: '210g',
                  progress: 0.58,
                  color: _kPrimary,
                ),
                const SizedBox(height: 14),
                _MacroBar(
                  label: 'Fats',
                  value: '54g',
                  progress: 0.65,
                  color: const Color(0xFFE91E63),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. Diet Card
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildDietCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2FC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _kPrimary.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.restaurant_rounded,
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
                  'Eat Clean Siết mỡ',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '2450 Kcal / ngày • Tuần 3',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'ĐANG ÁP DỤNG',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 4. Meal Diary
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildMealDiary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nhật ký ăn uống',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        _MealCard(
          emoji: '🍳',
          name: 'Bữa sáng',
          detail: 'Trứng luộc, yến mạch, chuối',
          kcal: '420 kcal',
        ),
        const SizedBox(height: 10),
        _MealCard(
          emoji: '🍗',
          name: 'Bữa trưa',
          detail: 'Ức gà nướng, gạo lứt, rau xanh',
          kcal: '650 kcal',
        ),
        const SizedBox(height: 10),
        _MealCard(
          emoji: '🥗',
          name: 'Bữa tối',
          detail: 'Cá hồi, khoai lang, salad',
          kcal: '580 kcal',
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 5. Water & Supplements
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildWaterAndSupplements() {
    return Row(
      children: [
        // Water card
        Expanded(
          child: Container(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('💧', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      'Nước',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  '1.8 / 2.5 L',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 1.8 / 2.5,
                    backgroundColor: Colors.blue.shade50,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Supplements card
        Expanded(
          child: Container(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('💊', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      'Supplements',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _SupplementTag('Whey'),
                    _SupplementTag('Creatine'),
                    _SupplementTag('BCAA'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Donut Painter
// ─────────────────────────────────────────────────────────────────────────────

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.proteinPct,
    required this.carbsPct,
    required this.fatsPct,
  });

  final double proteinPct;
  final double carbsPct;
  final double fatsPct;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 14.0;
    const startAngle = -pi / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Background ring
    paint.color = Colors.grey.shade100;
    canvas.drawCircle(center, radius, paint);

    // Protein arc
    paint.color = const Color(0xFF3F51B5);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      proteinPct * 2 * pi,
      false,
      paint,
    );

    // Carbs arc
    paint.color = const Color(0xFF6B4EFF);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle + proteinPct * 2 * pi,
      carbsPct * 2 * pi,
      false,
      paint,
    );

    // Fats arc
    paint.color = const Color(0xFFE91E63);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle + (proteinPct + carbsPct) * 2 * pi,
      fatsPct * 2 * pi,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.proteinPct != proteinPct ||
      oldDelegate.carbsPct != carbsPct ||
      oldDelegate.fatsPct != fatsPct;
}

// ─────────────────────────────────────────────────────────────────────────────
// Macro Bar
// ─────────────────────────────────────────────────────────────────────────────

class _MacroBar extends StatelessWidget {
  const _MacroBar({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

  final String label;
  final String value;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Meal Card
// ─────────────────────────────────────────────────────────────────────────────

class _MealCard extends StatelessWidget {
  const _MealCard({
    required this.emoji,
    required this.name,
    required this.detail,
    required this.kcal,
  });

  final String emoji;
  final String name;
  final String detail;
  final String kcal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
          Row(
            children: [
              // Emoji icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _kPrimaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              // Name + detail
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Kcal
              Text(
                kcal,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          // Comment button
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {},
              icon: const Text('💬', style: TextStyle(fontSize: 14)),
              label: const Text(
                'NHẬN XÉT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _kPrimary,
                  letterSpacing: 0.3,
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Supplement Tag
// ─────────────────────────────────────────────────────────────────────────────

class _SupplementTag extends StatelessWidget {
  const _SupplementTag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.green.shade700,
        ),
      ),
    );
  }
}
