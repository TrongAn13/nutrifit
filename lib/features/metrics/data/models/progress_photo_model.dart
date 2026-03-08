import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a progress photo stored in the `progress_photos` collection.
class ProgressPhotoModel {
  final String photoId;
  final String userId;
  final String imageUrl;
  final DateTime date;
  final String? caption;

  const ProgressPhotoModel({
    required this.photoId,
    required this.userId,
    required this.imageUrl,
    required this.date,
    this.caption,
  });

  // ───────────────────────── JSON Serialization ─────────────────────────

  factory ProgressPhotoModel.fromJson(Map<String, dynamic> json) {
    return ProgressPhotoModel(
      photoId: json['photoId'] as String,
      userId: json['userId'] as String,
      imageUrl: json['imageUrl'] as String,
      date: (json['date'] as Timestamp).toDate(),
      caption: json['caption'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'photoId': photoId,
      'userId': userId,
      'imageUrl': imageUrl,
      'date': Timestamp.fromDate(date),
      'caption': caption,
    };
  }

  // ───────────────────────── copyWith ─────────────────────────

  ProgressPhotoModel copyWith({
    String? photoId,
    String? userId,
    String? imageUrl,
    DateTime? date,
    String? caption,
  }) {
    return ProgressPhotoModel(
      photoId: photoId ?? this.photoId,
      userId: userId ?? this.userId,
      imageUrl: imageUrl ?? this.imageUrl,
      date: date ?? this.date,
      caption: caption ?? this.caption,
    );
  }

  @override
  String toString() => 'ProgressPhotoModel(id: $photoId, date: $date)';
}
