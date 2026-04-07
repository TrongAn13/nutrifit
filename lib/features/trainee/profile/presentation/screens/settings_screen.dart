import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/routes/app_router.dart';
import 'profile_detail_screen.dart';
import 'system_settings_screen.dart';

/// Profile / Settings tab — card-based layout with trainee info,
/// general settings, community & support, and social media sections.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Người dùng';
    final shortId = user?.uid.substring(0, 6) ?? '------';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Header ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cá nhân',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SystemSettingsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.settings_outlined, size: 22),
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              // ── 2. User Profile Info ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 32,
                      backgroundColor:
                          theme.colorScheme.primary.withValues(alpha: 0.12),
                      backgroundImage: user?.photoURL != null
                          ? NetworkImage(user!.photoURL!)
                          : null,
                      child: user?.photoURL == null
                          ? Text(
                              displayName.isNotEmpty
                                  ? displayName[0].toUpperCase()
                                  : 'U',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),

                    // Name + User ID
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'User ID: $shortId',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(
                                    ClipboardData(text: user?.uid ?? ''),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Đã copy ID'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                child: Icon(
                                  Icons.copy,
                                  size: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── 3. Section: THIẾT LẬP CHUNG ──
              _SectionHeader(title: 'THIẾT LẬP CHUNG'),
              _CardGroup(
                children: [
                  _CardListTile(
                    icon: Icons.person_outline,
                    title: 'Hồ sơ cá nhân',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ProfileDetailScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  _CardListTile(
                    icon: Icons.flag_outlined,
                    title: 'Mục tiêu',
                    onTap: () {
                      // TODO: Navigate to goal screen
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  _CardListTile(
                    icon: Icons.sports_kabaddi_outlined,
                    title: 'Huấn luyện viên cá nhân',
                    onTap: () => context.push(AppRouter.coach),
                  ),
                ],
              ),

              // ── 4. Section: CỘNG ĐỒNG VÀ HỖ TRỢ ──
              _SectionHeader(title: 'CỘNG ĐỒNG VÀ HỖ TRỢ'),

              // Facebook Community Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.facebook, color: Colors.blue.shade700, size: 24),
                          const SizedBox(width: 10),
                          Text(
                            'Cộng đồng NutriFit',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Giảm cân hiệu quả hơn khi có người đồng hành. Chia sẻ kinh nghiệm và nhận lời khuyên từ cộng đồng.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            // TODO: Open Facebook group URL
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Tham gia ngay',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Support Card
              _CardGroup(
                children: [
                  _CardListTile(
                    icon: Icons.auto_awesome,
                    iconColor: Colors.teal,
                    title: 'Trợ lý AI',
                    subtitle: 'Hỗ trợ ghi nhanh, trò chuyện...',
                    onTap: () => context.push('/chat'),
                  ),
                  const Divider(height: 1, indent: 56),
                  _CardListTile(
                    icon: Icons.chat_bubble_outline,
                    title: 'Zalo OA',
                    subtitle: 'Giải đáp thắc mắc qua Zalo',
                    onTap: () {
                      // TODO: Open Zalo OA URL
                    },
                  ),
                ],
              ),

              // ── 5. Section: MẠNG XÃ HỘI ──
              _SectionHeader(title: 'NUTRIFIT TRÊN MẠNG XÃ HỘI'),
              _CardGroup(
                children: [
                  _CardListTile(
                    icon: Icons.facebook,
                    iconColor: Colors.blue.shade700,
                    title: 'Facebook',
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 56),
                  _CardListTile(
                    icon: Icons.camera_alt_outlined,
                    iconColor: Colors.pink.shade400,
                    title: 'Instagram',
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 56),
                  _CardListTile(
                    icon: Icons.music_note_outlined,
                    iconColor: Colors.black87,
                    title: 'TikTok',
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 56),
                  _CardListTile(
                    icon: Icons.play_circle_outline,
                    iconColor: Colors.red.shade600,
                    title: 'YouTube',
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Section Header
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

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

// ═══════════════════════════════════════════════════════════════════════════════
// Card Group (white container with thin grey border)
// ═══════════════════════════════════════════════════════════════════════════════

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

// ═══════════════════════════════════════════════════════════════════════════════
// Card List Tile (used inside _CardGroup)
// ═══════════════════════════════════════════════════════════════════════════════

class _CardListTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _CardListTile({
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = iconColor ?? theme.colorScheme.onSurface;

    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: effectiveColor, size: 22),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
              ),
            )
          : null,
      trailing: Icon(
        Icons.chevron_right,
        size: 20,
        color: Colors.grey.shade400,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
