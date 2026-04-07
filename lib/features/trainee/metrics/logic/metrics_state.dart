import 'package:flutter/foundation.dart';

import '../data/models/body_metric_model.dart';
import '../data/models/progress_photo_model.dart';

/// States emitted by [MetricsBloc].
@immutable
sealed class MetricsState {
  const MetricsState();
}

final class MetricsInitial extends MetricsState {
  const MetricsInitial();
}

final class MetricsLoading extends MetricsState {
  const MetricsLoading();
}

/// Contains both metrics history and progress photos.
final class MetricsLoaded extends MetricsState {
  final List<BodyMetricModel> metrics;
  final List<ProgressPhotoModel> photos;
  final bool isSavingPhoto;

  const MetricsLoaded({
    required this.metrics,
    required this.photos,
    this.isSavingPhoto = false,
  });
}

final class MetricsError extends MetricsState {
  final String message;

  const MetricsError(this.message);
}
