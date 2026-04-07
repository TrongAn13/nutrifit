import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../data/models/workout_plan_model.dart';
import '../../data/models/workout_history_model.dart';
import '../screens/workout_result_screen.dart';

/// Grid-style calendar widget using [TableCalendar].
///
/// Shows workout markers (dumbbell icon) on days that have scheduled
/// routines based on the active [WorkoutPlanModel].
class WorkoutGridCalendar extends StatefulWidget {
  final WorkoutPlanModel plan;
  final List<WorkoutHistoryModel> histories;

  const WorkoutGridCalendar({
    super.key,
    required this.plan,
    required this.histories,
  });

  @override
  State<WorkoutGridCalendar> createState() => _WorkoutGridCalendarState();
}

class _WorkoutGridCalendarState extends State<WorkoutGridCalendar> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
  }

  /// Determines if a given [day] has a workout scheduled.
  ///
  /// Checks if the weekday of [day] matches any routine's [dayOfWeek],
  /// and the day falls within the plan duration (from createdAt + totalWeeks).
  List<dynamic> _getEventsForDay(DateTime day) {
    // 1. Check if history exists for this day (filtered by current plan)
    final currentPlanId = widget.plan.planId;
    try {
      final history = widget.histories.firstWhere(
        (h) => isSameDay(h.date, day) && h.planId == currentPlanId,
      );
      return [history];
    } catch (_) {}

    // 2. Check scheduled plan
    final plan = widget.plan;
    if (plan.trainingDays.isEmpty) return [];

    final planStart = DateTime(
      plan.createdAt.year,
      plan.createdAt.month,
      plan.createdAt.day,
    );
    final planEnd = planStart.add(Duration(days: plan.totalWeeks * 7));

    // Only show markers within plan duration
    if (day.isBefore(planStart) || day.isAfter(planEnd)) return [];

    // Check if this weekday is one of the selected training days
    if (plan.trainingDays.contains(day.weekday)) {
      return ['workout'];
    }

    return [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: TableCalendar<dynamic>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          rowHeight: 45,
          daysOfWeekHeight: 20,
          selectedDayPredicate: (day) =>
              _selectedDay != null && isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            final events = _getEventsForDay(selectedDay);
            if (events.isNotEmpty && events.first is WorkoutHistoryModel) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkoutResultScreen(
                    history: events.first as WorkoutHistoryModel,
                  ),
                ),
              );
            } else {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            }
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          eventLoader: _getEventsForDay,

          // Format / Start day
          calendarFormat: CalendarFormat.month,
          availableCalendarFormats: const {CalendarFormat.month: 'Month'},
          startingDayOfWeek: StartingDayOfWeek.monday,

          // Header style
          headerStyle: HeaderStyle(
            titleCentered: true,
            formatButtonVisible: false,
            titleTextStyle: theme.textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.bold,
            ),
            leftChevronIcon: Icon(
              Icons.chevron_left_rounded,
              color: colorScheme.onSurface,
            ),
            rightChevronIcon: Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurface,
            ),
            headerPadding: const EdgeInsets.symmetric(vertical: 8),
          ),

          // Weekday labels
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: theme.textTheme.bodySmall!.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.4),
              fontWeight: FontWeight.w500,
            ),
            weekendStyle: theme.textTheme.bodySmall!.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.4),
              fontWeight: FontWeight.w500,
            ),
          ),

          // Calendar day styles
          calendarStyle: CalendarStyle(
            // Hide default markers — we use custom markerBuilder
            markersMaxCount: 0,

            // Compressed cell margins
            cellMargin: const EdgeInsets.all(2.0),

            // Today: just primary-colored bold text, no circle fill
            todayDecoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
            ),
            todayTextStyle: theme.textTheme.bodyMedium!.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),

            // Selected day
            selectedDecoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary.withValues(alpha: 0.15),
            ),
            selectedTextStyle: theme.textTheme.bodyMedium!.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),

            // Default day
            defaultTextStyle: theme.textTheme.bodyMedium!.copyWith(
              color: colorScheme.onSurface,
            ),

            // Weekend
            weekendTextStyle: theme.textTheme.bodyMedium!.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),

            // Outside month
            outsideDaysVisible: false,
          ),

          // Custom builders
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              final events = _getEventsForDay(day);
              if (events.isNotEmpty && events.first is WorkoutHistoryModel) {
                return _buildHistoryCell(
                  day,
                  events.first as WorkoutHistoryModel,
                  theme,
                );
              }
              return null;
            },
            todayBuilder: (context, day, focusedDay) {
              final events = _getEventsForDay(day);
              if (events.isNotEmpty && events.first is WorkoutHistoryModel) {
                return _buildHistoryCell(
                  day,
                  events.first as WorkoutHistoryModel,
                  theme,
                );
              }
              return null;
            },
            markerBuilder: (context, day, events) {
              if (events.isEmpty) return null;
              if (events.first is WorkoutHistoryModel) {
                return null; // We draw entirely in default/today
              }

              return Positioned(
                bottom: 2,
                child: Icon(
                  Icons.fitness_center,
                  size: 14,
                  color: colorScheme.primary,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCell(
    DateTime day,
    WorkoutHistoryModel history,
    ThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.all(2.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${history.completionPercentage.round()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
