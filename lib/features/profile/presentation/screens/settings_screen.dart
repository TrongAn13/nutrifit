import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/logic/auth_bloc.dart';
import '../../../auth/logic/auth_event.dart';

/// Profile / Settings tab — displays user profile card and settings list.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cá nhân'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children:  [
          // ── Profile Card ──
          _ProfileCard(),
          SizedBox(height: 16),

          // ── Personal Tools ──
          _SectionHeader(title: 'Công cụ cá nhân'),
          _SettingsTile(
            icon: Icons.smart_toy_outlined,
            title: 'Huấn luyện viên cá nhân',
            subtitle: 'Trợ lý AI hỗ trợ luyện tập',
            route: '/chat',
          ),
          _SettingsTile(
            icon: Icons.analytics_outlined,
            title: 'Chỉ số cơ thể',
            subtitle: 'Theo dõi cân nặng, BMI và các chỉ số',
          ),
          SizedBox(height: 8),

          // ── Template Plans ──
          _SectionHeader(title: 'Mẫu kế hoạch'),
          _SettingsTile(
            icon: Icons.calendar_month_outlined,
            title: 'Mẫu kế hoạch tập',
            subtitle: 'Các chương trình tập luyện có sẵn',
            route: '/workout-templates',
          ),
          _SettingsTile(
            icon: Icons.restaurant_menu_outlined,
            title: 'Mẫu kế hoạch dinh dưỡng',
            subtitle: 'Các thực đơn mẫu',
          ),
          SizedBox(height: 8),

          // ── Library ──
          _SectionHeader(title: 'Thư viện'),
          _SettingsTile(
            icon: Icons.fitness_center_outlined,
            title: 'Thư viện động tác',
            subtitle: 'Danh sách bài tập và hướng dẫn',
            route: '/exercise-library',
          ),
          _SettingsTile(
            icon: Icons.egg_outlined,
            title: 'Thư viện thực phẩm',
            subtitle: 'Tra cứu dinh dưỡng thực phẩm',
            route: '/food-library',
          ),
          SizedBox(height: 8),

          // ── Account ──
          _SectionHeader(title: 'Tài khoản'),
          _SettingsTile(
            icon: Icons.lock_outline_rounded,
            title: 'Đổi mật khẩu',
            subtitle: 'Cập nhật mật khẩu đăng nhập',
          ),
          SizedBox(height: 8),

          // ── Logout ──
          _LogoutTile(),
          SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile Card
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Người dùng';
    final email = user?.email ?? '';

    return Card(
      child: InkWell(
        onTap: () => context.push('/edit-profile'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                backgroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : null,
                child: user?.photoURL == null
                    ? Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : 'U',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Settings Tile
// ─────────────────────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? route;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.route,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        onTap: () {
          if (route != null) {
            context.push(route!);
          }
          // TODO: Handle other tiles
        },
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: colorScheme.primary.withValues(alpha: 0.10),
          child: Icon(icon, size: 20, color: colorScheme.primary),
        ),
        title: Text(title, style: theme.textTheme.bodyLarge),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          size: 20,
          color: colorScheme.onSurface.withValues(alpha: 0.3),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logout Tile
// ─────────────────────────────────────────────────────────────────────────────

class _LogoutTile extends StatelessWidget {
  const _LogoutTile();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: AppColors.error.withValues(alpha: 0.08),
      child: ListTile(
        onTap: () {
          context.read<AuthBloc>().add(const AuthLogoutRequested());
        },
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.error.withValues(alpha: 0.12),
          child: const Icon(Icons.logout_rounded,
              size: 20, color: AppColors.error),
        ),
        title: Text(
          'Đăng xuất',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.error,
            fontWeight: FontWeight.w600,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

