import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/profile_repository.dart';

/// Screen for editing the user's personal profile.
/// Saves updated fields directly to the Firestore `users` collection.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = ProfileRepository();

  // Controllers
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _weightCtrl;

  DateTime? _birthDate;
  String? _gender;
  String? _activityLevel;
  String? _goal;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _cityCtrl = TextEditingController();
    _heightCtrl = TextEditingController();
    _weightCtrl = TextEditingController();
    _loadProfile();
  }

  /// Fetch current profile and populate form fields.
  Future<void> _loadProfile() async {
    try {
      final profile = await _repo.getProfile();
      if (profile != null && mounted) {
        setState(() {
          _nameCtrl.text = profile.name;
          _phoneCtrl.text = profile.phone ?? '';
          _cityCtrl.text = profile.city ?? '';
          _heightCtrl.text = profile.height?.toString() ?? '';
          _weightCtrl.text = profile.weight?.toString() ?? '';
          _birthDate = profile.birthDate;
          _gender = profile.gender;
          _activityLevel = profile.activityLevel;
          _goal = profile.goal;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Validate and save profile to Firestore.
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await _repo.updateProfile(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
        birthDate: _birthDate,
        gender: _gender,
        city: _cityCtrl.text.trim().isNotEmpty ? _cityCtrl.text.trim() : null,
        height: double.tryParse(_heightCtrl.text.trim()),
        weight: double.tryParse(_weightCtrl.text.trim()),
        activityLevel: _activityLevel,
        goal: _goal,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu hồ sơ thành công!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Name ──
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Họ và tên',
                        prefixIcon: Icon(Icons.person_outlined),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Vui lòng nhập tên'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // ── Phone ──
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    // ── Birth Date ──
                    _DatePickerField(
                      label: 'Ngày sinh',
                      selectedDate: _birthDate,
                      onDateSelected: (d) => setState(() => _birthDate = d),
                    ),
                    const SizedBox(height: 16),

                    // ── Gender ──
                    DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: const InputDecoration(
                        labelText: 'Giới tính',
                        prefixIcon: Icon(Icons.wc_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text('Nam')),
                        DropdownMenuItem(value: 'female', child: Text('Nữ')),
                        DropdownMenuItem(value: 'other', child: Text('Khác')),
                      ],
                      onChanged: (v) => setState(() => _gender = v),
                    ),
                    const SizedBox(height: 16),

                    // ── City ──
                    TextFormField(
                      controller: _cityCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Thành phố',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Divider (Health section) ──
                    Divider(color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Text(
                      'CHỈ SỐ SỨC KHỎE',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Height ──
                    TextFormField(
                      controller: _heightCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Chiều cao (cm)',
                        prefixIcon: Icon(Icons.height_outlined),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    // ── Weight ──
                    TextFormField(
                      controller: _weightCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Cân nặng (kg)',
                        prefixIcon: Icon(Icons.monitor_weight_outlined),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    // ── Activity Level ──
                    DropdownButtonFormField<String>(
                      value: _activityLevel,
                      decoration: const InputDecoration(
                        labelText: 'Mức độ vận động',
                        prefixIcon: Icon(Icons.directions_run_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'sedentary',
                            child: Text('Ít vận động')),
                        DropdownMenuItem(
                            value: 'light',
                            child: Text('Vận động nhẹ (1-3 ngày/tuần)')),
                        DropdownMenuItem(
                            value: 'moderate',
                            child: Text('Vận động vừa (3-5 ngày/tuần)')),
                        DropdownMenuItem(
                            value: 'active',
                            child: Text('Vận động nhiều (6-7 ngày/tuần)')),
                        DropdownMenuItem(
                            value: 'very_active',
                            child: Text('Rất nhiều (Ngày 2 lần)')),
                      ],
                      onChanged: (v) => setState(() => _activityLevel = v),
                    ),
                    const SizedBox(height: 16),

                    // ── Goal ──
                    DropdownButtonFormField<String>(
                      value: _goal,
                      decoration: const InputDecoration(
                        labelText: 'Mục tiêu',
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'lose_weight',
                            child: Text('Giảm cân')),
                        DropdownMenuItem(
                            value: 'maintain', child: Text('Giữ cân')),
                        DropdownMenuItem(
                            value: 'gain_muscle',
                            child: Text('Tăng cơ')),
                      ],
                      onChanged: (v) => setState(() => _goal = v),
                    ),
                    const SizedBox(height: 32),

                    // ── Save Button ──
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : _saveProfile,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                            _isSaving ? 'Đang lưu...' : 'Lưu hồ sơ'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Date Picker Field
// ─────────────────────────────────────────────────────────────────────────────

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const _DatePickerField({
    required this.label,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final displayText = selectedDate != null
        ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
        : '';

    return TextFormField(
      readOnly: true,
      initialValue: displayText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.cake_outlined),
        suffixIcon: Icon(
          Icons.calendar_today,
          size: 18,
          color: colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime(now.year - 20),
          firstDate: DateTime(1940),
          lastDate: now,
          helpText: 'Chọn ngày sinh',
          cancelText: 'Hủy',
          confirmText: 'Chọn',
        );
        if (picked != null) onDateSelected(picked);
      },
    );
  }
}
