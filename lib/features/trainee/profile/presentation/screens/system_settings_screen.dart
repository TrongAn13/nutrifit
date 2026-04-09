import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/theme/theme_cubit.dart';
import '../../../../auth/logic/auth_bloc.dart';
import '../../../../auth/logic/auth_event.dart';

// ── Dark theme constants ────────────────────────────────────────────────────
const Color _kBg = Color(0xFF060708);
const Color _kCardBg = Color(0xFF1A1D23);
const Color _kLime = Color(0xFFE2FF54);
const Color _kBorder = Color(0xFF2A2D35);
const Color _kTextSecondary = Color(0xFF8A8F9D);
const Color _kError = Color(0xFFFF5252);

/// System settings screen accessible from the gear icon on the Profile tab.
class SystemSettingsScreen extends StatelessWidget {
  const SystemSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(
          'Cài đặt hệ thống',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section 1: CÀI ĐẶT ──
            _SectionLabel(title: 'Cài đặt'),
            _CardGroup(
              children: [
                _SettingsTile(
                  icon: PhosphorIcons.bell(),
                  title: 'Thông báo',
                  onTap: () {
                    // TODO: Navigate to notification settings
                  },
                ),
                const _CustomDivider(),
                _SettingsTile(
                  icon: PhosphorIcons.globe(),
                  title: 'Ngôn ngữ',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Tiếng Việt',
                        style: GoogleFonts.inter(
                          color: _kTextSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: _kTextSecondary,
                      ),
                    ],
                  ),
                  onTap: () {
                    // TODO: Open language selection
                  },
                ),
                const _CustomDivider(),
                BlocBuilder<ThemeCubit, ThemeMode>(
                  builder: (context, currentMode) {
                    final label = switch (currentMode) {
                      ThemeMode.light => 'Sáng',
                      ThemeMode.dark => 'Tối',
                      ThemeMode.system => 'Hệ thống',
                    };
                    return _SettingsTile(
                      icon: currentMode == ThemeMode.dark ? PhosphorIcons.moon() : PhosphorIcons.sun(),
                      title: 'Theme',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: GoogleFonts.inter(
                              color: _kTextSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: _kTextSecondary,
                          ),
                        ],
                      ),
                      onTap: () => _showThemePicker(context, currentMode),
                    );
                  },
                ),
                const _CustomDivider(),
                _SettingsTile(
                  icon: PhosphorIcons.info(),
                  title: 'Thông tin ứng dụng',
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'NutriFit',
                      applicationVersion: '1.0.0',
                      applicationLegalese: '© 2026 NutriFit',
                    );
                  },
                ),
              ],
            ),

            // ── Section 2: TÀI KHOẢN ──
            _SectionLabel(title: 'Tài khoản'),
            _CardGroup(
              children: [
                _SettingsTile(
                  icon: PhosphorIcons.lockKey(),
                  title: 'Đổi mật khẩu',
                  onTap: () => _showChangePasswordDialog(context),
                ),
                const _CustomDivider(),
                _SettingsTile(
                  icon: PhosphorIcons.userMinus(),
                  iconColor: _kError,
                  title: 'Xóa tài khoản',
                  titleColor: _kError,
                  onTap: () => _showDeleteAccountDialog(context),
                ),
                const _CustomDivider(),
                _SettingsTile(
                  icon: PhosphorIcons.signOut(),
                  iconColor: _kError,
                  title: 'Đăng xuất',
                  titleColor: _kError,
                  showChevron: false,
                  onTap: () {
                    context
                        .read<AuthBloc>()
                        .add(const AuthLogoutRequested());
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Theme Picker BottomSheet ──

  void _showThemePicker(BuildContext context, ThemeMode current) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121419),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Chọn giao diện',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                _ThemeOption(
                  icon: PhosphorIcons.sun(),
                  label: 'Sáng',
                  isSelected: current == ThemeMode.light,
                  onTap: () {
                    context.read<ThemeCubit>().setTheme(ThemeMode.light);
                    Navigator.pop(sheetContext);
                  },
                ),
                _ThemeOption(
                  icon: PhosphorIcons.moon(),
                  label: 'Tối',
                  isSelected: current == ThemeMode.dark,
                  onTap: () {
                    context.read<ThemeCubit>().setTheme(ThemeMode.dark);
                    Navigator.pop(sheetContext);
                  },
                ),
                _ThemeOption(
                  icon: PhosphorIcons.gearSix(),
                  label: 'Theo hệ thống',
                  isSelected: current == ThemeMode.system,
                  onTap: () {
                    context.read<ThemeCubit>().setTheme(ThemeMode.system);
                    Navigator.pop(sheetContext);
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Change Password Dialog ──

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: _kCardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Đổi mật khẩu',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Chức năng đổi mật khẩu sẽ gửi email xác nhận đến địa chỉ email của bạn.',
            style: GoogleFonts.inter(color: _kTextSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Hủy',
                style: GoogleFonts.inter(color: _kTextSecondary, fontWeight: FontWeight.w600),
              ),
            ),
            FilledButton(
              onPressed: () {
                // TODO: Trigger password reset email via AuthBloc
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: _kCardBg,
                    content: Text(
                      'Đã gửi email đổi mật khẩu!',
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: _kLime,
                foregroundColor: _kBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Gửi email', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // ── Delete Account Dialog ──

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: _kCardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: Icon(PhosphorIcons.warningCircle(), color: _kError, size: 48),
          title: Text(
            'Xóa tài khoản vĩnh viễn?',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Hành động này KHÔNG THỂ HOÀN TÁC. '
            'Toàn bộ dữ liệu tập luyện, dinh dưỡng và hồ sơ cá nhân '
            'của bạn sẽ bị xóa vĩnh viễn.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: _kTextSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Hủy',
                style: GoogleFonts.inter(color: _kTextSecondary, fontWeight: FontWeight.w600),
              ),
            ),
            FilledButton(
              onPressed: () {
                // TODO: Trigger account deletion
                Navigator.pop(ctx);
              },
              style: FilledButton.styleFrom(
                backgroundColor: _kError,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Xóa tài khoản', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
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
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: _kTextSecondary,
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
          color: _kCardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kBorder, width: 0.8),
        ),
        child: Column(children: children),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final Color? titleColor;
  final Widget? trailing;
  final bool showChevron;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    this.iconColor,
    required this.title,
    this.titleColor,
    this.trailing,
    this.showChevron = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? Colors.white).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor ?? Colors.white, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: titleColor ?? Colors.white,
          fontSize: 15,
        ),
      ),
      trailing: trailing ??
          (showChevron
              ? const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: _kTextSecondary,
                )
              : null),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: isSelected ? _kLime : Colors.white),
      title: Text(
        label,
        style: GoogleFonts.inter(
          color: isSelected ? _kLime : Colors.white,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: _kLime)
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }
}

class _CustomDivider extends StatelessWidget {
  const _CustomDivider();
  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, indent: 60, color: _kBorder);
  }
}
