import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single chat message in a conversation.
///
/// Stored in Firestore at: `chat_rooms/{chatRoomId}/messages/{id}`.
class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;
  final String type; // 'text', 'image', 'video'

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    this.type = 'text',
  });

  // ───────────────────────── JSON Serialization ─────────────────────────

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String,
      text: json['text'] as String? ?? '',
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      type: json['type'] as String? ?? 'text',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type,
    };
  }

  // ───────────────────────── copyWith ─────────────────────────

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? text,
    DateTime? timestamp,
    String? type,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
    );
  }

  @override
  String toString() =>
      'MessageModel(id: $id, sender: $senderId, text: $text)';
}
