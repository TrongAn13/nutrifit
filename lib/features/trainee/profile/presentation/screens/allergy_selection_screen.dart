import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../data/repositories/profile_repository.dart';

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
  final _repo = ProfileRepository();

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
    selectedAllergies = Set<String>.from(widget.initialAllergies ?? []);
    otherController =
        TextEditingController(text: widget.initialOtherAllergies ?? '');
  }

  @override
  void dispose() {
    otherController.dispose();
    super.dispose();
  }

  bool get hasData =>
      selectedAllergies.isNotEmpty || otherController.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      // Combine selected allergies with other allergies text
      final allAllergies = <String>[...selectedAllergies];
      final otherText = otherController.text.trim();
      if (otherText.isNotEmpty) {
        // Split by comma and add each trimmed item
        final others = otherText
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        allAllergies.addAll(others);
      }

      await _repo.updateAllergies(allAllergies, otherText);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Thực phẩm dị ứng',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Animal allergies section
                  _buildAllergyGroup('NHÓM ĐỘNG VẬT', animalAllergies),

                  // Plant allergies section
                  _buildAllergyGroup('NHÓM THỰC VẬT', plantAllergies),

                  // Other section
                  _buildOtherSection(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bottom action
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildAllergyGroup(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
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
        ),

        // Items container
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200, width: 0.8),
            ),
            child: Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  _buildAllergyItem(items[i]),
                  if (i < items.length - 1)
                    const Divider(height: 1, indent: 16, endIndent: 16),
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
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            isSelected
                ? Icon(Icons.check_circle, color: AppColors.success, size: 22)
                : Icon(Icons.radio_button_unchecked,
                    color: Colors.grey.shade400, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 8),
          child: Text(
            'KHÁC',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.blueGrey.shade400,
              letterSpacing: 1.2,
            ),
          ),
        ),

        // TextField container
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200, width: 0.8),
            ),
            child: TextField(
              controller: otherController,
              maxLines: 3,
              minLines: 3,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Nhập các thực phẩm bạn dị ứng, cách nhau bằng dấu phẩy',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: hasData
            ? SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
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
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Lưu',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              )
            : SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.success,
                          ),
                        )
                      : Text(
                          'Không dị ứng với thực phẩm nào',
                          style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
      ),
    );
  }
}
