import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/chat_repository.dart';
import '../data/message_model.dart';

/// Real-time chat screen between a Coach and a User.
///
/// Requires [peerId] (the other person's UID), [peerName], and
/// optionally [peerAvatarUrl].
/// Messages are streamed from `chat_rooms/{chatRoomId}/messages`.
class ChatRoomScreen extends StatefulWidget {
  final String peerId;
  final String peerName;
  final String? peerAvatarUrl;

  const ChatRoomScreen({
    super.key,
    required this.peerId,
    required this.peerName,
    this.peerAvatarUrl,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _chatRepo = ChatRepository();
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  late final String _currentUserId;
  late final String _chatRoomId;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _chatRoomId = ChatRepository.getChatRoomId(_currentUserId, widget.peerId);
    _textController.addListener(() {
      final hasText = _textController.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ───────────────────────── Send ─────────────────────────

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();

    try {
      await _chatRepo.sendMessage(
        chatRoomId: _chatRoomId,
        senderId: _currentUserId,
        receiverId: widget.peerId,
        text: text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Gửi tin nhắn thất bại: $e'),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    }
  }

  // ───────────────────────── Build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // ── Message List ──
          Expanded(child: _buildMessageList()),

          // ── Input Bar ──
          _buildInputBar(),
        ],
      ),
    );
  }

  // ───────────────────── AppBar ─────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0.5,
      titleSpacing: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.deepOrange.shade50,
            backgroundImage: widget.peerAvatarUrl != null
                ? NetworkImage(widget.peerAvatarUrl!)
                : null,
            child: widget.peerAvatarUrl == null
                ? Text(
                    widget.peerName.isNotEmpty
                        ? widget.peerName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange.shade700,
                      fontSize: 16,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.peerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Đang hoạt động',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: null, // Disabled for now
          icon: Icon(Icons.videocam_outlined, color: Colors.grey.shade400),
          tooltip: 'Video call (Sắp ra mắt)',
        ),
        IconButton(
          onPressed: null, // Disabled for now
          icon: Icon(Icons.call_outlined, color: Colors.grey.shade400),
          tooltip: 'Gọi điện (Sắp ra mắt)',
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ───────────────────── Message List ─────────────────────

  Widget _buildMessageList() {
    return StreamBuilder<List<MessageModel>>(
      stream: _chatRepo.messagesStream(_chatRoomId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data ?? [];
        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_bubble_outline_rounded,
                    size: 56, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'Hãy bắt đầu cuộc trò chuyện!',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index];
            final isMine = msg.senderId == _currentUserId;

            // Check if we should show a time separator
            final showTime = index == messages.length - 1 ||
                _shouldShowTimeSeparator(
                  messages[index],
                  messages[index + 1],
                );

            return _MessageBubble(
              message: msg,
              isMine: isMine,
              peerName: widget.peerName,
              showTimeSeparator: showTime,
            );
          },
        );
      },
    );
  }

  /// Show a time separator if messages are more than 15 minutes apart.
  bool _shouldShowTimeSeparator(MessageModel current, MessageModel previous) {
    return current.timestamp.difference(previous.timestamp).inMinutes.abs() >
        15;
  }

  // ───────────────────── Input Bar ─────────────────────

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0
            ? 8
            : MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Attachment button
          IconButton(
            onPressed: () {
              // TODO: Attach image/video
            },
            icon: Icon(
              Icons.add_circle_outline,
              color: Colors.grey.shade500,
              size: 26,
            ),
          ),

          // Text field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),

          const SizedBox(width: 4),

          // Send / Mic button
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _hasText
                ? IconButton(
                    key: const ValueKey('send'),
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send_rounded),
                    color: Colors.deepOrange,
                    iconSize: 26,
                  )
                : IconButton(
                    key: const ValueKey('mic'),
                    onPressed: null,
                    icon: Icon(
                      Icons.mic_outlined,
                      color: Colors.grey.shade400,
                      size: 26,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Message Bubble
// ─────────────────────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMine;
  final String peerName;
  final bool showTimeSeparator;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.peerName,
    this.showTimeSeparator = false,
  });

  @override
  Widget build(BuildContext context) {
    final timeText = DateFormat('HH:mm').format(message.timestamp);

    return Column(
      children: [
        // Time separator
        if (showTimeSeparator)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              _formatDateSeparator(message.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            mainAxisAlignment:
                isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Peer avatar (only for received messages)
              if (!isMine) ...[
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.grey.shade200,
                  child: Text(
                    peerName.isNotEmpty ? peerName[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],

              // Bubble
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMine ? Colors.deepOrange : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft:
                          Radius.circular(isMine ? 16 : 4),
                      bottomRight:
                          Radius.circular(isMine ? 4 : 16),
                    ),
                    border: isMine
                        ? null
                        : Border.all(
                            color: Colors.grey.shade200,
                            width: 0.8,
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: isMine
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: TextStyle(
                          fontSize: 15,
                          color: isMine ? Colors.white : Colors.black87,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeText,
                        style: TextStyle(
                          fontSize: 11,
                          color: isMine
                              ? Colors.white.withValues(alpha: 0.7)
                              : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateSeparator(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(dt.year, dt.month, dt.day);

    if (messageDay == today) {
      return 'Hôm nay';
    } else if (messageDay == today.subtract(const Duration(days: 1))) {
      return 'Hôm qua';
    } else {
      return DateFormat('dd/MM/yyyy').format(dt);
    }
  }
}
