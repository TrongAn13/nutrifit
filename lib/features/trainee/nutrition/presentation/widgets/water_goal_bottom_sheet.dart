import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Bottom sheet for adjusting the daily water intake goal.
///
/// Uses a [CupertinoPicker] to scroll from 1000 ml to 4000 ml
/// in 100 ml increments.
class WaterGoalBottomSheet extends StatefulWidget {
  final int currentGoalMl;
  final int recommendedGoalMl;
  final ValueChanged<int> onSave;

  const WaterGoalBottomSheet({
    super.key,
    required this.currentGoalMl,
    required this.recommendedGoalMl,
    required this.onSave,
  });

  @override
  State<WaterGoalBottomSheet> createState() => _WaterGoalBottomSheetState();
}

class _WaterGoalBottomSheetState extends State<WaterGoalBottomSheet> {
  static const int _minMl = 1000;
  static const int _step = 100;
  static const int _itemCount = 31; // 1000..4000

  late final FixedExtentScrollController _scrollCtrl;
  late int _selectedMl;

  @override
  void initState() {
    super.initState();
    _selectedMl = widget.currentGoalMl;
    final index = ((_selectedMl - _minMl) / _step).round().clamp(
      0,
      _itemCount - 1,
    );
    _scrollCtrl = FixedExtentScrollController(initialItem: index);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
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
            const SizedBox(height: 20),

            // Header
            Text(
              'Khuyến nghị từ ứng dụng',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Description
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Dựa trên thể trạng của bạn, khuyến nghị ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  TextSpan(
                    text: '${widget.recommendedGoalMl} ml',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.lightBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: ' mỗi ngày.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Cupertino Picker
            Flexible(
              child: SizedBox(
                height: 200,
                child: CupertinoPicker(
                  scrollController: _scrollCtrl,
                  itemExtent: 44,
                  onSelectedItemChanged: (index) {
                    setState(() => _selectedMl = _minMl + index * _step);
                  },
                  children: List.generate(_itemCount, (i) {
                    final val = _minMl + i * _step;
                    final isSelected = val == _selectedMl;
                    return Center(
                      child: Text(
                        '$val ml',
                        style: TextStyle(
                          fontSize: isSelected ? 20 : 16,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected ? Colors.black87 : Colors.grey[400],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () {
                  widget.onSave(_selectedMl);
                  Navigator.of(context).pop();
                },
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
      ),
    );
  }
}
