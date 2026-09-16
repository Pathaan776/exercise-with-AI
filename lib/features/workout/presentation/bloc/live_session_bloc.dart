import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fitcheck/features/workout/data/datasource/pose_detection_client.dart';
import 'package:fitcheck/features/workout/domain/analyzers/analyzer_factory.dart';
import 'package:fitcheck/features/workout/domain/analyzers/exercise_analyzer.dart';
import 'package:fitcheck/features/workout/domain/entities/exercise_analysis.dart';
import 'package:fitcheck/features/workout/domain/entities/exercise_type.dart';
import 'package:fitcheck/features/workout/presentation/bloc/live_session_event.dart';
import 'package:fitcheck/features/workout/presentation/bloc/live_session_state.dart';
import 'package:fitcheck/features/workout/presentation/models/skeleton_frame.dart';

/// Drives a live camera coaching session: feeds frames through ML Kit, scores
/// them with the analyzer for the chosen exercise and publishes both the
/// numbers and the skeleton to draw.
class LiveSessionBloc extends Bloc<LiveSessionEvent, LiveSessionState> {
  LiveSessionBloc({
    required PoseDetectionClient poseDetectionClient,
    required ExerciseAnalyzerFactory analyzerFactory,
    required ExerciseType exercise,
  }) : _client = poseDetectionClient,
       _analyzer = analyzerFactory.create(exercise),
       super(LiveSessionState.initial(exercise)) {
    on<LiveSessionStarted>(_onStarted);
    on<LiveSessionPaused>(_onPaused);
    on<LiveSessionReset>(_onReset);
    on<LiveSessionCameraReady>(_onCameraReady);
    on<LiveSessionCameraFailed>(_onCameraFailed);
    on<LiveSessionFrameCaptured>(_onFrame);
  }

  final PoseDetectionClient _client;
  final ExerciseAnalyzer _analyzer;

  /// Frames arrive faster than ML Kit can consume them. Rather than queueing
  /// (which builds unbounded latency), newer frames are dropped while one is
  /// in flight — the analysis stays pinned to the present moment.
  bool _isProcessing = false;

  void _onStarted(LiveSessionStarted event, Emitter<LiveSessionState> emit) {
    if (state.cameraStatus != CameraStatus.ready) return;
    emit(state.copyWith(isRunning: true));
  }

  void _onPaused(LiveSessionPaused event, Emitter<LiveSessionState> emit) {
    emit(state.copyWith(isRunning: false));
  }

  void _onReset(LiveSessionReset event, Emitter<LiveSessionState> emit) {
    _analyzer.reset();
    emit(
      state.copyWith(
        isRunning: false,
        analysis: ExerciseAnalysis.empty(state.exercise),
        clearSkeleton: true,
      ),
    );
  }

  void _onCameraReady(
    LiveSessionCameraReady event,
    Emitter<LiveSessionState> emit,
  ) {
    _analyzer.reset();
    emit(
      state.copyWith(
        cameraStatus: CameraStatus.ready,
        isFrontCamera: event.isFrontCamera,
      ),
    );
  }

  void _onCameraFailed(
    LiveSessionCameraFailed event,
    Emitter<LiveSessionState> emit,
  ) {
    emit(
      state.copyWith(
        cameraStatus: CameraStatus.failed,
        isRunning: false,
        errorMessage: event.message,
      ),
    );
  }

  Future<void> _onFrame(
    LiveSessionFrameCaptured event,
    Emitter<LiveSessionState> emit,
  ) async {
    if (!state.isRunning || _isProcessing) return;
    _isProcessing = true;

    try {
      final result = await _client.detectStream(
        event.image,
        event.camera,
        event.deviceOrientation,
      );

      // The session may have been paused or closed while ML Kit was working.
      if (isClosed || !state.isRunning) return;

      if (result.isEmpty) {
        emit(
          state.copyWith(
            analysis: _analyzer.analyzeFrame(const []),
            clearSkeleton: true,
          ),
        );
        return;
      }

      final analysis = _analyzer.analyzeFrame(
        result.poses,
        now: DateTime.now(),
      );
      emit(
        state.copyWith(
          analysis: analysis,
          skeleton: SkeletonFrame.fromPose(
            _analyzer.bestPose(result.poses),
            imageSize: result.imageSize,
            mirrored: state.isFrontCamera,
          ),
        ),
      );
    } finally {
      _isProcessing = false;
    }
  }
}
