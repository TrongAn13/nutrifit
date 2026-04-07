import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/routes/app_router.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design Tokens
// ─────────────────────────────────────────────────────────────────────────────

const Color _kAccent = Color(0xFF92A3FD);
const Color _kAccentSecondary = Color(0xFF9DCEFF);
const Color _kFieldBg = Color(0xFFF7F8F8);

/// Screen 1 of the post-registration profile setup flow.
///
/// Collects gender, date of birth, weight, and height from the trainee.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  // String? _gender;
  // DateTime? _dob;
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  String _gender = 'male';
  DateTime? _dob;

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  /// Opens a date picker and stores the selected birth date.
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1940),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: _kAccent,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dob = picked);
    }
  }

  /// Validates fields and navigates to the goal selection screen.
  void _onNext() {
    if (_dob == null) {
      _showSnack('Vui lòng chọn ngày sinh');
      return;
    }
    final weight = double.tryParse(_weightCtrl.text.trim());
    final height = double.tryParse(_heightCtrl.text.trim());
    if (weight == null || weight <= 0) {
      _showSnack('Vui lòng nhập cân nặng hợp lệ');
      return;
    }
    if (height == null || height <= 0) {
      _showSnack('Vui lòng nhập chiều cao hợp lệ');
      return;
    }

    context.go(AppRouter.goalSelection, extra: {
      'gender': _gender,
      'birthDate': _dob,
      'weight': weight,
      'height': height,
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // ── Illustration ──
              SvgPicture.asset(
                'assets/images/profile_setup/infor.svg',
                height: MediaQuery.of(context).size.height * 0.35,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),

              // ── Header ──
              Text(
                "Let's complete your profile",
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'It will help us to know more about you!',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // ── Gender Dropdown ──
              _buildGenderToggle(),
              const SizedBox(height: 8),

              // ── Date of Birth ──
              _buildDateField(),
              const SizedBox(height: 8),

              // ── Weight ──
              _buildUnitField(
                controller: _weightCtrl,
                hint: 'Your Weight',
                icon: Icons.monitor_weight_outlined,
                unit: 'KG',
              ),
              const SizedBox(height: 8),

              // ── Height ──
              _buildUnitField(
                controller: _heightCtrl,
                hint: 'Your Height',
                icon: Icons.height_rounded,
                unit: 'CM',
              ),
              const SizedBox(height: 24),

              // ── Next Button ──
              _buildNextButton(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Form Widgets
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildGenderToggle() {
    return Row(
      children: [
        // ── Nút chọn Nam ──
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _gender = 'male'),
            child: Container(
              height: 58,
              decoration: BoxDecoration(
                color: _gender == 'male' ? Colors.blue.withOpacity(0.1) : _kFieldBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _gender == 'male' ? Colors.blue : Colors.grey.shade300,
                  width: _gender == 'male' ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.male_rounded,
                    color: _gender == 'male' ? Colors.blue : Colors.grey.shade400,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Male',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: _gender == 'male' ? FontWeight.w600 : FontWeight.w400,
                      color: _gender == 'male' ? Colors.blue : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 14),

        // ── Nút chọn Nữ ──
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _gender = 'female'),
            child: Container(
              height: 58,
              decoration: BoxDecoration(
                color: _gender == 'female' ? Colors.pink.withOpacity(0.1) : _kFieldBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _gender == 'female' ? Colors.pinkAccent : Colors.grey.shade300,
                  width: _gender == 'female' ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.female_rounded,
                    color: _gender == 'female' ? Colors.pinkAccent : Colors.grey.shade400,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Female',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: _gender == 'female' ? FontWeight.w600 : FontWeight.w400,
                      color: _gender == 'female' ? Colors.pinkAccent : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  void _showDatePickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Nền trong suốt để bo góc đẹp hơn
      isScrollControlled: true,
      builder: (BuildContext builder) {
        return Container(
          height: 320,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)), // Bo góc to hơn
          ),
          child: Column(
            children: [
              // 1. Thanh Drag Handle (Vạch xám nhỏ ở trên cùng)
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 1),

              // 2. Header với Nút "Xong" được bo tròn
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Date of Birth',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.blue.withOpacity(0.1), // Nền xanh nhạt
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                        minimumSize: const Size(0, 36),
                      ),
                      onPressed: () {
                        if (_dob == null) {
                          setState(() {
                            _dob = DateTime(2000, 1, 1);
                          });
                        }
                        Navigator.pop(context); // Đóng bảng
                      },
                      child: Text(
                        'Done',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: Colors.grey.shade100), // Đường viền mờ phân cách

              // 3. Thanh cuộn (Bọc trong Theme để đổi Font chữ)
              Expanded(
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    textTheme: CupertinoTextThemeData(
                      // Ép font Inter vào trong thanh cuộn
                      dateTimePickerTextStyle: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: _dob ?? DateTime(2000, 1, 1),
                    maximumDate: DateTime.now(),
                    minimumYear: 1950,
                    onDateTimeChanged: (DateTime newDate) {
                      setState(() => _dob = newDate);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  Widget _buildDateField() {
    // Ép kiểu hiển thị thành dạng DD/MM/YYYY
    final String displayDate = _dob == null
        ? 'Date of Birth'
        : '${_dob!.day.toString().padLeft(2, '0')}/${_dob!.month.toString().padLeft(2, '0')}/${_dob!.year}';

    return GestureDetector(
      onTap: _showDatePickerSheet, // Bấm vào là gọi cái bảng cuộn lên
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50, // Khớp nền với Weight/Height
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month_outlined, color: Colors.grey.shade400, size: 20),
            const SizedBox(width: 12),
            Text(
              displayDate,
              style: GoogleFonts.inter(
                fontSize: 14,
                // Nếu chưa chọn thì màu nhạt (Hint), chọn rồi thì màu đậm
                color: _dob == null ? Colors.grey.shade400 : Colors.grey.shade800,
                fontWeight: _dob == null ? FontWeight.w400 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required String unit,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade800),
            decoration: InputDecoration(
              filled: true,
              fillColor: _kFieldBg,
              prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
              hintText: hint,
              hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey[400]),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.blue, width: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kAccent, _kAccentSecondary],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              unit,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNextButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(colors: [_kAccent, _kAccentSecondary]),
        boxShadow: [
          BoxShadow(
            color: _kAccent.withAlpha(80),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _onNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Next',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}
