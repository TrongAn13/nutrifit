import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/theme_cubit.dart';
import '../../../../auth/logic/auth_bloc.dart';
import '../../../../auth/logic/auth_event.dart';

/// System settings screen accessible from the gear icon on the Profile tab.
///
/// Sections:
///   1. General — notifications, language, theme, about
///   2. Account — change password, delete account, logout
class SystemSettingsScreen extends StatelessWidget {
  const SystemSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Cài đặt hệ thống',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                  icon: Icons.notifications_outlined,
                  title: 'Thông báo',
                  onTap: () {
                    // TODO: Navigate to notification settings
                  },
                ),
                const Divider(height: 1, indent: 56),
                _SettingsTile(
                  icon: Icons.language,
                  title: 'Ngôn ngữ',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Tiếng Việt',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                  onTap: () {
                    // TODO: Open language selection
                  },
                ),
                const Divider(height: 1, indent: 56),
                BlocBuilder<ThemeCubit, ThemeMode>(
                  builder: (context, currentMode) {
                    final label = switch (currentMode) {
                      ThemeMode.light => 'Sáng',
                      ThemeMode.dark => 'Tối',
                      ThemeMode.system => 'Hệ thống',
                    };
                    return _SettingsTile(
                      icon: Icons.dark_mode_outlined,
                      title: 'Theme',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                      onTap: () => _showThemePicker(context, currentMode),
                    );
                  },
                ),
                const Divider(height: 1, indent: 56),
                _SettingsTile(
                  icon: Icons.info_outline,
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
                  icon: Icons.lock_outline,
                  title: 'Đổi mật khẩu',
                  onTap: () => _showChangePasswordDialog(context),
                ),
                const Divider(height: 1, indent: 56),
                _SettingsTile(
                  icon: Icons.delete_outline,
                  iconColor: AppColors.error,
                  title: 'Xóa tài khoản',
                  titleColor: AppColors.error,
                  onTap: () => _showDeleteAccountDialog(context),
                ),
                const Divider(height: 1, indent: 56),
                _SettingsTile(
                  icon: Icons.logout,
                  iconColor: AppColors.error,
                  title: 'Đăng xuất',
                  titleColor: AppColors.error,
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
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Chọn giao diện',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _ThemeOption(
                  icon: Icons.light_mode_outlined,
                  label: 'Sáng',
                  isSelected: current == ThemeMode.light,
                  onTap: () {
                    context.read<ThemeCubit>().setTheme(ThemeMode.light);
                    Navigator.pop(sheetContext);
                  },
                ),
                _ThemeOption(
                  icon: Icons.dark_mode_outlined,
                  label: 'Tối',
                  isSelected: current == ThemeMode.dark,
                  onTap: () {
                    context.read<ThemeCubit>().setTheme(ThemeMode.dark);
                    Navigator.pop(sheetContext);
                  },
                ),
                _ThemeOption(
                  icon: Icons.settings_suggest_outlined,
                  label: 'Theo hệ thống',
                  isSelected: current == ThemeMode.system,
                  onTap: () {
                    context.read<ThemeCubit>().setTheme(ThemeMode.system);
                    Navigator.pop(sheetContext);
                  },
                ),
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
          title: const Text('Đổi mật khẩu'),
          content: const Text(
            'Chức năng đổi mật khẩu sẽ gửi email xác nhận đến địa chỉ email của bạn.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                // TODO: Trigger password reset email via AuthBloc
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã gửi email đổi mật khẩu!'),
                  ),
                );
              },
              child: const Text('Gửi email'),
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
          icon: const Icon(Icons.warning_amber_rounded,
              color: AppColors.error, size: 48),
          title: const Text('Xóa tài khoản vĩnh viễn?'),
          content: const Text(
            'Hành động này KHÔNG THỂ HOÀN TÁC. '
            'Toàn bộ dữ liệu tập luyện, dinh dưỡng và hồ sơ cá nhân '
            'của bạn sẽ bị xóa vĩnh viễn.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                // TODO: Trigger account deletion
                Navigator.pop(ctx);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: const Text('Xóa tài khoản'),
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

/// Section label above each card group.
class _SectionLabel extends StatelessWidget {
  final String title;

  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// White rounded container grouping multiple [_SettingsTile]s.
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

/// Individual tile inside a [_CardGroup].
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
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.colorScheme.onSurface;
    final effectiveTitleColor = titleColor ?? theme.colorScheme.onSurface;

    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: effectiveIconColor, size: 22),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: effectiveTitleColor,
        ),
      ),
      trailing: trailing ??
          (showChevron
              ? Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Colors.grey.shade400,
                )
              : null),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}

/// Radio-like option in the theme picker bottom sheet.
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
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: theme.colorScheme.onSurface),
      title: Text(label),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
          : null,
    );
  }
}
