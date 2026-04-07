import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routes/app_router.dart';
import '../../../trainee/user_coach/data/invitation_repository.dart';
import '../../chat/coach_chat_list_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

/// Shared accent colours used throughout the coach dashboard.
const Color _kPrimary = Color(0xFF6B4EFF);
const Color _kPrimaryLight = Color(0xFFEDE9FF);
const Color _kChartLine = Color(0xFF3F51B5);
const Color _kBg = Color(0xFFF7F9FC);

/// Dashboard screen for coach accounts.
///
/// Shows branded header, summary statistics cards, analytics chart,
/// activity stream and highlight alerts.
class CoachDashboardScreen extends StatefulWidget {
  const CoachDashboardScreen({super.key});

  @override
  State<CoachDashboardScreen> createState() => _CoachDashboardScreenState();
}

class _CoachDashboardScreenState extends State<CoachDashboardScreen> {
  /// Toggle state for the analytics chart period selector.
  bool _isMonthlySelected = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildStatsGrid(),
              const SizedBox(height: 28),
              _buildAnalyticsSection(),
              const SizedBox(height: 28),
              _buildActivitySection(),
              const SizedBox(height: 28),
              _buildAlertsSection(),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 1. Header
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row 1: Brand + action icons
        Row(
          children: [
            // Logo icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _kPrimary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.fitness_center_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'NutriFit',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CoachChatListScreen(),
                  ),
                );
              },
              icon: Icon(
                Icons.chat_bubble_outline,
                color: Colors.grey.shade600,
                size: 22,
              ),
            ),
            // Bell with red badge
            Stack(
              children: [
                IconButton(
                  onPressed: () => context.push(AppRouter.notifications),
                  icon: Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.grey.shade600,
                    size: 24,
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Row 2: Greeting + QR button
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chào Coach Nam',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Chuyên gia Dinh dưỡng & Thể hình',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            // QR Code button
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.qr_code_rounded,
                color: Colors.grey.shade600,
                size: 22,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. Stats Grid (4 cards)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'HỌC VIÊN',
                icon: Icons.person_outline,
                value: '24',
                footer: _StatFooterText(text: '+2 mới tuần này', color: Colors.blue),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _StatCard(
                label: 'YÊU CẦU MỚI',
                icon: Icons.assignment_outlined,
                value: '3',
                footer: Row(
                  children: List.generate(
                    3,
                    (_) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'TỈ LỆ TUÂN THỦ',
                icon: Icons.verified_outlined,
                value: '76.4%',
                footer: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.764,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(_kPrimary),
                    minHeight: 6,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _StatCard(
                label: 'LỊCH TẬP HỌC VIÊN',
                icon: Icons.calendar_today_outlined,
                value: '15',
                footer: _StatFooterText(
                  text: 'Đã hoàn thành 2/15',
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. Analytics Chart
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildAnalyticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row
        Row(
          children: [
            const Text(
              'Phân tích',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const Spacer(),
            // Toggle button
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ToggleChip(
                    label: 'Tháng',
                    isSelected: _isMonthlySelected,
                    onTap: () => setState(() => _isMonthlySelected = true),
                  ),
                  _ToggleChip(
                    label: 'Tuần',
                    isSelected: !_isMonthlySelected,
                    onTap: () => setState(() => _isMonthlySelected = false),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Chart container
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade100,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chart header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'TỈ LỆ ĐẠT MỤC TIÊU CHUNG (%)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '+12.4%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF388E3C),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // The line chart
              SizedBox(
                height: 180,
                child: _buildLineChart(),
              ),
              const SizedBox(height: 16),

              // Footer
              Center(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    children: const [
                      TextSpan(text: 'Tổng khối lượng biến đổi: '),
                      TextSpan(
                        text: '-45kg Mỡ',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(text: ' / '),
                      TextSpan(
                        text: '+12kg Cơ',
                        style: TextStyle(
                          color: _kChartLine,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLineChart() {
    // Mock data points
    final spots = [
      const FlSpot(0, 60),
      const FlSpot(1, 65),
      const FlSpot(2, 58),
      const FlSpot(3, 72),
      const FlSpot(4, 68),
      const FlSpot(5, 80),
      const FlSpot(6, 76),
    ];

    return LineChart(
      LineChartData(
        minY: 50,
        maxY: 100,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                const months = [
                  'T1', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7',
                ];
                final idx = value.toInt();
                if (idx < 0 || idx >= months.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    months[idx],
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: 25,
              getTitlesWidget: (value, meta) {
                if (value == 50 || value == 75 || value == 100) {
                  return Text(
                    '${value.toInt()}%',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: _kChartLine,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  _kChartLine.withAlpha(60),
                  _kChartLine.withAlpha(5),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 4. Activity Stream
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hoạt động',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade100,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _ActivityItem(
                time: '15:30',
                name: 'Minh Tú',
                action: 'đã hoàn thành ',
                highlight: 'Squat 80kg',
                icon: Icons.check_circle,
                iconColor: Colors.green,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _ActivityItem(
                time: '14:20',
                name: 'Quốc Bảo',
                action: 'đã cập nhật ',
                highlight: 'bữa trưa 650kcal',
                icon: Icons.restaurant,
                iconColor: Colors.orange,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _ActivityItem(
                time: '12:05',
                name: 'Minh Anh',
                action: 'đã gửi ',
                highlight: 'ảnh tiến trình',
                icon: Icons.image_outlined,
                iconColor: _kPrimary,
              ),
              // View all link
              const Divider(height: 1, indent: 16, endIndent: 16),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Xem tất cả hoạt động',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kChartLine,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 5. Alerts / Tiêu điểm
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildAlertsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tiêu điểm',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade100,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _AlertItem(
                iconBg: Colors.red.shade50,
                iconColor: Colors.red,
                icon: Icons.person_off_outlined,
                title: 'Vắng mặt > 2 ngày',
                badgeText: 'CẦN NHẮC NHỞ',
                badgeColor: Colors.red,
                subtitle: 'Minh Anh, Quốc Bảo chưa cập nhật nhật ký.',
                actionText: 'LIÊN HỆ',
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _AlertItem(
                iconBg: Colors.amber.shade50,
                iconColor: Colors.amber.shade700,
                icon: Icons.local_fire_department_outlined,
                title: 'Vượt Calorie mục tiêu',
                badgeText: 'CẢNH BÁO',
                badgeColor: Colors.amber.shade700,
                subtitle: 'Hoàng Dũng đã vượt 350kcal hôm qua.',
                actionText: 'NHẮC',
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _AlertItem(
                iconBg: Colors.green.shade50,
                iconColor: Colors.green,
                icon: Icons.emoji_events_outlined,
                title: 'Kỷ lục mới',
                badgeText: 'TÍCH CỰC',
                badgeColor: Colors.green,
                subtitle: 'Minh Tú đạt PR Squat 85kg.',
                actionText: 'KHÍCH LỆ',
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _AlertItem(
                iconBg: Colors.blue.shade50,
                iconColor: Colors.blue,
                icon: Icons.warning_amber_rounded,
                title: 'Chấn thương cần theo dõi',
                badgeText: 'LƯU Ý',
                badgeColor: Colors.blue,
                subtitle: 'Trần Bình báo đau vai phải khi Bench Press.',
                actionText: 'LIÊN HỆ',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private Widget Components
// ─────────────────────────────────────────────────────────────────────────────

/// A single stat card for the dashboard grid.
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.icon,
    required this.value,
    required this.footer,
  });

  final String label;
  final IconData icon;
  final String value;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: label + icon
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Icon(icon, size: 18, color: Colors.grey.shade400),
            ],
          ),
          const SizedBox(height: 16),
          // Big value
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          // Footer
          footer,
        ],
      ),
    );
  }
}

/// Coloured text footer used inside [_StatCard].
class _StatFooterText extends StatelessWidget {
  const _StatFooterText({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Period toggle chip used inside the analytics section.
class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }
}

/// A single row in the activity stream.
class _ActivityItem extends StatelessWidget {
  const _ActivityItem({
    required this.time,
    required this.name,
    required this.action,
    required this.highlight,
    required this.icon,
    required this.iconColor,
  });

  final String time;
  final String name;
  final String action;
  final String highlight;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Time
          SizedBox(
            width: 42,
            child: Text(
              time,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: _kPrimaryLight,
            child: Text(
              name[0],
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: _kPrimary,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Text
          Expanded(
            child: RichText(
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: Colors.black87),
                children: [
                  TextSpan(
                    text: name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _kChartLine,
                    ),
                  ),
                  TextSpan(text: ' $action'),
                  TextSpan(
                    text: highlight,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _kChartLine,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Status icon
          Icon(icon, size: 20, color: iconColor),
        ],
      ),
    );
  }
}

/// A single alert row for the spotlight section.
class _AlertItem extends StatelessWidget {
  const _AlertItem({
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.badgeText,
    required this.badgeColor,
    required this.subtitle,
    required this.actionText,
  });

  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String badgeText;
  final Color badgeColor;
  final String subtitle;
  final String actionText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Leading icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Action button
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionText,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: _kChartLine,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Client Bottom Sheet (preserved from original)
// ─────────────────────────────────────────────────────────────────────────────

/// Modal bottom sheet with connection code and email invite sections.
class AddClientBottomSheet extends StatefulWidget {
  const AddClientBottomSheet({super.key});

  @override
  State<AddClientBottomSheet> createState() => _AddClientBottomSheetState();
}

class _AddClientBottomSheetState extends State<AddClientBottomSheet> {
  late String _connectionCode;
  final _emailCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _connectionCode = _generateCode();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  /// Generates a random code in XXXX-YYYY format.
  String _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random();
    final part1 = List.generate(
      4,
      (_) => chars[rng.nextInt(chars.length)],
    ).join();
    final part2 = List.generate(
      4,
      (_) => chars[rng.nextInt(chars.length)],
    ).join();
    return '$part1-$part2';
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _connectionCode));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Đã sao chép mã kết nối!'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
  }

  void _refreshCode() {
    setState(() => _connectionCode = _generateCode());
  }

  Future<void> _sendInvite() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('Vui lòng nhập email hợp lệ'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    try {
      final currentCoach = FirebaseAuth.instance.currentUser;
      if (currentCoach == null) return;

      // Fetch coach name from Firestore
      final coachDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentCoach.uid)
          .get();
      final coachName = coachDoc.data()?['name'] as String? ?? 'HLV';

      await InvitationRepository().sendInvitation(
        coachId: currentCoach.uid,
        coachName: coachName,
        toEmail: email,
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Đã gửi lời mời thành công!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Close Button ──
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Đóng',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Block 1: Connection Code ──
            _sectionHeader(
              icon: Icons.shield_outlined,
              iconBgColor: _kPrimary.withAlpha(30),
              iconColor: _kPrimary,
              title: 'Mã Kết Nối Của Bạn',
              subtitle: 'Gửi mã này cho học viên.',
            ),
            const SizedBox(height: 14),

            // Code display
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                _connectionCode.split('').join(' '),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Copy + Refresh row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copyCode,
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Sao chép mã'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: _refreshCode,
                    icon: Icon(Icons.refresh, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Divider ──
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 20),

            // ── Block 2: Email Invite ──
            _sectionHeader(
              icon: Icons.email_outlined,
              iconBgColor: Colors.blue.shade50,
              iconColor: Colors.blue.shade600,
              title: 'Gửi Lời Mời',
              subtitle: 'Mời học viên qua địa chỉ email.',
            ),
            const SizedBox(height: 16),

            // Email label
            Text(
              'EMAIL HỌC VIÊN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),

            // Email field
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Ví dụ: hocvien@email.com',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Send button
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: _sendInvite,
                style: FilledButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('Gửi lời mời'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a section header row with icon, title, and subtitle.
  Widget _sectionHeader({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Client Card (preserved from original)
// ─────────────────────────────────────────────────────────────────────────────

/// Visual card for a single managed client in the list.
class ClientCard extends StatelessWidget {
  final String clientId;
  final String clientName;
  final String clientGoal;

  const ClientCard({
    super.key,
    required this.clientId,
    required this.clientName,
    required this.clientGoal,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.push(
          '${AppRouter.clientDetail}/$clientId',
          extra: {'clientName': clientName, 'clientGoal': clientGoal},
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: _kPrimaryLight,
              child: Text(
                clientName.isNotEmpty ? clientName[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _kPrimary,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Name + Goal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clientName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.track_changes_outlined,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          clientGoal,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Arrow button
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _kPrimaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_right,
                color: _kPrimary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
