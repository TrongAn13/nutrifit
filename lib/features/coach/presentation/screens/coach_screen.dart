import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';

/// Coach tab — displays coach search, add button, and empty state.
class CoachScreen extends StatelessWidget {
  const CoachScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('HLV của tôi'),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => context.push('/chat'),
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            tooltip: 'Tin nhắn',
          ),
          IconButton(
            onPressed: () {
              // TODO: Navigate to notifications
            },
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Thông báo',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // ── Search Bar ──
            TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm HLV...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // ── Add Coach Button ──
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: () {
                  // TODO: Navigate to coach search/add
                },
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Thêm HLV'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            // ── Empty State ──
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor:
                          colorScheme.primary.withValues(alpha: 0.08),
                      child: Icon(
                        Icons.person_outline_rounded,
                        size: 48,
                        color: colorScheme.primary.withValues(alpha: 0.35),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Chưa có kết nối nào',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Bạn chưa kết nối với Huấn luyện viên nào. '
                        'Hãy tìm và thêm HLV để được hướng dẫn tập luyện chuyên nghiệp.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
