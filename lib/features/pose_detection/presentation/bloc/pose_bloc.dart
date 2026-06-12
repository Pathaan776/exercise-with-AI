import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fitcheck/features/pose_detection/domain/exercise/exercise_detector.dart';
import 'package:fitcheck/features/pose_detection/domain/exercise/exercise_result.dart';
import 'package:fitcheck/features/pose_detection/domain/repository/pose_repository.dart';
import 'package:fitcheck/features/pose_detection/domain/usecases/detect_pose_usecase.dart';
import 'package:fitcheck/features/pose_detection/presentation/bloc/pose_event.dart';
import 'package:fitcheck/features/pose_detection/presentation/bloc/pose_state.dart';

final class PoseBloc extends Bloc<PoseEvent, PoseState> {
  PoseBloc({
    required DetectPoseUsecase detectPoseUsecase,
    required PoseRepository poseRepository,
    required List<ExerciseDetector> exerciseDetectors,
  }) : _detectPoseUsecase = detectPoseUsecase,
       _poseRepository = poseRepository,
       _exerciseDetectors = exerciseDetectors,
       super(PoseState.initial()) {
    on<PoseStarted>(_onStarted);
    on<PoseStopped>(_onStopped);
    on<PoseReceived>(_onPoseReceived);
    on<PoseFailed>(_onPoseFailed);
  }

  final DetectPoseUsecase _detectPoseUsecase;
  final PoseRepository _poseRepository;
  final List<ExerciseDetector> _exerciseDetectors;

  StreamSubscription? _subscription;

  Future<void> _onStarted(PoseStarted event, Emitter<PoseState> emit) async {
    if (state.isRunning) return;

    for (final detector in _exerciseDetectors) {
      detector.reset();
    }

    emit(state.copyWith(isRunning: true, errorMessage: null));

    try {
      await _poseRepository.start();
      _subscription = _detectPoseUsecase().listen(
        (pose) => add(PoseReceived(pose)),
        onError: (Object error, StackTrace _) =>
            add(PoseFailed(error.toString())),
      );
    } catch (e) {
      add(PoseFailed(e.toString()));
    }
  }

  Future<void> _onStopped(PoseStopped event, Emitter<PoseState> emit) async {
    if (!state.isRunning) return;
    await _subscription?.cancel();
    _subscription = null;
    await _poseRepository.stop();
    emit(state.copyWith(isRunning: false));
  }

  void _onPoseReceived(PoseReceived event, Emitter<PoseState> emit) {
    final updated = Map<String, ExerciseResult>.from(state.resultsByDetectorId);
    for (final detector in _exerciseDetectors) {
      final result = detector.onPose(event.pose);
      if (result != null) {
        updated[result.detectorId] = result;
      }
    }

    emit(
      state.copyWith(
        pose: event.pose,
        resultsByDetectorId: updated,
        errorMessage: null,
      ),
    );
  }

  Future<void> _onPoseFailed(PoseFailed event, Emitter<PoseState> emit) async {
    await _subscription?.cancel();
    _subscription = null;
    await _poseRepository.stop();
    emit(state.copyWith(isRunning: false, errorMessage: event.message));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await _poseRepository.stop();
    return super.close();
  }
}
