import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/routes/app_router.dart';

/// Chat list screen for coaches — shows all active conversations
/// with their clients, sorted by most recent message.
class CoachChatListScreen extends StatelessWidget {
  const CoachChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final coachId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tin nhắn',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Search bar
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm tin nhắn...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon:
                          Icon(Icons.search, color: Colors.grey.shade400),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.grey.shade200, width: 0.8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.grey.shade200, width: 0.8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.deepOrange.shade300),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Chat Room List ──
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('chat_rooms')
                    .where('participants', arrayContains: coachId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Lỗi tải tin nhắn',
                        style: TextStyle(color: Colors.red.shade400),
                      ),
                    );
                  }

                  var docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return _EmptyChatState();
                  }

                  // Sort locally to avoid needing a Firestore composite index
                  // (arrayContains on 'participants' + orderBy on 'lastMessageTime')
                  docs = docs.toList()
                    ..sort((a, b) {
                      final timeA =
                          (a.data()['lastMessageTime'] as Timestamp?)?.toDate();
                      final timeB =
                          (b.data()['lastMessageTime'] as Timestamp?)?.toDate();
                      if (timeA == null && timeB == null) return 0;
                      if (timeA == null) return 1;
                      if (timeB == null) return -1;
                      return timeB.compareTo(timeA); // Descending
                    });

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data();
                      final participants =
                          List<String>.from(data['participants'] ?? []);
                      // The peer is the participant who is NOT the coach
                      final peerId = participants.firstWhere(
                        (id) => id != coachId,
                        orElse: () => '',
                      );

                      return _ChatRoomTile(
                        chatRoomId: docs[index].id,
                        peerId: peerId,
                        lastMessage: data['lastMessage'] as String? ?? '',
                        lastSenderId: data['lastSenderId'] as String? ?? '',
                        lastMessageTime:
                            (data['lastMessageTime'] as Timestamp?)?.toDate(),
                        currentUserId: coachId,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyChatState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline_rounded,
              size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Chưa có cuộc trò chuyện nào',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Khi bạn nhắn tin cho học viên,\ncuộc trò chuyện sẽ hiển thị ở đây.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade400,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chat Room Tile
// ─────────────────────────────────────────────────────────────────────────────

/// A single chat room row. Fetches the peer's name from Firestore.
class _ChatRoomTile extends StatelessWidget {
  final String chatRoomId;
  final String peerId;
  final String lastMessage;
  final String lastSenderId;
  final DateTime? lastMessageTime;
  final String currentUserId;

  const _ChatRoomTile({
    required this.chatRoomId,
    required this.peerId,
    required this.lastMessage,
    required this.lastSenderId,
    required this.lastMessageTime,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    // Fetch peer name from Firestore users collection
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future:
          FirebaseFirestore.instance.collection('users').doc(peerId).get(),
      builder: (context, userSnap) {
        final peerName =
            userSnap.data?.data()?['name'] as String? ?? 'Học viên';

        final timeText = lastMessageTime != null
            ? _formatTime(lastMessageTime!)
            : '';

        // Preview: if I sent the last message, prefix with "Bạn: "
        final preview = lastSenderId == currentUserId
            ? 'Bạn: $lastMessage'
            : lastMessage;

        return InkWell(
          onTap: () {
            context.push(
              AppRouter.chatRoom,
              extra: {
                'peerId': peerId,
                'peerName': peerName,
              },
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: [
                // Avatar with online dot
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.deepOrange.shade50,
                      child: Text(
                        peerName.isNotEmpty
                            ? peerName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange.shade700,
                        ),
                      ),
                    ),
                    // Online indicator (mock)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.green.shade500,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),

                // Name + last message
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              peerName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            timeText,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        preview,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(dt.year, dt.month, dt.day);

    if (messageDay == today) {
      return DateFormat('HH:mm').format(dt);
    } else if (messageDay == today.subtract(const Duration(days: 1))) {
      return 'Hôm qua';
    } else {
      return DateFormat('dd/MM').format(dt);
    }
  }
}
