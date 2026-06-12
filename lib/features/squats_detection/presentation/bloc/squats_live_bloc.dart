import 'package:fitcheck/features/squats_detection/data/datasource/pose_detection_client.dart';
import 'package:fitcheck/features/squats_detection/domain/usecases/squat_analyzer.dart';
import 'package:fitcheck/features/squats_detection/presentation/bloc/squats_live_event.dart';
import 'package:fitcheck/features/squats_detection/presentation/bloc/squats_live_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SquatsLiveBloc extends Bloc<SquatsLiveEvent, SquatsLiveState> {
  final PoseDetectionClient _client;
  final SquatAnalyzer _analyzer;
  bool _isProcessing = false;

  SquatsLiveBloc(this._client, this._analyzer)
    : super(SquatsLiveState.initial()) {
    on<SquatsLiveStarted>((event, emit) {
      _analyzer.reset();
      emit(state.copyWith(isRunning: true));
    });

    on<SquatsLiveStopped>((event, emit) {
      emit(state.copyWith(isRunning: false));
    });

    on<SquatsLiveFrameCaptured>(_onFrame);
  }

  Future<void> _onFrame(
    SquatsLiveFrameCaptured event,
    Emitter<SquatsLiveState> emit,
  ) async {
    if (!state.isRunning) return;
    if (_isProcessing) return;

    _isProcessing = true;
    try {
      final poses = await _client.detectStream(event.image, event.camera);
      final result = _analyzer.analyzeFrame(poses: poses);
      emit(state.copyWith(analysis: result));
    } catch (_) {
    } finally {
      _isProcessing = false;
    }
  }
}
