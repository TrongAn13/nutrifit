import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/routine_model.dart';
import '../../data/models/workout_plan_model.dart';

/// Day label mapping: 1=T2, 2=T3, ..., 7=CN.
const _dayLabelsMap = {
  1: 'Thứ 2',
  2: 'Thứ 3',
  3: 'Thứ 4',
  4: 'Thứ 5',
  5: 'Thứ 6',
  6: 'Thứ 7',
  7: 'Chủ nhật',
};

/// Screen for entering basic workout plan information.
///
/// Collects plan name, description, total weeks, and training days,
/// then creates an empty plan and navigates directly to PlanDetailScreen.
class CreatePlanScreen extends StatefulWidget {
  const CreatePlanScreen({super.key});

  @override
  State<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends State<CreatePlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  int _totalWeeks = 4;
  List<int> _trainingDays = [1, 3, 5]; // Default: Mon, Wed, Fri

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _toggleDay(int day) {
    setState(() {
      if (_trainingDays.contains(day)) {
        // Must keep at least 1 day selected
        if (_trainingDays.length > 1) {
          _trainingDays = List<int>.from(_trainingDays)..remove(day);
        }
      } else {
        _trainingDays = List<int>.from(_trainingDays)..add(day);
      }
      _trainingDays.sort();
    });
  }

  void _onContinue() {
    if (!_formKey.currentState!.validate()) return;

    final sortedDays = List<int>.from(_trainingDays)..sort();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    const uuid = Uuid();

    // Generate empty routines for each week
    final List<RoutineModel> routines = [];
    for (int week = 0; week < _totalWeeks; week++) {
      for (int i = 0; i < sortedDays.length; i++) {
        final dayOfWeek = sortedDays[i];
        final dayLabel = _dayLabelsMap[dayOfWeek] ?? 'Buổi ${i + 1}';
        routines.add(
          RoutineModel(
            routineId: uuid.v4(),
            name: 'Tuần ${week + 1} - $dayLabel',
            dayOfWeek: dayOfWeek,
            exercises: [],
          ),
        );
      }
    }

    // Create empty WorkoutPlanModel
    final newPlan = WorkoutPlanModel(
      planId: uuid.v4(),
      userId: userId,
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      totalWeeks: _totalWeeks,
      trainingDays: sortedDays,
      isActive: false,
      routines: routines,
      createdAt: DateTime.now(),
    );

    // Navigate directly to PlanDetailScreen (replace current route)
    context.pushReplacement('/plan-detail', extra: newPlan);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // ── Custom Header ──
            _CreatePlanHeader(
              onBack: () => context.pop(),
              onContinue: _onContinue,
            ),

            // ── Scrollable Content ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Section: Basic Info ──
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Plan name
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Tên giáo án',
                                hintText: 'VD: Tăng cơ 12 tuần',
                                prefixIcon: Icon(
                                  Icons.edit_outlined,
                                  color: Colors.grey.shade600,
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFF03613),
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Vui lòng nhập tên giáo án'
                                  : null,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 16),

                            // Description
                            TextFormField(
                              controller: _descController,
                              decoration: InputDecoration(
                                labelText: 'Mô tả (tuỳ chọn)',
                                hintText: 'VD: Tập trung phát triển cơ ngực và lưng',
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.only(bottom: 48),
                                  child: Icon(
                                    Icons.description_outlined,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFF03613),
                                    width: 2,
                                  ),
                                ),
                              ),
                              maxLines: 3,
                              textInputAction: TextInputAction.next,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Section: Duration ──
                      _SectionTitle(
                        icon: Icons.calendar_month_outlined,
                        title: 'Thời lượng',
                      ),
                      const SizedBox(height: 12),
                      _NumberSelectorCard(
                        label: 'Số tuần tập luyện',
                        subtitle: 'Thời gian thực hiện giáo án',
                        value: _totalWeeks,
                        min: 1,
                        max: 52,
                        onChanged: (v) => setState(() => _totalWeeks = v),
                      ),
                      const SizedBox(height: 24),

                      // ── Section: Training Days ──
                      _SectionTitle(
                        icon: Icons.event_repeat_outlined,
                        title: 'Ngày tập hàng tuần',
                      ),
                      const SizedBox(height: 12),
                      _WeekdayPickerCard(
                        selectedDays: _trainingDays,
                        onDayToggled: _toggleDay,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Custom Header ─────────────────────────

class _CreatePlanHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onContinue;

  const _CreatePlanHeader({required this.onBack, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1A1C29),
            ),
          ),
          const Spacer(),
          // Step indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFDECE8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.looks_one_rounded,
                  size: 16,
                  color: Color(0xFFF03613),
                ),
                SizedBox(width: 4),
                Text(
                  'Bước 1/2',
                  style: TextStyle(
                    color: Color(0xFFF03613),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onContinue,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFF03613),
            ),
            child: const Text(
              'Tiếp',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ───────────────────────── Section Title ─────────────────────────

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFFF03613)),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1C29),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── Weekday Picker Card ─────────────────────────

class _WeekdayPickerCard extends StatelessWidget {
  final List<int> selectedDays;
  final ValueChanged<int> onDayToggled;

  /// Day labels in Vietnamese: T2 → CN
  static const _dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  static const _dayNames = [
    'Thứ 2',
    'Thứ 3',
    'Thứ 4',
    'Thứ 5',
    'Thứ 6',
    'Thứ 7',
    'CN',
  ];

  const _WeekdayPickerCard({
    required this.selectedDays,
    required this.onDayToggled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDECE8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  color: Color(0xFFF03613),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${selectedDays.length} buổi/tuần',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1C29),
                      ),
                    ),
                    Text(
                      'Chọn các ngày bạn muốn tập',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Day chips - use Row with flexible spacing
          Row(
            children: List.generate(7, (i) {
              final dayValue = i + 1; // 1=Mon ... 7=Sun
              final isSelected = selectedDays.contains(dayValue);

              return Expanded(
                child: GestureDetector(
                  onTap: () => onDayToggled(dayValue),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    margin: EdgeInsets.only(right: i < 6 ? 6 : 0),
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? const Color(0xFFF03613)
                          : Colors.grey.shade100,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFFF03613).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _dayLabels[i],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          // Selected days summary
          if (selectedDays.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _buildSelectedDaysSummary(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _buildSelectedDaysSummary() {
    final sortedDays = List<int>.from(selectedDays)..sort();
    return sortedDays.map((d) => _dayNames[d - 1]).join(', ');
  }
}

// ───────────────────────── Number Selector Card ─────────────────────────

class _NumberSelectorCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _NumberSelectorCard({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFDECE8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Color(0xFFF03613),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1C29),
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          // Number controls
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ControlButton(
                  icon: Icons.remove_rounded,
                  onTap: value > min ? () => onChanged(value - 1) : null,
                ),
                Container(
                  width: 48,
                  alignment: Alignment.center,
                  child: Text(
                    '$value',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1C29),
                    ),
                  ),
                ),
                _ControlButton(
                  icon: Icons.add_rounded,
                  onTap: value < max ? () => onChanged(value + 1) : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _ControlButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isEnabled ? const Color(0xFFF03613) : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isEnabled ? Colors.white : Colors.grey.shade500,
        ),
      ),
    );
  }
}
