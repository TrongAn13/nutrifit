import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/body_metric_model.dart';
import '../../data/models/progress_photo_model.dart';
import '../../logic/metrics_bloc.dart';
import '../../logic/metrics_event.dart';
import '../../logic/metrics_state.dart';

/// Metrics tab — displays body metrics, weight chart, and progress photos.
class MetricsScreen extends StatelessWidget {
  const MetricsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.read<MetricsBloc>().add(const MetricsLoadRequested());

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<MetricsBloc, MetricsState>(
          builder: (context, state) {
            if (state is MetricsLoading || state is MetricsInitial) {
              return const _ShimmerBody();
            }
            if (state is MetricsError) {
              return _ErrorBody(
                message: state.message,
                onRetry: () => context
                    .read<MetricsBloc>()
                    .add(const MetricsLoadRequested()),
              );
            }
            final loaded = state as MetricsLoaded;
            return _MetricsBody(
              metrics: loaded.metrics,
              photos: loaded.photos,
              isSavingPhoto: loaded.isSavingPhoto,
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Metrics Body
// ─────────────────────────────────────────────────────────────────────────────

class _MetricsBody extends StatelessWidget {
  final List<BodyMetricModel> metrics;
  final List<ProgressPhotoModel> photos;
  final bool isSavingPhoto;

  const _MetricsBody({
    required this.metrics,
    required this.photos,
    this.isSavingPhoto = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──
                    _HeaderSection(),
                    const SizedBox(height: 20),

                    // ── BMI + Weight Cards ──
                    _SummaryCards(
                      latestMetric:
                          metrics.isNotEmpty ? metrics.first : null,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // ── TabBar ──
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                TabBar(
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor:
                      theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: const [
                    Tab(text: 'Biểu đồ'),
                    Tab(text: 'Ảnh tiến độ'),
                  ],
                ),
                theme.colorScheme.surface,
              ),
            ),
          ];
        },
        body: TabBarView(
          children: [
            // Tab 1: Chart
            _ChartTab(metrics: metrics),
            // Tab 2: Photos
            _PhotosTab(photos: photos, isSavingPhoto: isSavingPhoto),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header — with functional buttons
// ─────────────────────────────────────────────────────────────────────────────

class _HeaderSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            'Chỉ số cơ thể',
            style: theme.textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        IconButton.filledTonal(
          onPressed: () => _pickPhoto(context),
          icon: const Icon(Icons.camera_alt_outlined, size: 20),
          tooltip: 'Tải ảnh lên',
        ),
        const SizedBox(width: 8),
        FilledButton.tonalIcon(
          onPressed: () => _showWeightSheet(context),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('Cập nhật'),
        ),
      ],
    );
  }

  /// Opens the weight logging bottom sheet.
  void _showWeightSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetCtx) => _WeightInputSheet(
        onSave: (weight) {
          context.read<MetricsBloc>().add(
                MetricsWeightLogged(weight: weight, date: DateTime.now()),
              );
          Navigator.pop(sheetCtx);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Đã ghi nhận ${weight.toStringAsFixed(1)} kg')),
          );
        },
      ),
    );
  }

  /// Opens image picker and uploads progress photo.
  Future<void> _pickPhoto(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (picked == null || !context.mounted) return;

    context.read<MetricsBloc>().add(
          MetricsPhotoUploaded(imageFile: File(picked.path)),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đang tải ảnh lên...')),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Weight Input Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _WeightInputSheet extends StatefulWidget {
  final ValueChanged<double> onSave;

  const _WeightInputSheet({required this.onSave});

  @override
  State<_WeightInputSheet> createState() => _WeightInputSheetState();
}

class _WeightInputSheetState extends State<_WeightInputSheet> {
  final _controller = TextEditingController();
  double? _weight;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cập nhật cân nặng',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Nhập cân nặng hiện tại của bạn',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            onChanged: (v) => setState(() => _weight = double.tryParse(v)),
            decoration: const InputDecoration(
              labelText: 'Cân nặng',
              suffixText: 'kg',
              prefixIcon: Icon(Icons.scale_outlined),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: _weight != null && _weight! > 0
                  ? () => widget.onSave(_weight!)
                  : null,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Lưu'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BMI + Weight Summary Cards
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryCards extends StatelessWidget {
  final BodyMetricModel? latestMetric;

  const _SummaryCards({required this.latestMetric});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (latestMetric == null) {
      return const _EmptyStateCard(
        message:
            'Chưa có dữ liệu.\nHãy ghi nhận các chỉ số hàng ngày để theo dõi tiến độ.',
      );
    }

    final metric = latestMetric!;
    final bmi = metric.bmi;

    return Row(
      children: [
        // BMI Card
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.monitor_heart_outlined,
                          size: 20, color: colorScheme.primary),
                      const SizedBox(width: 6),
                      Text('BMI',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.6),
                          )),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    bmi.toStringAsFixed(1),
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _bmiColor(bmi),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _bmiColor(bmi).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _bmiLabel(bmi),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: _bmiColor(bmi),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Weight Card
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.scale_outlined,
                          size: 20, color: colorScheme.primary),
                      const SizedBox(width: 6),
                      Text('Cân nặng',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.6),
                          )),
                    ],
                  ),
                  const SizedBox(height: 10),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: metric.weight.toStringAsFixed(1),
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: ' kg',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${metric.height.toInt()} cm',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _bmiColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return AppColors.success;
    if (bmi < 30) return Colors.orange;
    return AppColors.error;
  }

  String _bmiLabel(double bmi) {
    if (bmi < 18.5) return 'Thiếu cân';
    if (bmi < 25) return 'Bình thường';
    if (bmi < 30) return 'Thừa cân';
    return 'Béo phì';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1: Weight Line Chart (fl_chart)
// ─────────────────────────────────────────────────────────────────────────────

class _ChartTab extends StatelessWidget {
  final List<BodyMetricModel> metrics;

  const _ChartTab({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (metrics.isEmpty) {
      return const _EmptyStateCard(
        message:
            'Chưa có dữ liệu.\nHãy ghi nhận các chỉ số hàng ngày để xem biểu đồ.',
      );
    }

    // Take entries from last 30 days
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final recentMetrics = metrics
        .where((m) => m.date.isAfter(cutoff))
        .toList()
        .reversed
        .toList(); // chronological order

    final chartData =
        recentMetrics.isNotEmpty ? recentMetrics : metrics.reversed.toList();

    final spots = chartData.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.weight);
    }).toList();

    final minWeight = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxWeight = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final padding = (maxWeight - minWeight) * 0.2 + 1;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Biến động cân nặng (30 ngày)',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              // Quick add button beside chart title
              IconButton.filledTonal(
                onPressed: () {
                  // Bubble up to header's weight sheet
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    builder: (sheetCtx) => _WeightInputSheet(
                      onSave: (weight) {
                        context.read<MetricsBloc>().add(
                              MetricsWeightLogged(
                                  weight: weight, date: DateTime.now()),
                            );
                        Navigator.pop(sheetCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Đã ghi nhận ${weight.toStringAsFixed(1)} kg')),
                        );
                      },
                    ),
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                tooltip: 'Cập nhật chỉ số',
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minY: minWeight - padding,
                maxY: maxWeight + padding,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval:
                      ((maxWeight - minWeight) / 4).clamp(1, 10),
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: colorScheme.outline.withValues(alpha: 0.15),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: (chartData.length / 5)
                          .ceilToDouble()
                          .clamp(1, 7),
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= chartData.length) {
                          return const SizedBox.shrink();
                        }
                        final d = chartData[idx].date;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${d.day}/${d.month}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.4),
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval:
                          ((maxWeight - minWeight) / 4).clamp(1, 10),
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              colorScheme.onSurface.withValues(alpha: 0.4),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: colorScheme.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 3,
                        color: colorScheme.primary,
                        strokeWidth: 1.5,
                        strokeColor: colorScheme.surface,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color:
                          colorScheme.primary.withValues(alpha: 0.08),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) =>
                        touchedSpots.map((s) {
                      return LineTooltipItem(
                        '${s.y.toStringAsFixed(1)} kg',
                        TextStyle(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList(),
                  ),
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
// Tab 2: Progress Photos with Camera Card
// ─────────────────────────────────────────────────────────────────────────────

class _PhotosTab extends StatelessWidget {
  final List<ProgressPhotoModel> photos;
  final bool isSavingPhoto;

  const _PhotosTab({required this.photos, this.isSavingPhoto = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // itemCount = photos + 1 (camera card at position 0)
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.75,
      ),
      itemCount: photos.length + 1,
      itemBuilder: (context, index) {
        // First item = camera card
        if (index == 0) {
          return _CameraCard(
            isSaving: isSavingPhoto,
            colorScheme: colorScheme,
            theme: theme,
          );
        }

        final photo = photos[index - 1];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Image.network(
                  photo.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: 40,
                      color: colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${photo.date.day}/${photo.date.month}/${photo.date.year}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    if (photo.caption != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        photo.caption!,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Camera card for adding new progress photos.
class _CameraCard extends StatelessWidget {
  final bool isSaving;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _CameraCard({
    required this.isSaving,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isSaving ? null : () => _pickPhoto(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
              width: 2,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSaving)
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: colorScheme.primary,
                  ),
                )
              else
                Icon(
                  Icons.camera_alt_rounded,
                  size: 40,
                  color: colorScheme.primary.withValues(alpha: 0.5),
                ),
              const SizedBox(height: 12),
              Text(
                isSaving ? 'Đang tải...' : 'Thêm ảnh',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPhoto(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (picked == null || !context.mounted) return;

    context.read<MetricsBloc>().add(
          MetricsPhotoUploaded(imageFile: File(picked.path)),
        );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TabBar Delegate
// ─────────────────────────────────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final Color _backgroundColor;

  _TabBarDelegate(this._tabBar, this._backgroundColor);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: _backgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyStateCard extends StatelessWidget {
  final String message;

  const _EmptyStateCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_chart_outlined,
              size: 56,
              color: colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shimmer Body
// ─────────────────────────────────────────────────────────────────────────────

class _ShimmerBody extends StatelessWidget {
  const _ShimmerBody();

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final baseColor = isLight ? Colors.grey.shade300 : Colors.grey.shade700;
    final highlightColor =
        isLight ? Colors.grey.shade100 : Colors.grey.shade600;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header shimmer
            Row(
              children: [
                Container(width: 160, height: 28, color: Colors.white),
                const Spacer(),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 100,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // 2 summary cards
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 130,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 130,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Tab bar shimmer
            Container(
              width: double.infinity,
              height: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            // Chart shimmer
            Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error Body
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.error),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
