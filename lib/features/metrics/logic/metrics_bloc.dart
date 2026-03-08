import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repositories/metric_repository.dart';
import 'metrics_event.dart';
import 'metrics_state.dart';

/// Manages body metrics and progress photos state.
class MetricsBloc extends Bloc<MetricsEvent, MetricsState> {
  final MetricRepository _repo;

  MetricsBloc({required MetricRepository metricRepository})
      : _repo = metricRepository,
        super(const MetricsInitial()) {
    on<MetricsLoadRequested>(_onLoadRequested);
    on<MetricsWeightLogged>(_onWeightLogged);
    on<MetricsPhotoUploaded>(_onPhotoUploaded);
  }

  /// Fetches metrics and photos in parallel.
  Future<void> _onLoadRequested(
    MetricsLoadRequested event,
    Emitter<MetricsState> emit,
  ) async {
    emit(const MetricsLoading());
    try {
      final results = await Future.wait([
        _repo.getMetrics(),
        _repo.getPhotos(),
      ]);
      emit(MetricsLoaded(
        metrics: results[0] as dynamic,
        photos: results[1] as dynamic,
      ));
    } catch (e) {
      emit(MetricsError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  /// Logs a weight entry and reloads all data.
  Future<void> _onWeightLogged(
    MetricsWeightLogged event,
    Emitter<MetricsState> emit,
  ) async {
    try {
      await _repo.logWeight(event.weight, event.date);
      // Reload everything after adding
      add(const MetricsLoadRequested());
    } catch (e) {
      emit(MetricsError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  /// Uploads a progress photo and reloads all data.
  Future<void> _onPhotoUploaded(
    MetricsPhotoUploaded event,
    Emitter<MetricsState> emit,
  ) async {
    // Emit a saving state so UI can show progress indicator
    if (state is MetricsLoaded) {
      final current = state as MetricsLoaded;
      emit(MetricsLoaded(
        metrics: current.metrics,
        photos: current.photos,
        isSavingPhoto: true,
      ));
    }
    try {
      await _repo.uploadProgressPhoto(event.imageFile, caption: event.caption);
      // Reload everything after upload
      add(const MetricsLoadRequested());
    } catch (e) {
      emit(MetricsError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
