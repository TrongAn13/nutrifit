import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../nutrition/logic/water_cubit.dart';

/// Bottom sheet displayed when the center FAB is pressed.
///
/// Contains:
///   - 4 circular action buttons (AI Scan, Calo Voice, Bộ sưu tập, Hỗ trợ)
///   - List of quick shortcuts (Cân nặng, Ghi nhanh, Vận động, Nước)
class QuickActionBottomSheet extends StatelessWidget {
  const QuickActionBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Handle bar ──
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Header ──
            Row(
              children: [
                const Spacer(),
                Text(
                  'Lối tắt',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 22),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 3),

            // ── Circular action grid ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CircleAction(
                  icon: Icons.document_scanner_outlined,
                  label: 'AI Scan',
                  onTap: () {},
                ),
                _CircleAction(
                  icon: Icons.mic_outlined,
                  label: 'Calo Voice',
                  onTap: () {},
                ),
                _CircleAction(
                  icon: Icons.bookmark_outline,
                  label: 'Bộ sưu tập',
                  onTap: () {},
                ),
                _CircleAction(
                  icon: Icons.chat_outlined,
                  label: 'Hỗ trợ',
                  onTap: () => context.push('/chat'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Shortcut list ──
            _ShortcutTile(
              icon: Icons.monitor_weight_outlined,
              label: 'Cân nặng',
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Navigate to weight tracking
              },
            ),
            Divider(height: 1, color: Colors.grey[200]),
            _ShortcutTile(
              icon: Icons.restaurant_outlined,
              label: 'Ghi nhanh',
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Navigate to quick food log
              },
            ),
            Divider(height: 1, color: Colors.grey[200]),
            _ShortcutTile(
              icon: Icons.directions_run_outlined,
              label: 'Vận động',
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Navigate to exercise tracking
              },
            ),
            Divider(height: 1, color: Colors.grey[200]),
            _ShortcutTile(
              icon: Icons.local_drink_outlined,
              label: 'Nước',
              onTap: () async {
                Navigator.of(context).pop();
                await context.push('/water-tracking');
                if (context.mounted) {
                  context.read<WaterCubit>().load();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Circle Action Button
// ═══════════════════════════════════════════════════════════════════════════════

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CircleAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200, width: 1),
            ),
            child: Icon(icon, size: 24, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Shortcut Tile (ListTile-style)
// ═══════════════════════════════════════════════════════════════════════════════

class _ShortcutTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShortcutTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Colors.black87,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      trailing: Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
