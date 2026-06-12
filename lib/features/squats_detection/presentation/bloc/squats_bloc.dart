import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fitcheck/features/squats_detection/data/datasource/pose_detection_client.dart';
import 'package:fitcheck/features/squats_detection/domain/entities/squat_analysis.dart';
import 'package:fitcheck/features/squats_detection/domain/usecases/squat_analyzer.dart';
import 'package:fitcheck/features/squats_detection/presentation/bloc/squats_event.dart';
import 'package:fitcheck/features/squats_detection/presentation/bloc/squats_state.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

final class SquatsBloc extends Bloc<SquatsEvent, SquatsState> {
  SquatsBloc({
    required PoseDetectionClient poseDetectionClient,
    required SquatAnalyzer squatAnalyzer,
  }) : _poseDetectionClient = poseDetectionClient,
       _squatAnalyzer = squatAnalyzer,
       super(SquatsState.initial()) {
    on<SquatsImageSelected>(_onImageSelected);
    on<SquatsReset>(_onReset);
  }

  final PoseDetectionClient _poseDetectionClient;
  final SquatAnalyzer _squatAnalyzer;

  Future<void> _onImageSelected(
    SquatsImageSelected event,
    Emitter<SquatsState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoading: true,
        imageBytes: event.imageBytes,
        landmarkLines: const [],
        overlay: null,
      ),
    );
    try {
      final poses = await _poseDetectionClient.detectFile(event.imagePath);
      final analysis = _squatAnalyzer.analyzeImage(poses: poses);

      final best = _bestPose(poses);
      final lines = <String>[];
      final landmarks = <SquatsLandmark>[];
      if (best != null) {
        final values = best.landmarks.values.toList();
        for (final lm in values) {
          lines.add(
            '${lm.type.name}: (${lm.x.toStringAsFixed(0)}, ${lm.y.toStringAsFixed(0)}) vis=${lm.likelihood.toStringAsFixed(2)}',
          );
          landmarks.add(
            SquatsLandmark(
              type: lm.type,
              x: lm.x,
              y: lm.y,
              visibility: lm.likelihood,
            ),
          );
        }
      }

      emit(
        state.copyWith(
          isLoading: false,
          analysis: analysis,
          landmarkLines: lines,
          overlay: null,
        ),
      );

      if (landmarks.isNotEmpty) {
        emit(
          state.copyWith(
            overlay: SquatsOverlayData(
              imageSize: await _decodeImageSize(event.imageBytes),
              landmarks: landmarks,
            ),
          ),
        );
      }
    } catch (_) {
      emit(state.copyWith(isLoading: false, analysis: SquatAnalysis.initial()));
    }
  }

  void _onReset(SquatsReset event, Emitter<SquatsState> emit) {
    _squatAnalyzer.reset();
    emit(SquatsState.initial());
  }

  Future<Size> _decodeImageSize(Uint8List bytes) async {
    final codec = await instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return Size(frame.image.width.toDouble(), frame.image.height.toDouble());
  }

  Pose? _bestPose(List<Pose> poses) {
    if (poses.isEmpty) return null;
    Pose best = poses.first;
    for (final p in poses) {
      if (p.landmarks.length > best.landmarks.length) {
        best = p;
      }
    }
    return best;
  }
}
