import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/routes/app_router.dart';
import 'profile_detail_screen.dart';
import 'system_settings_screen.dart';

// ── Dark theme constants ────────────────────────────────────────────────────
const Color _kBg = Color(0xFF060708);
const Color _kCardBg = Color(0xFF1A1D23);
const Color _kLime = Color(0xFFE2FF54);
const Color _kBorder = Color(0xFF2A2D35);
const Color _kTextSecondary = Color(0xFF8A8F9D);

/// Profile / Settings tab — card-based layout with trainee info,
/// general settings, community & support, and social media sections.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Người dùng';
    final shortId = user?.uid.substring(0, 6) ?? '------';

    return Scaffold(
      backgroundColor: _kBg,
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
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 32,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: _kCardBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: _kBorder),
                      ),
                      child: IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SystemSettingsScreen(),
                            ),
                          );
                        },
                        icon: Icon(PhosphorIcons.gearSix(), size: 22),
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // ── 2. User Profile Info ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _kLime, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: _kCardBg,
                        backgroundImage: user?.photoURL != null
                            ? NetworkImage(user!.photoURL!)
                            : null,
                        child: user?.photoURL == null
                            ? Text(
                                displayName.isNotEmpty
                                    ? displayName[0].toUpperCase()
                                    : 'U',
                                style: GoogleFonts.inter(
                                  color: _kLime,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Name + User ID
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'User ID: $shortId',
                                style: GoogleFonts.inter(
                                  color: _kTextSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(
                                    ClipboardData(text: user?.uid ?? ''),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: _kCardBg,
                                      content: Text(
                                        'Đã copy ID',
                                        style: GoogleFonts.inter(color: Colors.white),
                                      ),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                                child: Icon(
                                  PhosphorIcons.copy(),
                                  size: 14,
                                  color: _kLime,
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
                    icon: PhosphorIcons.user(),
                    title: 'Hồ sơ cá nhân',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ProfileDetailScreen(),
                        ),
                      );
                    },
                  ),
                  const _CustomDivider(),
                  _CardListTile(
                    icon: PhosphorIcons.target(),
                    title: 'Mục tiêu',
                    onTap: () {
                      // TODO: Navigate to goal screen
                    },
                  ),
                  const _CustomDivider(),
                  _CardListTile(
                    icon: PhosphorIcons.barbell(),
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
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _kCardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1877F2).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.facebook, color: Color(0xFF1877F2), size: 24),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Cộng đồng NutriFit',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Giảm cân hiệu quả hơn khi có người đồng hành. Chia sẻ kinh nghiệm và nhận lời khuyên từ cộng đồng.',
                        style: GoogleFonts.inter(
                          color: _kTextSecondary,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: () {
                            // TODO: Open Facebook group URL
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: _kLime,
                            foregroundColor: _kBg,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Tham gia ngay',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Support Card
              _CardGroup(
                children: [
                  _CardListTile(
                    icon: PhosphorIcons.sparkle(),
                    iconColor: _kLime,
                    title: 'Trợ lý AI',
                    subtitle: 'Hỗ trợ ghi nhanh, trò chuyện...',
                    onTap: () => context.push('/chat'),
                  ),
                  const _CustomDivider(),
                  _CardListTile(
                    icon: PhosphorIcons.chatsCircle(),
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
                    icon: PhosphorIcons.facebookLogo(),
                    iconColor: const Color(0xFF1877F2),
                    title: 'Facebook',
                    onTap: () {},
                  ),
                  const _CustomDivider(),
                  _CardListTile(
                    icon: PhosphorIcons.instagramLogo(),
                    iconColor: const Color(0xFFE4405F),
                    title: 'Instagram',
                    onTap: () {},
                  ),
                  const _CustomDivider(),
                  _CardListTile(
                    icon: PhosphorIcons.tiktokLogo(),
                    iconColor: Colors.white,
                    title: 'TikTok',
                    onTap: () {},
                  ),
                  const _CustomDivider(),
                  _CardListTile(
                    icon: PhosphorIcons.youtubeLogo(),
                    iconColor: const Color(0xFFFF0000),
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

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
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
          border: Border.all(color: _kBorder),
        ),
        child: Column(children: children),
      ),
    );
  }
}

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
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: GoogleFonts.inter(
                color: _kTextSecondary,
                fontSize: 12,
              ),
            )
          : null,
      trailing: const Icon(
        Icons.chevron_right,
        size: 18,
        color: _kTextSecondary,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
