import 'package:flutter/material.dart';

import '../../data/models/water_entry_model.dart';

/// Drink type definition used in the selection grid.
class _DrinkType {
  final String name;
  final IconData icon;
  final double hydrationFactor;

  const _DrinkType(this.name, this.icon, this.hydrationFactor);
}

/// Bottom sheet for selecting a drink type, entering amount, and saving.
///
/// Features:
///   - Chip-based drink type grid
///   - Quick-add amount buttons (horizontal scroll)
///   - Custom numpad for precise input
class DrinkSelectionBottomSheet extends StatefulWidget {
  final ValueChanged<WaterEntryModel> onSave;

  const DrinkSelectionBottomSheet({super.key, required this.onSave});

  @override
  State<DrinkSelectionBottomSheet> createState() =>
      _DrinkSelectionBottomSheetState();
}

class _DrinkSelectionBottomSheetState extends State<DrinkSelectionBottomSheet> {
  static const List<_DrinkType> _drinks = [
    _DrinkType('Nước', Icons.water_drop, 1.0),
    _DrinkType('Sữa', Icons.local_cafe, 0.87),
    _DrinkType('Cà phê', Icons.coffee, 0.80),
    _DrinkType('Trà', Icons.emoji_food_beverage, 0.90),
    _DrinkType('Nước ép', Icons.local_bar, 0.85),
    _DrinkType('Sinh tố', Icons.blender, 0.80),
    _DrinkType('Nước ngọt', Icons.local_drink, 0.50),
    _DrinkType('Bia', Icons.sports_bar, 0.10),
  ];

  static const List<int> _quickAmounts = [
    100,
    150,
    200,
    250,
    300,
    350,
    400,
    500,
  ];

  int _selectedDrinkIndex = 0;
  String _amountText = '250';

  int get _amount => int.tryParse(_amountText) ?? 0;
  _DrinkType get _selectedDrink => _drinks[_selectedDrinkIndex];

  int get _effectiveMl => (_amount * _selectedDrink.hydrationFactor).round();

  void _onNumpad(String key) {
    setState(() {
      if (key == 'backspace') {
        if (_amountText.isNotEmpty) {
          _amountText = _amountText.substring(0, _amountText.length - 1);
        }
      } else {
        if (_amountText.length < 5) {
          // Prevent leading zeros
          if (_amountText == '0' && key != '00') {
            _amountText = key;
          } else {
            _amountText += key;
          }
        }
      }
    });
  }

  void _onSave() {
    if (_amount <= 0) return;

    final entry = WaterEntryModel(
      entryId: 'water_${DateTime.now().millisecondsSinceEpoch}',
      drinkName: _selectedDrink.name,
      amountMl: _amount,
      hydrationFactor: _selectedDrink.hydrationFactor,
      loggedAt: DateTime.now(),
    );
    widget.onSave(entry);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Drink type chips ──
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_drinks.length, (i) {
              final drink = _drinks[i];
              final isSelected = i == _selectedDrinkIndex;
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      drink.icon,
                      size: 16,
                      color: isSelected ? Colors.white : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(drink.name),
                  ],
                ),
                selected: isSelected,
                selectedColor: Colors.lightBlue,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                backgroundColor: Colors.grey[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onSelected: (_) => setState(() => _selectedDrinkIndex = i),
              );
            }),
          ),
          const SizedBox(height: 20),

          // ── Amount display ──
          Text(
            '${_amountText.isEmpty ? '0' : _amountText} ml',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Thực chứa $_effectiveMl ml nước',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),

          // ── Quick add row ──
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _quickAmounts.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final amt = _quickAmounts[i];
                final isActive = _amount == amt;
                return GestureDetector(
                  onTap: () => setState(() => _amountText = amt.toString()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.lightBlue : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$amt',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : Colors.grey[700],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // ── Custom numpad ──
          _buildNumpad(theme),
          const SizedBox(height: 16),

          // ── Save button ──
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _amount > 0 ? _onSave : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Lưu',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumpad(ThemeData theme) {
    const keys = [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      'backspace',
      '0',
      '00',
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: keys.map((key) {
        final isBackspace = key == 'backspace';
        return Material(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _onNumpad(key),
            child: Center(
              child: isBackspace
                  ? Icon(
                      Icons.backspace_outlined,
                      size: 22,
                      color: Colors.grey[700],
                    )
                  : Text(
                      key,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
