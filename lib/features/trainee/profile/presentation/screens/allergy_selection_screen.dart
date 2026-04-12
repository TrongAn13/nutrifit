import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../logic/profile_cubit.dart';

// ── Dark theme constants ────────────────────────────────────────────────────
const Color _kBg = Color(0xFF060708);
const Color _kCardBg = Color(0xFF1A1D23);
const Color _kLime = Color(0xFFE2FF54);
const Color _kBorder = Color(0xFF2A2D35);
const Color _kTextSecondary = Color(0xFF8A8F9D);

/// Screen for selecting food allergies.
/// Users can select from predefined lists or enter custom allergies.
class AllergySelectionScreen extends StatefulWidget {
  final List<String>? initialAllergies;
  final String? initialOtherAllergies;

  const AllergySelectionScreen({
    super.key,
    this.initialAllergies,
    this.initialOtherAllergies,
  });

  @override
  State<AllergySelectionScreen> createState() => _AllergySelectionScreenState();
}

class _AllergySelectionScreenState extends State<AllergySelectionScreen> {
  late final ProfileCubit _profileCubit;

  // Fixed allergy lists
  static const List<String> animalAllergies = [
    'Tôm',
    'Cua',
    'Cá',
    'Thịt bò',
    'Trứng',
    'Sữa bò',
  ];

  static const List<String> plantAllergies = [
    'Lúa mì',
    'Đậu phộng (lạc)',
    'Hạt điều',
  ];

  // State
  late Set<String> selectedAllergies;
  late TextEditingController otherController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _profileCubit = ProfileCubit.fromContext(context);
    selectedAllergies = Set<String>.from(widget.initialAllergies ?? []);
    otherController =
        TextEditingController(text: widget.initialOtherAllergies ?? '');
  }

  @override
  void dispose() {
    _profileCubit.close();
    otherController.dispose();
    super.dispose();
  }

  bool get hasData =>
      selectedAllergies.isNotEmpty || otherController.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final allAllergies = <String>[...selectedAllergies];
      final otherText = otherController.text.trim();
      if (otherText.isNotEmpty) {
        final others = otherText
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        allAllergies.addAll(others);
      }

      await _profileCubit.updateAllergies(allAllergies, otherText);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _kCardBg,
            content: Text('Lỗi: $e', style: GoogleFonts.inter(color: Colors.white)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(
          'Thực phẩm dị ứng',
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAllergyGroup('NHÓM ĐỘNG VẬT', animalAllergies),
                  _buildAllergyGroup('NHÓM THỰC VẬT', plantAllergies),
                  _buildOtherSection(),
                ],
              ),
            ),
          ),
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildAllergyGroup(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 28, bottom: 12),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: _kTextSecondary,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kBorder, width: 0.8),
            ),
            child: Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  _buildAllergyItem(items[i]),
                  if (i < items.length - 1)
                    Divider(height: 1, indent: 20, endIndent: 20, color: _kBorder),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAllergyItem(String item) {
    final isSelected = selectedAllergies.contains(item);

    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedAllergies.remove(item);
          } else {
            selectedAllergies.add(item);
          }
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? _kLime : Colors.white,
                ),
              ),
            ),
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

  Widget _buildOtherSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 28, bottom: 12),
          child: Text(
            'KHÁC',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: _kTextSecondary,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kBorder, width: 0.8),
            ),
            child: TextField(
              controller: otherController,
              maxLines: 4,
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Nhập các thực phẩm bạn dị ứng khác...',
                hintStyle: GoogleFonts.inter(
                  color: Colors.white24,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(20),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      decoration: BoxDecoration(
        color: _kCardBg,
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
            onPressed: _isSaving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: _kLime,
              foregroundColor: _kBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _kBg,
                    ),
                  )
                : Text(
                    hasData ? 'Lưu dị ứng' : 'Không có dị ứng',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
