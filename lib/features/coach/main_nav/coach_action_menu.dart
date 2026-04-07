import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/app_router.dart';
import '../presentation/screens/coach_dashboard_screen.dart';

/// Displays a modal bottom sheet with coach quick actions.
///
/// Actions:
/// 1. Thêm Học viên mới → opens the AddClientBottomSheet
/// 2. Tạo Giáo án mẫu → navigates to create plan screen
/// 3. Gửi thông báo chung → opens a broadcast input dialog
void showCoachActionMenu(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    backgroundColor: Colors.white,
    builder: (ctx) => const _CoachActionMenuSheet(),
  );
}

class _CoachActionMenuSheet extends StatelessWidget {
  const _CoachActionMenuSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Handle ──
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // ── Header ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tác vụ nhanh',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Action Items ──
            _ActionTile(
              icon: Icons.person_add_alt_1,
              iconColor: Colors.blue.shade600,
              iconBgColor: Colors.blue.shade50,
              title: 'Thêm Học viên mới',
              subtitle: 'Mời qua mã kết nối hoặc email',
              onTap: () {
                Navigator.pop(context); // Close this menu first
                // Re-use the AddClientBottomSheet from CoachDashboardScreen
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  backgroundColor: Colors.white,
                  builder: (_) => const AddClientBottomSheet(),
                );
              },
            ),
            const Divider(height: 1, indent: 56),

            _ActionTile(
              icon: Icons.fitness_center_rounded,
              title: 'Tạo mẫu giáo án',
              subtitle: 'Thiết kế giáo án tập luyện mới',
              iconColor: Colors.blue.shade600,
              iconBgColor: Colors.blue.shade50,
              onTap: () {
                Navigator.pop(context);
                context.push(AppRouter.createTemplate);
              },
            ),
            const Divider(height: 1, indent: 56),

            _ActionTile(
              icon: Icons.campaign_outlined,
              iconColor: Colors.deepOrange,
              iconBgColor: Colors.deepOrange.shade50,
              title: 'Gửi thông báo chung',
              subtitle: 'Gửi lời nhắc cho tất cả học viên',
              onTap: () {
                Navigator.pop(context);
                _showBroadcastDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Opens a simple dialog for broadcasting a message to all clients.
  void _showBroadcastDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gửi thông báo chung'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Nhập nội dung thông báo...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              // TODO: Implement broadcast logic
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text('Tính năng đang phát triển'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.deepOrange,
            ),
            child: const Text('Gửi'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action Tile
// ─────────────────────────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconBgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade500,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey.shade400,
        size: 20,
      ),
    );
  }
}
