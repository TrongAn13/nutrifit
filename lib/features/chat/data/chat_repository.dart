import 'package:cloud_firestore/cloud_firestore.dart';

import 'message_model.dart';

/// Handles Firestore operations for the real-time chat feature.
///
/// Chat rooms are stored in the top-level `chat_rooms` collection.
/// Messages are a sub-collection under each chat room document.
class ChatRepository {
  final FirebaseFirestore _db;

  ChatRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  // ───────────────────────── Helpers ─────────────────────────

  /// Generates a deterministic chat room ID from two UIDs.
  ///
  /// Always sorts alphabetically so both parties get the same ID.
  static String getChatRoomId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  /// Reference to the messages sub-collection for a given chat room.
  CollectionReference<Map<String, dynamic>> _messagesRef(String chatRoomId) =>
      _db.collection('chat_rooms').doc(chatRoomId).collection('messages');

  // ───────────────────────── Read ─────────────────────────

  /// Returns a real-time stream of messages ordered by timestamp descending
  /// (newest first), suitable for a reversed ListView.
  Stream<List<MessageModel>> messagesStream(String chatRoomId) {
    return _messagesRef(chatRoomId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromJson(doc.data()))
            .toList());
  }

  // ───────────────────────── Write ─────────────────────────

  /// Sends a text message and updates the chat room metadata.
  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    try {
      final docRef = _messagesRef(chatRoomId).doc();
      final message = MessageModel(
        id: docRef.id,
        senderId: senderId,
        receiverId: receiverId,
        text: text,
        timestamp: DateTime.now(),
      );

      final batch = _db.batch();

      // 1. Write message
      batch.set(docRef, message.toJson());

      // 2. Update chat room metadata (last message preview, participants)
      batch.set(
        _db.collection('chat_rooms').doc(chatRoomId),
        {
          'participants': [senderId, receiverId],
          'lastMessage': text,
          'lastMessageTime': Timestamp.fromDate(message.timestamp),
          'lastSenderId': senderId,
        },
        SetOptions(merge: true),
      );

      await batch.commit();
    } catch (e) {
      throw Exception('Gửi tin nhắn thất bại: $e');
    }
  }
}
