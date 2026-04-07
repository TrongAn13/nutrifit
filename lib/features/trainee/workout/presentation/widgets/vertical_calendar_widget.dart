import 'package:flutter/material.dart';

import '../../data/models/routine_model.dart';

/// A vertical calendar that displays all days of a selected month.
///
/// Each day row shows the weekday label, day number, and the routine name
/// if one is scheduled for that day of the week. The current day is
/// highlighted with an orange circle.
class VerticalCalendarWidget extends StatefulWidget {
  final List<RoutineModel> routines;

  const VerticalCalendarWidget({super.key, required this.routines});

  @override
  State<VerticalCalendarWidget> createState() => _VerticalCalendarWidgetState();
}

class _VerticalCalendarWidgetState extends State<VerticalCalendarWidget> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  /// Generates all days in [_currentMonth].
  List<DateTime> _daysInMonth() {
    final daysCount = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    ).day;
    return List.generate(
      daysCount,
      (i) => DateTime(_currentMonth.year, _currentMonth.month, i + 1),
    );
  }

  /// Maps day-of-week to routine name. Returns null if rest day.
  String? _routineForDay(int weekday) {
    // weekday: 1=Mon..7=Sun
    for (final r in widget.routines) {
      if (r.dayOfWeek == weekday) return r.name;
    }
    return null;
  }

  /// Vietnamese month name.
  String _monthLabel(int month) {
    const months = [
      'Tháng 1',
      'Tháng 2',
      'Tháng 3',
      'Tháng 4',
      'Tháng 5',
      'Tháng 6',
      'Tháng 7',
      'Tháng 8',
      'Tháng 9',
      'Tháng 10',
      'Tháng 11',
      'Tháng 12',
    ];
    return months[(month - 1).clamp(0, 11)];
  }

  /// Vietnamese weekday label.
  String _weekdayLabel(int weekday) {
    const labels = ['TH 2', 'TH 3', 'TH 4', 'TH 5', 'TH 6', 'TH 7', 'CN'];
    return labels[(weekday - 1).clamp(0, 6)];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final days = _daysInMonth();
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Month Header ──
        _MonthHeader(
          label: '${_monthLabel(_currentMonth.month)}, ${_currentMonth.year}',
          onPrevious: _previousMonth,
          onNext: _nextMonth,
          theme: theme,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 8),

        // ── Day List ──
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: days.length,
          itemBuilder: (context, index) {
            final day = days[index];
            final isToday =
                day.year == now.year &&
                day.month == now.month &&
                day.day == now.day;
            final routineName = _routineForDay(day.weekday);

            return _DayRow(
              weekdayLabel: _weekdayLabel(day.weekday),
              dayNumber: day.day.toString(),
              isToday: isToday,
              routineName: routineName,
              theme: theme,
              colorScheme: colorScheme,
            );
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Month Header
// ─────────────────────────────────────────────────────────────────────────────

class _MonthHeader extends StatelessWidget {
  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _MonthHeader({
    required this.label,
    required this.onPrevious,
    required this.onNext,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left_rounded, size: 22),
                visualDensity: VisualDensity.compact,
                tooltip: 'Tháng trước',
              ),
              IconButton(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right_rounded, size: 22),
                visualDensity: VisualDensity.compact,
                tooltip: 'Tháng sau',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Day Row
// ─────────────────────────────────────────────────────────────────────────────

class _DayRow extends StatelessWidget {
  final String weekdayLabel;
  final String dayNumber;
  final bool isToday;
  final String? routineName;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _DayRow({
    required this.weekdayLabel,
    required this.dayNumber,
    required this.isToday,
    this.routineName,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          // ── Left column: Weekday + Day number ──
          SizedBox(
            width: 50,
            child: Column(
              children: [
                Text(
                  weekdayLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.grey[400],
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                if (isToday)
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.deepOrange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      dayNumber,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: Center(
                      child: Text(
                        dayNumber,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // ── Right column: Routine name or Rest ──
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: routineName != null
                    ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                    : colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.2,
                      ),
                borderRadius: BorderRadius.circular(12),
                border: routineName != null
                    ? Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                      )
                    : null,
              ),
              child: routineName != null
                  ? Row(
                      children: [
                        Icon(
                          Icons.fitness_center_rounded,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            routineName!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'Nghỉ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[300],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
