import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fitcheck/features/workout/data/datasource/pose_detection_client.dart';
import 'package:fitcheck/features/workout/domain/analyzers/analyzer_factory.dart';
import 'package:fitcheck/features/workout/domain/analyzers/exercise_analyzer.dart';
import 'package:fitcheck/features/workout/domain/entities/exercise_analysis.dart';
import 'package:fitcheck/features/workout/domain/entities/exercise_type.dart';
import 'package:fitcheck/features/workout/presentation/bloc/image_analysis_event.dart';
import 'package:fitcheck/features/workout/presentation/bloc/image_analysis_state.dart';
import 'package:fitcheck/features/workout/presentation/models/skeleton_frame.dart';

/// Scores a single photo. Rep counting needs motion, so this reports posture
/// quality for the instant captured and nothing else.
class ImageAnalysisBloc extends Bloc<ImageAnalysisEvent, ImageAnalysisState> {
  ImageAnalysisBloc({
    required PoseDetectionClient poseDetectionClient,
    required ExerciseAnalyzerFactory analyzerFactory,
    required ExerciseType exercise,
  }) : _client = poseDetectionClient,
       _analyzer = analyzerFactory.create(exercise),
       super(ImageAnalysisState.initial(exercise)) {
    on<ImageAnalysisRequested>(_onRequested);
    on<ImageAnalysisCleared>(_onCleared);
  }

  final PoseDetectionClient _client;
  final ExerciseAnalyzer _analyzer;

  Future<void> _onRequested(
    ImageAnalysisRequested event,
    Emitter<ImageAnalysisState> emit,
  ) async {
    emit(
      state.copyWith(
        isAnalysing: true,
        imageBytes: event.bytes,
        clearSkeleton: true,
        analysis: ExerciseAnalysis.empty(state.exercise),
      ),
    );

    try {
      final poses = await _client.detectFile(event.path);
      final analysis = _analyzer.analyzeStill(poses);

      if (!analysis.hasPerson) {
        emit(
          state.copyWith(
            isAnalysing: false,
            analysis: analysis,
            errorMessage:
                'No clear pose found. Make sure your whole body is visible '
                'and shot from the side.',
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          isAnalysing: false,
          analysis: analysis,
          skeleton: SkeletonFrame.fromPose(
            _analyzer.bestPose(poses),
            imageSize: await _decodeSize(event.bytes),
          ),
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isAnalysing: false,
          analysis: ExerciseAnalysis.empty(state.exercise),
          errorMessage: 'Could not analyse that image.',
        ),
      );
      debugPrint('Image analysis failed: $error');
    }
  }

  void _onCleared(
    ImageAnalysisCleared event,
    Emitter<ImageAnalysisState> emit,
  ) {
    _analyzer.reset();
    emit(ImageAnalysisState.initial(state.exercise));
  }

  Future<ui.Size> _decodeSize(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final size = ui.Size(
      frame.image.width.toDouble(),
      frame.image.height.toDouble(),
    );
    frame.image.dispose();
    codec.dispose();
    return size;
  }
}
