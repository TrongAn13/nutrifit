import 'package:cloud_firestore/cloud_firestore.dart';

/// Repository for coach-trainee invitations stored in the `invitations` collection.
///
/// Each invitation document contains:
/// - `fromCoachId`: UID of the coach who sent the invite.
/// - `fromCoachName`: Display name of the coach.
/// - `toEmail`: Email of the invited trainee.
/// - `toUserId`: UID of the target trainee (filled after email lookup).
/// - `status`: 'pending' | 'accepted' | 'rejected'.
/// - `createdAt`: Server timestamp.
class InvitationRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _invitations =>
      _db.collection('invitations');

  // ───────────────────────── Send Invitation ─────────────────────────

  /// Creates a new pending invitation from a coach to a trainee email.
  Future<void> sendInvitation({
    required String coachId,
    required String coachName,
    required String toEmail,
  }) async {
    try {
      // Look up trainee by email to get their UID
      final userQuery = await _db
          .collection('users')
          .where('email', isEqualTo: toEmail)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw Exception('Không tìm thấy học viên với email này');
      }

      final toUserId = userQuery.docs.first.id;

      await _invitations.add({
        'fromCoachId': coachId,
        'fromCoachName': coachName,
        'toEmail': toEmail,
        'toUserId': toUserId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Gửi lời mời thất bại: $e');
    }
  }

  // ───────────────────────── Stream Pending ─────────────────────────

  /// Streams pending invitations for the given trainee ID.
  Stream<QuerySnapshot<Map<String, dynamic>>> pendingInvitations(
    String userId,
  ) {
    return _invitations
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  // ───────────────────────── Accept ─────────────────────────

  /// Accepts an invitation and creates the coach-trainee link.
  ///
  /// 1. Updates invitation status to 'accepted'.
  /// 2. Sets `coachId` on trainee's document.
  /// 3. Adds userId to coach's `clientIds` array.
  Future<void> acceptInvitation({
    required String invitationId,
    required String userId,
    required String coachId,
  }) async {
    try {
      final batch = _db.batch();

      // Update invitation status
      batch.update(_invitations.doc(invitationId), {
        'status': 'accepted',
      });

      // Link trainee → coach
      batch.update(_db.collection('users').doc(userId), {
        'coachId': coachId,
      });

      // Link coach → trainee
      batch.update(_db.collection('users').doc(coachId), {
        'clientIds': FieldValue.arrayUnion([userId]),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Chấp nhận lời mời thất bại: $e');
    }
  }

  // ───────────────────────── Reject ─────────────────────────

  /// Rejects an invitation.
  Future<void> rejectInvitation(String invitationId) async {
    try {
      await _invitations.doc(invitationId).update({
        'status': 'rejected',
      });
    } catch (e) {
      throw Exception('Từ chối lời mời thất bại: $e');
    }
  }

  // ───────────────────────── Disconnect ─────────────────────────

  /// Disconnects a trainee from their coach.
  Future<void> disconnect({
    required String userId,
    required String coachId,
  }) async {
    try {
      final batch = _db.batch();

      // Remove coachId from trainee
      batch.update(_db.collection('users').doc(userId), {
        'coachId': FieldValue.delete(),
      });

      // Remove userId from coach's clientIds
      batch.update(_db.collection('users').doc(coachId), {
        'clientIds': FieldValue.arrayRemove([userId]),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Hủy kết nối thất bại: $e');
    }
  }
}
