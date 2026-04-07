import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/logic/auth_bloc.dart';
import '../../../auth/logic/auth_event.dart';

/// Profile screen for coach accounts.
///
/// Tab 4 of CoachMainScreen. Displays coach information, specialties,
/// default service packages, and settings/logout options.
class CoachProfileScreen extends StatelessWidget {
  const CoachProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // In a real app, this data would come from a CoachEntity / CoachBloc.
    // Here we use static demo data to fulfill the UI requirements.
    const coachName = 'Nguyễn Tuấn Hải';
    const bio = 'Chuyên gia thay đổi hình thể, giúp bạn đạt được vóc dáng mơ ước mà không cần kiêng khem khắc nghiệt...';
    const specialties = ['Giảm mỡ', 'Tăng cơ', 'Dinh dưỡng thể thao'];

    return Scaffold(
      backgroundColor: Colors.grey[50], // Nền xám siêu nhạt
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Section
              _buildHeaderSection(context, coachName),
              
              // Khối 1: Giới thiệu & Chuyên môn
              _buildBioAndSpecialtiesSection(bio, specialties),

              // Khối 2: Quản lý Gói Dịch vụ
              _buildServicePackagesSection(),

              // Khối 3: Cài đặt & Đăng xuất
              _buildSettingsAndLogoutSection(context),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. Header Section (Avatar, Name, Badge, Stats, Edit Button)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildHeaderSection(BuildContext context, String name) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar tròn to
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.deepOrange.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.deepOrange.shade100, width: 2),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0] : 'C',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange.shade600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Name & Badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, size: 14, color: Colors.blue.shade600),
                          const SizedBox(width: 4),
                          Text(
                            'Huấn luyện viên được chứng nhận',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Thống kê nhanh
          Row(
            children: [
              _buildStatColumn('4.9', 'Đánh giá', icon: Icons.star, iconColor: Colors.amber),
              _buildDivider(),
              _buildStatColumn('24', 'Học viên'),
              _buildDivider(),
              _buildStatColumn('3 năm', 'Kinh nghiệm'),
            ],
          ),
          const SizedBox(height: 24),
          // Nút Chỉnh sửa
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: () {}, // Navigate to Edit Profile in future
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                foregroundColor: Colors.black87,
              ),
              child: const Text(
                'Chỉnh sửa trang cá nhân',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String value, String label, {IconData? icon, Color? iconColor}) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 4),
                Icon(icon, size: 16, color: iconColor),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 24,
      width: 1,
      color: Colors.grey.shade200,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. Khối 1: Giới thiệu & Chuyên môn (Bio & Specialties)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildBioAndSpecialtiesSection(String bio, List<String> specialties) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Giới thiệu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            bio,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Chuyên môn',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: specialties.map((spec) => Chip(
              label: Text(spec),
              labelStyle: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            )).toList(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. Khối 2: Quản lý Gói Dịch vụ (Service Packages)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildServicePackagesSection() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Các gói huấn luyện',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {}, // Add package action
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Thêm'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.deepOrange,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          // Danh sách Gói (mẫu tĩnh)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            title: const Text(
              'Coaching 1 kèm 1 (1 Tháng)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                const Text(
                  '1.500.000 VNĐ',
                  style: TextStyle(
                    color: Colors.deepOrange,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Lịch tập & Thực đơn thiết kế riêng, hỗ trợ nhắn tin 24/7.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(Icons.edit, color: Colors.grey.shade400, size: 20),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 4. Khối 3: Cài đặt & Đăng xuất
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildSettingsAndLogoutSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: Colors.white,
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.settings_outlined,
            title: 'Cài đặt ứng dụng',
            onTap: () {},
          ),
          const Divider(height: 1, indent: 56),
          _buildSettingsTile(
            icon: Icons.star_outline_rounded,
            title: 'Đánh giá ứng dụng',
            onTap: () {},
          ),
          const Divider(height: 1, indent: 56),
          _buildSettingsTile(
            icon: Icons.help_outline_rounded,
            title: 'Trung tâm hỗ trợ',
            onTap: () {},
          ),
          const Divider(height: 1, indent: 56),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text(
              'Đăng xuất',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
            ),
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade600),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản của mình?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(const AuthLogoutRequested());
              context.go('/login');
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}
