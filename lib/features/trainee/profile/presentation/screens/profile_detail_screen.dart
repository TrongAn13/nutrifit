import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:vertical_weight_slider/vertical_weight_slider.dart';

import '../../../../../core/theme/app_colors.dart';

import '../../../../auth/data/models/user_model.dart';
import '../../data/repositories/profile_repository.dart';
import 'allergy_selection_screen.dart';

/// Read-only profile detail screen showing trainee information
/// in a card-based layout grouped by sections.
/// Tapping on editable rows opens BottomSheets for inline editing.
class ProfileDetailScreen extends StatefulWidget {
  const ProfileDetailScreen({super.key});

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  final _repo = ProfileRepository();
  UserModel? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _repo.getProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Helper formatters ──

  String _formatGender(String? g) => switch (g) {
        'male' => 'Nam',
        'female' => 'Nữ',
        'other' => 'Khác',
        _ => '--',
      };

  String _formatDate(DateTime? d) =>
      d != null ? DateFormat('dd/MM/yyyy').format(d) : '--';

  String _formatActivityLevel(String? level) => switch (level) {
        'sedentary' => 'Ít vận động',
        'light' => 'Nhẹ nhàng',
        'moderate' => 'Trung bình',
        'active' => 'Năng động',
        'very_active' => 'Rất năng động',
        _ => '--',
      };

  String _formatWorkActivity(String? level) => switch (level) {
        'sedentary' => 'Ít vận động',
        'light' => 'Vận động nhẹ',
        'moderate' => 'Vận động vừa phải',
        'active' => 'Vận động nhiều',
        _ => '--',
      };

  String _formatHomeActivity(String? level) => switch (level) {
        'sedentary' => 'Ít hoạt động',
        'light' => 'Nhẹ nhàng',
        'moderate' => 'Linh hoạt',
        'active' => 'Năng nổ',
        _ => '--',
      };

  String _formatGoal(String? goal) => switch (goal) {
        'lose_weight' => 'Giảm cân',
        'maintain' => 'Giữ cân',
        'gain_muscle' => 'Tăng cơ',
        _ => '--',
      };

  // ── BMI / BMR / TDEE calculations ──

  double? _calcBmi(double? h, double? w) {
    if (h == null || w == null || h == 0) return null;
    return w / ((h / 100) * (h / 100));
  }

  double? _calcBmr(double? h, double? w, DateTime? birth, String? gender) {
    if (h == null || w == null || birth == null || gender == null) return null;
    final age = DateTime.now().difference(birth).inDays ~/ 365;
    // Mifflin-St Jeor
    if (gender == 'male') return 10 * w + 6.25 * h - 5 * age + 5;
    return 10 * w + 6.25 * h - 5 * age - 161;
  }

  double? _calcTdee(double? bmr, String? activity) {
    if (bmr == null) return null;
    final factor = switch (activity) {
      'sedentary' => 1.2,
      'light' => 1.375,
      'moderate' => 1.55,
      'active' => 1.725,
      'very_active' => 1.9,
      _ => 1.2,
    };
    return bmr * factor;
  }

  double _getPalFactor(String? activity) {
    return switch (activity) {
      'sedentary' => 1.2,
      'light' => 1.375,
      'moderate' => 1.55,
      'active' => 1.725,
      'very_active' => 1.9,
      _ => 1.2,
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Info Dialog (BMI, BMR, TDEE)
  // ═══════════════════════════════════════════════════════════════════════════

  void _showInfoDialog({
    required String title,
    required String definition,
    required String userValueText,
    required String formulaTitle,
    required String formula,
    required List<String> notes,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Definition section
              Text(
                '$title là gì?',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                definition,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),

              // User value section
              Text(
                '$title của bạn: $userValueText',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 12),

              // Formula section
              Text(
                formulaTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formula,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              // Notes section
              const Text(
                'Chú thích:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              ...notes.map((note) => Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 2),
                child: Text(
                  '• $note',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'OK',
              style: TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BottomSheet: Text Input (for Name, Phone, Email)
  // ═══════════════════════════════════════════════════════════════════════════

  void _showTextInputSheet({
    required String title,
    required String label,
    required String initialValue,
    TextInputType keyboardType = TextInputType.text,
    required Future<void> Function(String value) onSave,
  }) {
    final controller = TextEditingController(text: initialValue);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Row(
                children: [
                  const Spacer(),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetCtx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Label ──
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),

              // ── Text Field ──
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Save Button ──
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: () async {
                    final value = controller.text.trim();
                    if (value.isEmpty) return;
                    Navigator.pop(sheetCtx);
                    await onSave(value);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Lưu',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BottomSheet: Gender Selection
  // ═══════════════════════════════════════════════════════════════════════════

  void _showGenderSelectionSheet() {
    String selected = _profile?.gender ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header ──
                  Row(
                    children: [
                      const Spacer(),
                      const Text(
                        'Giới tính sinh học',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetCtx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Female option ──
                  _GenderOptionTile(
                    icon: Icons.female,
                    label: 'Nữ',
                    isSelected: selected == 'female',
                    onTap: () =>
                        setSheetState(() => selected = 'female'),
                  ),
                  const SizedBox(height: 8),

                  // ── Male option ──
                  _GenderOptionTile(
                    icon: Icons.male,
                    label: 'Nam',
                    isSelected: selected == 'male',
                    onTap: () =>
                        setSheetState(() => selected = 'male'),
                  ),
                  const SizedBox(height: 20),

                  // ── Save Button ──
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: () async {
                        Navigator.pop(sheetCtx);
                        if (selected.isNotEmpty) {
                          try {
                            await _repo.updateProfile(
                              name: _profile?.name ?? '',
                              gender: selected,
                            );
                            await _loadProfile();
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Lỗi: ${e.toString()}')),
                              );
                            }
                          }
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Lưu',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BottomSheet: Date Picker (Birth Date)
  // ═══════════════════════════════════════════════════════════════════════════

  void _showDatePickerSheet() {
    DateTime selectedDate =
        _profile?.birthDate ?? DateTime(2000, 1, 1);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.only(
                  left: 20, right: 20, top: 16, bottom: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      const Spacer(),
                      const Text('Ngày sinh',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetCtx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Cupertino Date Picker
                  SizedBox(
                    height: 200,
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.date,
                      initialDateTime: selectedDate,
                      minimumDate: DateTime(1940),
                      maximumDate: DateTime.now(),
                      onDateTimeChanged: (date) {
                        setSheetState(() => selectedDate = date);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: () async {
                        Navigator.pop(sheetCtx);
                        try {
                          await _repo.updateProfile(
                            name: _profile?.name ?? '',
                            birthDate: selectedDate,
                          );
                          await _loadProfile();
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Lỗi: ${e.toString()}')),
                            );
                          }
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Lưu',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BottomSheet: Height Picker
  // ═══════════════════════════════════════════════════════════════════════════

  void _showHeightPickerSheet() {
    const int minHeight = 100;
    const int maxHeight = 250;
    final int initialIndex =
        (_profile?.height?.toInt() ?? 170) - minHeight;
    int selectedHeight = _profile?.height?.toInt() ?? 170;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.only(
              left: 20, right: 20, top: 16, bottom: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  const Spacer(),
                  const Text('Chiều cao',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetCtx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Cupertino Picker
              SizedBox(
                height: 200,
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(
                      initialItem: initialIndex),
                  itemExtent: 40,
                  onSelectedItemChanged: (index) {
                    selectedHeight = minHeight + index;
                  },
                  children: List.generate(
                    maxHeight - minHeight + 1,
                    (i) => Center(
                      child: Text(
                        '${minHeight + i} cm',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: () async {
                    Navigator.pop(sheetCtx);
                    try {
                      await _repo.updateProfile(
                        name: _profile?.name ?? '',
                        height: selectedHeight.toDouble(),
                      );
                      await _loadProfile();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('Lỗi: ${e.toString()}')),
                        );
                      }
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Lưu',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BottomSheet: Weight Ruler (using vertical_weight_slider horizontal)
  // ═══════════════════════════════════════════════════════════════════════════

  void _showWeightRulerSheet() {
    double currentWeight = _profile?.weight ?? 70.0;
    final controller = WeightSliderController(
      initialWeight: currentWeight,
      minWeight: 30,
      interval: 0.1,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.only(top: 16, bottom: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Spacer(),
                        const Text('Cân nặng',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            controller.dispose();
                            Navigator.pop(sheetCtx);
                          },
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Current weight display
                  Text(
                    '${currentWeight.toStringAsFixed(1)} kg',
                    style: const TextStyle(
                      fontSize: 28, // Even smaller font
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8), // Less gap

                  // Horizontal weight slider
                  SizedBox(
                    height: 60, // Constrain the overall height of the slider
                    child: VerticalWeightSlider(
                      isVertical: false,
                      controller: controller,
                      decoration: const PointerDecoration(
                        width: 40.0,
                        height: 2.0, // Thinner lines
                        largeColor: Color(0xFF898989),
                        mediumColor: Color(0xFFC5C5C5),
                        smallColor: Color(0xFFF0F0F0),
                        gap: 16.0,
                      ),
                      onChanged: (double value) {
                        setSheetState(
                            () => currentWeight = value);
                      },
                      indicator: Container(
                        height: 2.0,
                        width: 80.0,
                        alignment: Alignment.centerLeft,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),



                  // Save Button
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: () async {
                          final w = currentWeight;
                          controller.dispose();
                          Navigator.pop(sheetCtx);
                          try {
                            await _repo.updateProfile(
                              name: _profile?.name ?? '',
                              weight: double.parse(
                                  w.toStringAsFixed(1)),
                            );
                            await _loadProfile();
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                      content: Text(
                                          'Lỗi: ${e.toString()}')));
                            }
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Lưu',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Activity Level Sheet
  // ═══════════════════════════════════════════════════════════════════════════

  /// Reusable bottom sheet for selecting activity levels.
  /// [title] - Sheet title (e.g. "Mức độ công việc")
  /// [options] - List of {value, label, subtitle} maps
  /// [currentValue] - Current selected value
  /// [onSave] - Callback when trainee saves selection
  void _showActivityLevelSheet({
    required String title,
    required List<Map<String, String>> options,
    required String? currentValue,
    required Future<void> Function(String) onSave,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        String? selectedValue = currentValue;

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      children: [
                        const SizedBox(width: 40),
                        Expanded(
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetCtx),
                          icon: const Icon(Icons.close, size: 24),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Options
                    ...options.map((option) {
                      final isSelected = selectedValue == option['value'];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ActivityOptionTile(
                          label: option['label'] ?? '',
                          subtitle: option['subtitle'],
                          isSelected: isSelected,
                          onTap: () {
                            setSheetState(() => selectedValue = option['value']);
                          },
                        ),
                      );
                    }),

                    const SizedBox(height: 8),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: selectedValue != null
                            ? () async {
                                Navigator.pop(sheetCtx);
                                await onSave(selectedValue!);
                              }
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Lưu',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════════════════
  // Save helpers called from text input sheets
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _saveName(String value) async {
    try {
      await _repo.updateProfile(name: value);
      await _loadProfile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    }
  }

  Future<void> _savePhone(String value) async {
    try {
      await _repo.updateProfile(
        name: _profile?.name ?? '',
        phone: value,
      );
      await _loadProfile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    }
  }

  Future<void> _saveEmail(String value) async {
    // Email update requires Firebase Auth re-authentication,
    // so for now we only update Firestore field.
    try {
      await _repo.updateProfile(
        name: _profile?.name ?? '',
      );
      await _loadProfile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    }
  }

  Future<void> _saveWorkActivity(String value) async {
    try {
      await _repo.updateProfile(
        name: _profile?.name ?? '',
        workActivity: value,
      );
      await _loadProfile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    }
  }

  Future<void> _saveHomeActivity(String value) async {
    try {
      await _repo.updateProfile(
        name: _profile?.name ?? '',
        homeActivity: value,
      );
      await _loadProfile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    }
  }

  Future<void> _saveActivityLevel(String value) async {
    try {
      await _repo.updateProfile(
        name: _profile?.name ?? '',
        activityLevel: value,
      );
      await _loadProfile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    }
  }

  Future<void> _saveGoal(String value) async {
    try {
      await _repo.updateProfile(
        name: _profile?.name ?? '',
        goal: value,
      );
      await _loadProfile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Build
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Hồ sơ cá nhân',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header: Avatar + Name + Edit photo ──
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: theme.colorScheme.primary
                              .withValues(alpha: 0.12),
                          backgroundImage: user?.photoURL != null
                              ? NetworkImage(user!.photoURL!)
                              : null,
                          child: user?.photoURL == null
                              ? Icon(Icons.person,
                                  size: 32,
                                  color: theme.colorScheme.primary)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _profile?.name ?? 'Người dùng',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Thành viên từ ${_formatDate(_profile?.createdAt)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton.tonal(
                          onPressed: () {
                            // TODO: Open image picker
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.grey.shade200,
                            foregroundColor: Colors.black87,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                          ),
                          child: const Text('Sửa ảnh',
                              style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  ),

                  // ── Section 1: THÔNG TIN THÀNH VIÊN ──
                  const _SectionLabel(title: 'THÔNG TIN THÀNH VIÊN'),
                  _CardGroup(children: [
                    _InfoRow(
                      label: 'UserID',
                      value: _profile?.uid.substring(0, 8) ?? '--',
                      trailing: GestureDetector(
                        onTap: () {
                          Clipboard.setData(
                            ClipboardData(text: _profile?.uid ?? ''),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã copy ID'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Icon(Icons.copy_outlined,
                            size: 18, color: Colors.grey.shade400),
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _InfoRow(
                      label: 'Tên',
                      value: _profile?.name ?? '--',
                      onTap: () => _showTextInputSheet(
                        title: 'Cập nhật thông tin',
                        label: 'Đặt tên',
                        initialValue: _profile?.name ?? '',
                        onSave: _saveName,
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _InfoRow(label: 'Gói đăng ký', value: 'Gói dùng thử'),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _InfoRow(
                      label: 'Điện thoại',
                      value: _profile?.phone ?? '--',
                      onTap: () => _showTextInputSheet(
                        title: 'Cập nhật thông tin',
                        label: 'Số điện thoại',
                        initialValue: _profile?.phone ?? '',
                        keyboardType: TextInputType.phone,
                        onSave: _savePhone,
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _InfoRow(
                      label: 'Email',
                      value: _profile?.email ?? '--',
                      onTap: () => _showTextInputSheet(
                        title: 'Cập nhật thông tin',
                        label: 'Địa chỉ email',
                        initialValue: _profile?.email ?? '',
                        keyboardType: TextInputType.emailAddress,
                        onSave: _saveEmail,
                      ),
                    ),
                  ]),

                  // ── Section 2: THÔNG TIN CƠ BẢN ──
                  const _SectionLabel(title: 'THÔNG TIN CƠ BẢN'),
                  Builder(builder: (_) {
                    final bmi =
                        _calcBmi(_profile?.height, _profile?.weight);
                    final bmr = _calcBmr(_profile?.height, _profile?.weight,
                        _profile?.birthDate, _profile?.gender);
                    final tdee = _calcTdee(bmr, _profile?.activityLevel);

                    return _CardGroup(children: [
                      _InfoRow(
                        label: 'Giới tính',
                        value: _formatGender(_profile?.gender),
                        onTap: _showGenderSelectionSheet,
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _InfoRow(
                        label: 'Ngày sinh',
                        value: _formatDate(_profile?.birthDate),
                        onTap: _showDatePickerSheet,
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _InfoRow(
                        label: 'Chiều cao',
                        value: _profile?.height != null
                            ? '${_profile!.height!.toStringAsFixed(0)} cm'
                            : '--',
                        onTap: _showHeightPickerSheet,
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _InfoRow(
                        label: 'Cân nặng',
                        value: _profile?.weight != null
                            ? '${_profile!.weight!.toStringAsFixed(1)} kg'
                            : '--',
                        onTap: _showWeightRulerSheet,
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _InfoRow(
                        label: 'Mục tiêu',
                        value: _formatGoal(_profile?.goal),
                        onTap: () => _showActivityLevelSheet(
                          title: 'Mục tiêu',
                          options: const [
                            {'value': 'lose_weight', 'label': 'Giảm cân', 'subtitle': 'Giảm mỡ, giữ cơ'},
                            {'value': 'maintain', 'label': 'Giữ cân', 'subtitle': 'Duy trì cân nặng hiện tại'},
                            {'value': 'gain_muscle', 'label': 'Tăng cơ', 'subtitle': 'Tăng cơ bắp, tăng cân'},
                          ],
                          currentValue: _profile?.goal,
                          onSave: _saveGoal,
                        ),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _InfoRow(
                        label: 'Mức độ công việc',
                        value: _formatWorkActivity(_profile?.workActivity),
                        onTap: () => _showActivityLevelSheet(
                          title: 'Mức độ công việc',
                          options: const [
                            {'value': 'sedentary', 'label': 'Ít vận động', 'subtitle': 'Ngồi máy tính cả ngày'},
                            {'value': 'light', 'label': 'Vận động nhẹ', 'subtitle': 'Đi lại nhẹ nhàng, đứng nhiều'},
                            {'value': 'moderate', 'label': 'Vận động vừa phải', 'subtitle': 'Công việc đòi hỏi vận động'},
                            {'value': 'active', 'label': 'Vận động nhiều', 'subtitle': 'Lao động chân tay nặng'},
                          ],
                          currentValue: _profile?.workActivity,
                          onSave: _saveWorkActivity,
                        ),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _InfoRow(
                        label: 'Hoạt động ở nhà',
                        value: _formatHomeActivity(_profile?.homeActivity),
                        onTap: () => _showActivityLevelSheet(
                          title: 'Hoạt động ở nhà',
                          options: const [
                            {'value': 'sedentary', 'label': 'Ít hoạt động', 'subtitle': 'Chủ yếu nằm, ngồi'},
                            {'value': 'light', 'label': 'Nhẹ nhàng', 'subtitle': 'Việc nhà cơ bản'},
                            {'value': 'moderate', 'label': 'Linh hoạt', 'subtitle': 'Dọn dẹp, nấu ăn thường xuyên'},
                            {'value': 'active', 'label': 'Năng nổ', 'subtitle': 'Hoạt động liên tục, chăm sóc con nhỏ'},
                          ],
                          currentValue: _profile?.homeActivity,
                          onSave: _saveHomeActivity,
                        ),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _InfoRow(
                        label: 'Tập luyện thể chất',
                        value: _formatActivityLevel(_profile?.activityLevel),
                        onTap: () => _showActivityLevelSheet(
                          title: 'Tập luyện thể chất',
                          options: const [
                            {'value': 'sedentary', 'label': 'Không tập luyện', 'subtitle': 'Không hoặc rất ít vận động'},
                            {'value': 'light', 'label': 'Tập luyện nhẹ', 'subtitle': '1-2 buổi/tuần'},
                            {'value': 'moderate', 'label': 'Tập luyện trung bình', 'subtitle': '3-4 buổi/tuần'},
                            {'value': 'active', 'label': 'Tập luyện tích cực', 'subtitle': '5-6 buổi/tuần'},
                            {'value': 'very_active', 'label': 'Vận động viên', 'subtitle': 'Tập luyện mỗi ngày, cường độ cao'},
                          ],
                          currentValue: _profile?.activityLevel,
                          onSave: _saveActivityLevel,
                        ),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _InfoRow(
                        label: 'BMI',
                        value: bmi != null ? bmi.toStringAsFixed(1) : '--',
                        trailing: Icon(Icons.info_outline,
                            size: 18, color: Colors.grey.shade400),
                        onTap: bmi != null
                            ? () => _showInfoDialog(
                                  title: 'BMI',
                                  definition:
                                      'BMI là viết tắt của chỉ số khối cơ thể (Body Mass Index), là một chỉ số đơn giản để đánh giá tình trạng cân nặng của một người dựa trên chiều cao và cân nặng của họ. Chỉ số này giúp xác định bạn có đang ở mức thiếu cân, bình thường, thừa cân hay béo phì, từ đó có biện pháp điều chỉnh chế độ ăn uống và sinh hoạt hợp lý.',
                                  userValueText: bmi.toStringAsFixed(1),
                                  formulaTitle: 'Công thức tính BMI',
                                  formula: 'BMI = (Cân nặng) ÷ (Chiều cao)²',
                                  notes: [
                                    'BMI < 18,5: Thiếu cân',
                                    'BMI : 18,5 - 22,9: Bình thường',
                                    'BMI : 23 - 24,9: Thừa cân',
                                    'BMI : 25 - 29,9: Béo phì độ I',
                                    'BMI ≥ 30: Béo phì độ II',
                                  ],
                                )
                            : null,
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _InfoRow(
                        label: 'BMR',
                        value: bmr != null
                            ? '${bmr.toStringAsFixed(0)} kcal'
                            : '--',
                        trailing: Icon(Icons.info_outline,
                            size: 18, color: Colors.grey.shade400),
                        onTap: bmr != null
                            ? () {
                                final age = _profile?.birthDate != null
                                    ? DateTime.now()
                                            .difference(_profile!.birthDate!)
                                            .inDays ~/
                                        365
                                    : 0;
                                _showInfoDialog(
                                  title: 'BMR',
                                  definition:
                                      'BMR (Basal Metabolic Rate) là tỉ lệ trao đổi chất cơ bản. Đây là lượng Calo tối thiểu để duy trì các chức năng sống cơ bản ở trạng thái cơ thể hoàn toàn nghỉ ngơi.',
                                  userValueText:
                                      '${bmr.toStringAsFixed(0)} Calo/ngày',
                                  formulaTitle: 'Công thức tính BMR:',
                                  formula:
                                      '(10 x W) + (6.25 x H) - (5 x A) + 5',
                                  notes: [
                                    'W - cân nặng: ${_profile?.weight?.toStringAsFixed(1) ?? '--'} kg',
                                    'H - chiều cao: ${_profile?.height?.toStringAsFixed(0) ?? '--'} cm',
                                    'A - tuổi: $age',
                                    '* NutriFit sử dụng phương trình Mifflin-St Jeor để ước tính BMR.',
                                  ],
                                );
                              }
                            : null,
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _InfoRow(
                        label: 'TDEE',
                        value: tdee != null
                            ? '${tdee.toStringAsFixed(0)} kcal'
                            : '--',
                        trailing: Icon(Icons.info_outline,
                            size: 18, color: Colors.grey.shade400),
                        onTap: tdee != null && bmr != null
                            ? () {
                                final pal =
                                    _getPalFactor(_profile?.activityLevel);
                                _showInfoDialog(
                                  title: 'TDEE',
                                  definition:
                                      'TDEE (Total Daily Energy Expenditure) là tổng năng lượng (Calo) tiêu hao cho các hoạt động trong một ngày - bao gồm các hoạt động sống cơ bản và tất cả các hoạt động thể chất khác. Khi trung bình lượng Calo bạn ăn vào hàng ngày đạt mức TDEE, bạn sẽ giữ cân. Nếu bạn ăn thấp hơn, bạn sẽ giảm cân (và ngược lại).',
                                  userValueText:
                                      '${tdee.toStringAsFixed(0)} Calo/ngày',
                                  formulaTitle: 'Công thức tính TDEE',
                                  formula: 'TDEE (Kcal/ngày) = BMR x PAL',
                                  notes: [
                                    'BMR của bạn: ${bmr.toStringAsFixed(0)} Calo (Tỉ lệ trao đổi chất cơ bản)',
                                    'PAL của bạn: $pal (Hệ số vận động dựa trên mức độ hoạt động)',
                                  ],
                                );
                              }
                            : null,
                      ),
                    ]);
                  }),

                  // ── Section 3: KHÁC ──
                  const _SectionLabel(title: 'KHÁC'),
                  _CardGroup(children: [
                    _InfoRow(
                      label: 'Thực phẩm dị ứng',
                      value: '',
                      onTap: () async {
                        // Extract selected allergies from profile
                        final knownAllergies = <String>[];
                        final allAllergies = _profile?.allergies ?? [];
                        const animalList = [
                          'Tôm',
                          'Cua',
                          'Cá',
                          'Thịt bò',
                          'Trứng',
                          'Sữa bò'
                        ];
                        const plantList = [
                          'Lúa mì',
                          'Đậu phộng (lạc)',
                          'Hạt điều'
                        ];
                        for (final a in allAllergies) {
                          if (animalList.contains(a) ||
                              plantList.contains(a)) {
                            knownAllergies.add(a);
                          }
                        }

                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AllergySelectionScreen(
                              initialAllergies: knownAllergies,
                              initialOtherAllergies:
                                  _profile?.otherAllergies ?? '',
                            ),
                          ),
                        );
                        if (result == true) {
                          await _loadProfile();
                        }
                      },
                    ),
                  ]),
                ],
              ),
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Widgets
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.blueGrey.shade400,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _CardGroup extends StatelessWidget {
  final List<Widget> children;
  const _CardGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 0.8),
        ),
        child: Column(children: children),
      ),
    );
  }
}

/// A single info row inside a card group.
/// Shows [label] on the left, [value] + optional [trailing] on the right.
/// Optionally accepts [onTap] to make the row tappable.
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.label,
    required this.value,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trailingWidget = trailing ??
        Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400);

    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Label stays compact on the left
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(width: 12),

          // Value fills remaining space, right-aligned
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.blueGrey.shade400,
              ),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          trailingWidget,
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: row,
      );
    }
    return row;
  }
}

/// Gender selection option tile used inside the gender BottomSheet.
class _GenderOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderOptionTile({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green.shade300 : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? Colors.green : Colors.grey.shade600,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.black87 : Colors.grey.shade700,
              ),
            ),
            const Spacer(),
            isSelected
                ? const Icon(Icons.check_circle, color: Colors.green, size: 22)
                : Icon(Icons.radio_button_unchecked,
                    color: Colors.grey.shade400, size: 22),
          ],
        ),
      ),
    );
  }
}

/// Activity level option tile used inside _showActivityLevelSheet.
class _ActivityOptionTile extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ActivityOptionTile({
    required this.label,
    this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green.shade300 : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // Activity icon indicator
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.directions_run,
                size: 22,
                color: isSelected ? Colors.green : Colors.grey.shade500,
              ),
            ),
            const SizedBox(width: 12),
            // Label and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.black87 : Colors.grey.shade700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Selection indicator
            isSelected
                ? const Icon(Icons.check_circle, color: Colors.green, size: 22)
                : Icon(Icons.radio_button_unchecked,
                    color: Colors.grey.shade400, size: 22),
          ],
        ),
      ),
    );
  }
}
