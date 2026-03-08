import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


/// Screen for entering basic workout plan information.
///
/// Collects plan name, description, total weeks, and training days,
/// then navigates to the routine builder screen.
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

    // Navigate to the routine builder screen
    context.push('/create-routine', extra: {
      'name': _nameController.text.trim(),
      'description': _descController.text.trim(),
      'totalWeeks': _totalWeeks,
      'trainingDays': sortedDays,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Tạo giáo án mới')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Plan name ──
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên giáo án *',
                  hintText: 'VD: Tăng cơ 12 tuần',
                  prefixIcon: Icon(Icons.edit_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Vui lòng nhập tên'
                    : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // ── Description ──
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  hintText:
                      'VD: Giáo án tập trung vào phát triển cơ ngực và lưng',
                  prefixIcon: Icon(Icons.description_outlined),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 24),

              // ── Total weeks ──
              _NumberSelector(
                label: 'Số tuần',
                icon: Icons.calendar_month_outlined,
                value: _totalWeeks,
                min: 1,
                max: 52,
                onChanged: (v) => setState(() => _totalWeeks = v),
                colorScheme: colorScheme,
                theme: theme,
              ),
              const SizedBox(height: 16),

              // ── Training Days Picker ──
              _WeekdayPicker(
                selectedDays: _trainingDays,
                onDayToggled: _toggleDay,
                theme: theme,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 32),

              // ── Continue button ──
              FilledButton.icon(
                onPressed: _onContinue,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Tiếp tục'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Weekday Picker Widget ─────────────────────────

/// A row of 7 circular day-of-week toggles (Mon→Sun).
///
/// Selected days use a DeepOrange background with white text,
/// unselected days use a subtle grey background.
class _WeekdayPicker extends StatelessWidget {
  final List<int> selectedDays;
  final ValueChanged<int> onDayToggled;
  final ThemeData theme;
  final ColorScheme colorScheme;

  /// Day labels in Vietnamese: T2 → CN
  static const _dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  const _WeekdayPicker({
    required this.selectedDays,
    required this.onDayToggled,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.event_repeat_outlined,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ngày tập (${selectedDays.length} buổi/tuần)',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.spaceEvenly,
              spacing: 8,
              runSpacing: 8,
              children: List.generate(7, (i) {
                final dayValue = i + 1; // 1=Mon ... 7=Sun
                final isSelected = selectedDays.contains(dayValue);

                return GestureDetector(
                  onTap: () => onDayToggled(dayValue),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? Colors.deepOrange
                          : colorScheme.surfaceContainerHighest,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _dayLabels[i],
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: isSelected
                            ? Colors.white
                            : colorScheme.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Number Selector Widget ─────────────────────────

class _NumberSelector extends StatelessWidget {
  final String label;
  final IconData icon;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _NumberSelector({
    required this.label,
    required this.icon,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
            IconButton.filled(
              onPressed: value > min ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove, size: 18),
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                minimumSize: const Size(36, 36),
              ),
            ),
            SizedBox(
              width: 40,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton.filled(
              onPressed: value < max ? () => onChanged(value + 1) : null,
              icon: const Icon(Icons.add, size: 18),
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                minimumSize: const Size(36, 36),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
