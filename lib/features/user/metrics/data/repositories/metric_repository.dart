import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../models/body_metric_model.dart';
import '../models/progress_photo_model.dart';

/// Handles Firestore operations for `body_metrics` and `progress_photos`.
class MetricRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  MetricRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _metricsRef =>
      _firestore.collection('body_metrics');

  CollectionReference<Map<String, dynamic>> get _photosRef =>
      _firestore.collection('progress_photos');

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Chưa đăng nhập.');
    return user.uid;
  }

  // ───────────────────── Body Metrics ─────────────────────

  /// Fetches all body metrics for the current user, ordered by date desc.
  Future<List<BodyMetricModel>> getMetrics() async {
    try {
      final snapshot = await _metricsRef
          .where('userId', isEqualTo: _uid)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => BodyMetricModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Không thể tải chỉ số: ${e.toString()}');
    }
  }

  /// Saves a new body metric entry.
  Future<void> addMetric(BodyMetricModel metric) async {
    try {
      await _metricsRef.doc(metric.metricId).set(metric.toJson());
    } catch (e) {
      throw Exception('Không thể lưu chỉ số: ${e.toString()}');
    }
  }

  /// Convenience method to log a weight entry for a specific date.
  ///
  /// Fetches the user's latest height or defaults to 170 cm.
  Future<BodyMetricModel> logWeight(double weight, DateTime date) async {
    try {
      // Get latest metric for height reference
      final existing = await getMetrics();
      final height = existing.isNotEmpty ? existing.first.height : 170.0;

      final metric = BodyMetricModel(
        metricId: const Uuid().v4(),
        userId: _uid,
        date: DateTime(date.year, date.month, date.day),
        weight: weight,
        height: height,
      );

      await addMetric(metric);
      return metric;
    } catch (e) {
      throw Exception('Không thể ghi nhận cân nặng: ${e.toString()}');
    }
  }

  // ───────────────────── Progress Photos ─────────────────────

  /// Fetches all progress photos for the current user, ordered by date desc.
  Future<List<ProgressPhotoModel>> getPhotos() async {
    try {
      final snapshot = await _photosRef
          .where('userId', isEqualTo: _uid)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ProgressPhotoModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Không thể tải ảnh tiến độ: ${e.toString()}');
    }
  }

  /// Saves a new progress photo document.
  Future<void> addPhoto(ProgressPhotoModel photo) async {
    try {
      await _photosRef.doc(photo.photoId).set(photo.toJson());
    } catch (e) {
      throw Exception('Không thể lưu ảnh: ${e.toString()}');
    }
  }

  /// Uploads a progress photo to Firebase Storage and saves the document
  /// to the `progress_photos` collection.
  ///
  /// Returns the created [ProgressPhotoModel] with the download URL set.
  Future<ProgressPhotoModel> uploadProgressPhoto(
    File image, {
    String? caption,
  }) async {
    try {
      final photoId = const Uuid().v4();
      final ref = _storage
          .ref()
          .child('progress_photos')
          .child(_uid)
          .child('$photoId.jpg');

      // Upload file
      await ref.putFile(
        image,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Get download URL
      final downloadUrl = await ref.getDownloadURL();

      // Save document to Firestore
      final photo = ProgressPhotoModel(
        photoId: photoId,
        userId: _uid,
        imageUrl: downloadUrl,
        date: DateTime.now(),
        caption: caption,
      );

      await addPhoto(photo);
      return photo;
    } catch (e) {
      throw Exception('Không thể tải ảnh lên: ${e.toString()}');
    }
  }
}
