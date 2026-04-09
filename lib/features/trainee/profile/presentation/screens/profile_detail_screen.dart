import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:vertical_weight_slider/vertical_weight_slider.dart';

import '../../../../auth/data/models/user_model.dart';
import '../../data/repositories/profile_repository.dart';
import 'allergy_selection_screen.dart';

// ── Dark theme constants ────────────────────────────────────────────────────
const Color _kBg = Color(0xFF060708);
const Color _kCardBg = Color(0xFF1A1D23);
const Color _kLime = Color(0xFFE2FF54);
const Color _kBorder = Color(0xFF2A2D35);
const Color _kTextSecondary = Color(0xFF8A8F9D);
const Color _kError = Color(0xFFFF5252);

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
        backgroundColor: _kCardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _kBorder),
        ),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
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
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                definition,
                style: GoogleFonts.inter(
                  color: _kTextSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // User value section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _kLime.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$title của bạn: $userValueText',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: _kLime,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Formula section
              Text(
                formulaTitle,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  formula,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Notes section
              Text(
                'Chú thích:',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ...notes.map((note) => Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: _kLime)),
                    Expanded(
                      child: Text(
                        note,
                        style: GoogleFonts.inter(
                          color: _kTextSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Đóng',
              style: GoogleFonts.inter(
                color: _kLime,
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
      backgroundColor: const Color(0xFF121419),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return Padding(
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
              // ── Handle ──
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // ── Header ──
              Row(
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetCtx),
                    icon: const Icon(Icons.close, color: Colors.white54),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Label ──
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kTextSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),

              // ── Text Field ──
              Container(
                decoration: BoxDecoration(
                  color: _kBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _kBorder),
                ),
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: keyboardType,
                  style: GoogleFonts.inter(color: Colors.white),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Nhập $title...',
                    hintStyle: GoogleFonts.inter(color: Colors.white24),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Save Button ──
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: () async {
                    final value = controller.text.trim();
                    if (value.isEmpty) return;
                    Navigator.pop(sheetCtx);
                    await onSave(value);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _kLime,
                    foregroundColor: _kBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Lưu thay đổi',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
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
      backgroundColor: const Color(0xFF121419),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   // Handle
                   Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // ── Header ──
                  Row(
                    children: [
                      const SizedBox(width: 40),
                      Expanded(
                        child: Text(
                          'Giới tính sinh học',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetCtx),
                        icon: const Icon(Icons.close, color: Colors.white54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _GenderOptionTile(
                    icon: PhosphorIcons.genderFemale(),
                    label: 'Nữ',
                    isSelected: selected == 'female',
                    onTap: () => setSheetState(() => selected = 'female'),
                  ),
                  const SizedBox(height: 12),

                  _GenderOptionTile(
                    icon: PhosphorIcons.genderMale(),
                    label: 'Nam',
                    isSelected: selected == 'male',
                    onTap: () => setSheetState(() => selected = 'male'),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
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
                                    backgroundColor: _kCardBg,
                                    content: Text('Lỗi: $e', style: const TextStyle(color: Colors.white))),
                              );
                            }
                          }
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _kLime,
                        foregroundColor: _kBg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Lưu',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
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
    DateTime selectedDate = _profile?.birthDate ?? DateTime(2000, 1, 1);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121419),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Row(
                    children: [
                      const SizedBox(width: 40),
                      Expanded(
                        child: Text(
                          'Ngày sinh',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetCtx),
                        icon: const Icon(Icons.close, color: Colors.white54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    height: 220,
                    child: CupertinoTheme(
                      data: const CupertinoThemeData(
                        textTheme: CupertinoTextThemeData(
                          dateTimePickerTextStyle: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                      ),
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
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
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
                              SnackBar(content: Text('Lỗi: $e')),
                            );
                          }
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _kLime,
                        foregroundColor: _kBg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text('Lưu',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 24),
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
    final int initialIndex = (_profile?.height?.toInt() ?? 170) - minHeight;
    int selectedHeight = _profile?.height?.toInt() ?? 170;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121419),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Text('Chiều cao',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetCtx),
                    icon: const Icon(Icons.close, color: Colors.white54),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              SizedBox(
                height: 220,
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(initialItem: initialIndex),
                  itemExtent: 44,
                  onSelectedItemChanged: (index) {
                    selectedHeight = minHeight + index;
                  },
                  children: List.generate(
                    maxHeight - minHeight + 1,
                    (i) => Center(
                      child: Text(
                        '${minHeight + i} cm',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 54,
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
                          SnackBar(content: Text('Lỗi: $e')),
                        );
                      }
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _kLime,
                    foregroundColor: _kBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text('Lưu',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BottomSheet: Weight Ruler
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
      backgroundColor: const Color(0xFF121419),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const SizedBox(width: 40),
                        Expanded(
                          child: Text('Cân nặng',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                        IconButton(
                          onPressed: () {
                            controller.dispose();
                            Navigator.pop(sheetCtx);
                          },
                          icon: const Icon(Icons.close, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  Text(
                    '${currentWeight.toStringAsFixed(1)} kg',
                    style: GoogleFonts.inter(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: _kLime,
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    height: 80,
                    child: VerticalWeightSlider(
                      isVertical: false,
                      controller: controller,
                      decoration: const PointerDecoration(
                        width: 40.0,
                        height: 3.0,
                        largeColor: Colors.white70,
                        mediumColor: Colors.white38,
                        smallColor: Colors.white12,
                        gap: 16.0,
                      ),
                      onChanged: (double value) {
                        setSheetState(() => currentWeight = value);
                      },
                      indicator: Container(
                        height: 3.0,
                        width: 100.0,
                        alignment: Alignment.centerLeft,
                        color: _kLime,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        onPressed: () async {
                          final w = currentWeight;
                          controller.dispose();
                          Navigator.pop(sheetCtx);
                          try {
                            await _repo.updateProfile(
                              name: _profile?.name ?? '',
                              weight: double.parse(w.toStringAsFixed(1)),
                            );
                            await _loadProfile();
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Lỗi: $e')),
                              );
                            }
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: _kLime,
                          foregroundColor: _kBg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text('Lưu',
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
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

  void _showActivityLevelSheet({
    required String title,
    required List<Map<String, String>> options,
    required String? currentValue,
    required Future<void> Function(String) onSave,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121419),
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
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Row(
                      children: [
                        const SizedBox(width: 40),
                        Expanded(
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetCtx),
                          icon: const Icon(Icons.close, color: Colors.white54),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

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

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        onPressed: selectedValue != null
                            ? () async {
                                Navigator.pop(sheetCtx);
                                await onSave(selectedValue!);
                              }
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: _kLime,
                          foregroundColor: _kBg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Lưu',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
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
  // Save Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _saveName(String value) async {
    try {
      await _repo.updateProfile(name: value);
      await _loadProfile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  Future<void> _savePhone(String value) async {
    try {
      await _repo.updateProfile(name: _profile?.name ?? '', phone: value);
      await _loadProfile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  Future<void> _saveEmail(String value) async {
    try {
      await _repo.updateProfile(name: _profile?.name ?? '');
      await _loadProfile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  Future<void> _saveWorkActivity(String value) async {
    try {
      await _repo.updateProfile(name: _profile?.name ?? '', workActivity: value);
      await _loadProfile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  Future<void> _saveHomeActivity(String value) async {
    try {
      await _repo.updateProfile(name: _profile?.name ?? '', homeActivity: value);
      await _loadProfile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  Future<void> _saveActivityLevel(String value) async {
    try {
      await _repo.updateProfile(name: _profile?.name ?? '', activityLevel: value);
      await _loadProfile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  Future<void> _saveGoal(String value) async {
    try {
      await _repo.updateProfile(name: _profile?.name ?? '', goal: value);
      await _loadProfile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Build
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(
          'Hồ sơ cá nhân',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _kLime))
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _kLime, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 36,
                            backgroundColor: _kCardBg,
                            backgroundImage: user?.photoURL != null
                                ? NetworkImage(user!.photoURL!)
                                : null,
                            child: user?.photoURL == null
                                ? Icon(PhosphorIcons.user(), size: 36, color: _kLime)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _profile?.name ?? 'Người dùng',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Thành viên từ ${_formatDate(_profile?.createdAt)}',
                                style: GoogleFonts.inter(
                                  color: _kTextSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          style: IconButton.styleFrom(
                            backgroundColor: _kCardBg,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: _kBorder),
                            ),
                          ),
                          icon: Icon(PhosphorIcons.pencilLine(), color: Colors.white, size: 20),
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
                          Clipboard.setData(ClipboardData(text: _profile?.uid ?? ''));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                backgroundColor: _kCardBg,
                                content: Text('Đã copy ID', style: GoogleFonts.inter(color: Colors.white))),
                          );
                        },
                        child: Icon(PhosphorIcons.copy(), size: 18, color: _kLime),
                      ),
                    ),
                    const _CustomDivider(),
                    _InfoRow(
                      label: 'Tên',
                      value: _profile?.name ?? '--',
                      onTap: () => _showTextInputSheet(
                        title: 'Cập nhật tên',
                        label: 'Tên hiển thị',
                        initialValue: _profile?.name ?? '',
                        onSave: _saveName,
                      ),
                    ),
                    const _CustomDivider(),
                    const _InfoRow(label: 'Gói đăng ký', value: 'Gói Premium'),
                    const _CustomDivider(),
                    _InfoRow(
                      label: 'Điện thoại',
                      value: _profile?.phone ?? '--',
                      onTap: () => _showTextInputSheet(
                        title: 'Cập nhật điện thoại',
                        label: 'Số điện thoại',
                        initialValue: _profile?.phone ?? '',
                        keyboardType: TextInputType.phone,
                        onSave: _savePhone,
                      ),
                    ),
                    const _CustomDivider(),
                    _InfoRow(
                      label: 'Email',
                      value: _profile?.email ?? '--',
                      onTap: () => _showTextInputSheet(
                        title: 'Cập nhật email',
                        label: 'Địa chỉ email',
                        initialValue: _profile?.email ?? '',
                        keyboardType: TextInputType.emailAddress,
                        onSave: _saveEmail,
                      ),
                    ),
                  ]),

                  // ── Section 2: THÔNG TIN CƠ BẢN ──
                  const _SectionLabel(title: 'THÔNG TIN CƠ BẢN'),
                  Builder(builder: (ctx) {
                    final bmi = _calcBmi(_profile?.height, _profile?.weight);
                    final bmr = _calcBmr(_profile?.height, _profile?.weight, _profile?.birthDate, _profile?.gender);
                    final tdee = _calcTdee(bmr, _profile?.activityLevel);

                    return _CardGroup(children: [
                      _InfoRow(
                        label: 'Giới tính',
                        value: _formatGender(_profile?.gender),
                        onTap: _showGenderSelectionSheet,
                      ),
                      const _CustomDivider(),
                      _InfoRow(
                        label: 'Ngày sinh',
                        value: _formatDate(_profile?.birthDate),
                        onTap: _showDatePickerSheet,
                      ),
                      const _CustomDivider(),
                      _InfoRow(
                        label: 'Chiều cao',
                        value: _profile?.height != null ? '${_profile!.height!.toStringAsFixed(0)} cm' : '--',
                        onTap: _showHeightPickerSheet,
                      ),
                      const _CustomDivider(),
                      _InfoRow(
                        label: 'Cân nặng',
                        value: _profile?.weight != null ? '${_profile!.weight!.toStringAsFixed(1)} kg' : '--',
                        onTap: _showWeightRulerSheet,
                      ),
                      const _CustomDivider(),
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
                      const _CustomDivider(),
                      _InfoRow(
                        label: 'Công việc',
                        value: _formatWorkActivity(_profile?.workActivity),
                        onTap: () => _showActivityLevelSheet(
                          title: 'Mức độ công việc',
                          options: const [
                            {'value': 'sedentary', 'label': 'Ít vận động', 'subtitle': 'Ngồi máy tính cả ngày'},
                            {'value': 'light', 'label': 'Vận động nhẹ', 'subtitle': 'Đi lại nhẹ nhàng'},
                            {'value': 'moderate', 'label': 'Trung bình', 'subtitle': 'Đứng nhiều, đi lại liên tục'},
                            {'value': 'active', 'label': 'Vận động nhiều', 'subtitle': 'Lao động chân tay nặng'},
                          ],
                          currentValue: _profile?.workActivity,
                          onSave: _saveWorkActivity,
                        ),
                      ),
                      const _CustomDivider(),
                      _InfoRow(
                        label: 'Hoạt động nhà',
                        value: _formatHomeActivity(_profile?.homeActivity),
                        onTap: () => _showActivityLevelSheet(
                          title: 'Hoạt động ở nhà',
                          options: const [
                            {'value': 'sedentary', 'label': 'Ít hoạt động', 'subtitle': 'Nghỉ ngơi là chính'},
                            {'value': 'light', 'label': 'Nhẹ nhàng', 'subtitle': 'Việc nhà cơ bản'},
                            {'value': 'moderate', 'label': 'Linh hoạt', 'subtitle': 'Dọn dẹp, nấu ăn thường xuyên'},
                            {'value': 'active', 'label': 'Năng nổ', 'subtitle': 'Chăm sóc gia đình bận rộn'},
                          ],
                          currentValue: _profile?.homeActivity,
                          onSave: _saveHomeActivity,
                        ),
                      ),
                      const _CustomDivider(),
                      _InfoRow(
                        label: 'Tập luyện',
                        value: _formatActivityLevel(_profile?.activityLevel),
                        onTap: () => _showActivityLevelSheet(
                          title: 'Tập luyện thể chất',
                          options: const [
                            {'value': 'sedentary', 'label': 'Không tập luyện', 'subtitle': 'Ngồi nhiều, không tập thể dục'},
                            {'value': 'light', 'label': 'Tập luyện nhẹ', 'subtitle': '1-2 buổi/tuần'},
                            {'value': 'moderate', 'label': 'Trung bình', 'subtitle': '3-4 buổi/tuần'},
                            {'value': 'active', 'label': 'Tích cực', 'subtitle': '5-6 buổi/tuần'},
                            {'value': 'very_active', 'label': 'Cường độ cao', 'subtitle': 'Tập luyện mỗi ngày'},
                          ],
                          currentValue: _profile?.activityLevel,
                          onSave: _saveActivityLevel,
                        ),
                      ),
                      const _CustomDivider(),
                      _InfoRow(
                        label: 'Chỉ số BMI',
                        value: bmi != null ? bmi.toStringAsFixed(1) : '--',
                        trailing: Icon(PhosphorIcons.info(), size: 18, color: _kLime),
                        onTap: bmi != null ? () => _showInfoDialog(
                          title: 'BMI',
                          definition: 'BMI (Body Mass Index) là chỉ số khối cơ thể, đánh giá mức độ cân đối giữa chiều cao và cân nặng.',
                          userValueText: bmi.toStringAsFixed(1),
                          formulaTitle: 'Công thức',
                          formula: 'BMI = W (kg) / H² (m)',
                          notes: [
                            'Dưới 18.5: Thiếu cân',
                            '18.5 - 22.9: Bình thường',
                            '23.0 - 24.9: Tiền béo phì',
                            'Trên 25.0: Béo phì',
                          ],
                        ) : null,
                      ),
                      const _CustomDivider(),
                      _InfoRow(
                        label: 'Chỉ số BMR',
                        value: bmr != null ? '${bmr.toStringAsFixed(0)} kcal' : '--',
                        trailing: Icon(PhosphorIcons.info(), size: 18, color: _kLime),
                        onTap: bmr != null ? () => _showInfoDialog(
                          title: 'BMR',
                          definition: 'BMR là mức trao đổi chất cơ bản, lượng calo cần thiết để duy trì sự sống khi cơ thể nghỉ ngơi hoàn toàn.',
                          userValueText: '${bmr.toStringAsFixed(0)} kcal/ngày',
                          formulaTitle: 'Công thức Mifflin-St Jeor',
                          formula: '(10 × W) + (6.25 × H) - (5 × A) + s',
                          notes: ['Nam: s = +5', 'Nữ: s = -161', 'W: Cân nặng, H: Chiều cao, A: Tuổi'],
                        ) : null,
                      ),
                      const _CustomDivider(),
                      _InfoRow(
                        label: 'Chỉ số TDEE',
                        value: tdee != null ? '${tdee.toStringAsFixed(0)} kcal' : '--',
                        trailing: Icon(PhosphorIcons.info(), size: 18, color: _kLime),
                        onTap: tdee != null ? () => _showInfoDialog(
                          title: 'TDEE',
                          definition: 'TDEE là tổng năng lượng tiêu hao mỗi ngày, bao gồm cả BMR và các hoạt động thể chất.',
                          userValueText: '${tdee.toStringAsFixed(0)} kcal/ngày',
                          formulaTitle: 'Cách tính',
                          formula: 'TDEE = BMR × PAL',
                          notes: ['PAL là hệ số hoạt động thể chất của bạn.'],
                        ) : null,
                      ),
                    ]);
                  }),

                  // ── Section 3: KHÁC ──
                  const _SectionLabel(title: 'KHÁC'),
                  _CardGroup(children: [
                    _InfoRow(
                      label: 'Dị ứng thực phẩm',
                      value: _profile?.allergies != null && (_profile!.allergies?.isNotEmpty ?? false) 
                          ? '${_profile!.allergies!.length} loại' 
                          : 'Không có',
                      onTap: () async {
                         final knownAllergies = <String>[];
                         final allAllergies = _profile?.allergies ?? [];
                         // This part preserves existing filter logic
                         const animalList = ['Tôm','Cua','Cá','Thịt bò','Trứng','Sữa bò'];
                         const plantList = ['Lúa mì','Đậu phộng (lạc)','Hạt điều'];
                         for (final a in allAllergies) {
                           if (animalList.contains(a) || plantList.contains(a)) knownAllergies.add(a);
                         }

                         final res = await Navigator.push<bool>(
                           context,
                           MaterialPageRoute(
                             builder: (_) => AllergySelectionScreen(
                               initialAllergies: knownAllergies,
                               initialOtherAllergies: _profile?.otherAllergies ?? '',
                             ),
                           ),
                         );
                         if (res == true) await _loadProfile();
                      },
                    ),
                  ]),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// UI Sub-components
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 28, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: _kTextSecondary,
          letterSpacing: 1.5,
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
          color: _kCardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kBorder, width: 0.8),
        ),
        child: Column(children: children),
      ),
    );
  }
}

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
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                color: _kTextSecondary,
                fontSize: 15,
              ),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          trailing ?? const Icon(Icons.chevron_right, size: 18, color: _kTextSecondary),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: row,
      );
    }
    return row;
  }
}

class _CustomDivider extends StatelessWidget {
  const _CustomDivider();
  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, indent: 20, endIndent: 20, color: _kBorder);
  }
}

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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? _kLime.withOpacity(0.1) : _kBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _kLime : _kBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? _kLime : Colors.white70, size: 24),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? _kLime : Colors.white,
              ),
            ),
            const Spacer(),
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? _kLime : Colors.white24,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? _kLime.withOpacity(0.1) : _kBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _kLime : _kBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? _kLime : Colors.white,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: _kTextSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? _kLime : Colors.white24,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
