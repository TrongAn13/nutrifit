import 'package:flutter/material.dart';

import '../../../tracking/data/models/daily_log_model.dart';
import '../../data/models/food_model.dart';

/// Bottom sheet for specifying food quantity before logging a meal entry.
///
/// Receives a [FoodModel] and [mealType], allows trainee to enter grams,
/// and auto-calculates macros proportionally.
class AddFoodDetailSheet extends StatefulWidget {
  final FoodModel food;
  final String mealType;

  const AddFoodDetailSheet({
    super.key,
    required this.food,
    required this.mealType,
  });

  @override
  State<AddFoodDetailSheet> createState() => _AddFoodDetailSheetState();
}

class _AddFoodDetailSheetState extends State<AddFoodDetailSheet> {
  final _gramsCtrl = TextEditingController(text: '100');
  double _grams = 100;

  /// Macros from FoodModel are per 100g base.
  double get _ratio => _grams / 100;
  double get _calories => widget.food.calories * _ratio;
  double get _protein => widget.food.protein * _ratio;
  double get _fat => widget.food.fat * _ratio;
  double get _carbs => widget.food.carbs * _ratio;

  @override
  void dispose() {
    _gramsCtrl.dispose();
    super.dispose();
  }

  void _onGramsChanged(String value) {
    setState(() {
      _grams = double.tryParse(value) ?? 0;
    });
  }

  void _confirm() {
    final entry = MealEntry(
      mealId: DateTime.now().millisecondsSinceEpoch.toString(),
      mealType: widget.mealType,
      name: widget.food.name,
      calories: _calories,
      protein: _protein,
      fat: _fat,
      carbs: _carbs,
    );
    Navigator.of(context).pop(entry);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Food name header
            Text(
              widget.food.name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.food.category,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),

            // Grams input
            TextFormField(
              controller: _gramsCtrl,
              keyboardType: TextInputType.number,
              onChanged: _onGramsChanged,
              decoration: const InputDecoration(
                labelText: 'Định lượng',
                suffixText: 'g',
                prefixIcon: Icon(Icons.scale_outlined),
              ),
            ),
            const SizedBox(height: 20),

            // Macro preview cards
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _MacroRow(
                    label: 'Calories',
                    value: '${_calories.toStringAsFixed(0)} kcal',
                    color: colorScheme.primary,
                  ),
                  const Divider(height: 20),
                  _MacroRow(
                    label: 'Protein',
                    value: '${_protein.toStringAsFixed(1)} g',
                    color: Colors.blue,
                  ),
                  const Divider(height: 20),
                  _MacroRow(
                    label: 'Fat',
                    value: '${_fat.toStringAsFixed(1)} g',
                    color: Colors.orange,
                  ),
                  const Divider(height: 20),
                  _MacroRow(
                    label: 'Carbs',
                    value: '${_carbs.toStringAsFixed(1)} g',
                    color: Colors.green,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Confirm button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _grams > 0 ? _confirm : null,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Xác nhận thêm'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Macro Row Helper
// ─────────────────────────────────────────────────────────────────────────────

class _MacroRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
