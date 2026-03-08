import 'dart:io';

import 'package:flutter/foundation.dart';


/// Events dispatched to [MetricsBloc].
@immutable
sealed class MetricsEvent {
  const MetricsEvent();
}

/// Load all body metrics and progress photos.
final class MetricsLoadRequested extends MetricsEvent {
  const MetricsLoadRequested();
}

/// Log a new weight entry and reload data.
final class MetricsWeightLogged extends MetricsEvent {
  final double weight;
  final DateTime date;

  const MetricsWeightLogged({required this.weight, required this.date});
}

/// Upload a progress photo and reload data.
final class MetricsPhotoUploaded extends MetricsEvent {
  final File imageFile;
  final String? caption;

  const MetricsPhotoUploaded({required this.imageFile, this.caption});
}
