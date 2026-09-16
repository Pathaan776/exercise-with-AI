import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import 'package:fitcheck/features/workout/domain/entities/exercise_analysis.dart';
import 'package:fitcheck/features/workout/domain/entities/exercise_type.dart';
import 'package:fitcheck/features/workout/presentation/models/skeleton_frame.dart';

final class ImageAnalysisState extends Equatable {
  const ImageAnalysisState({
    required this.exercise,
    required this.isAnalysing,
    required this.analysis,
    this.imageBytes,
    this.skeleton,
    this.errorMessage,
  });

  factory ImageAnalysisState.initial(ExerciseType exercise) =>
      ImageAnalysisState(
        exercise: exercise,
        isAnalysing: false,
        analysis: ExerciseAnalysis.empty(exercise),
      );

  final ExerciseType exercise;
  final bool isAnalysing;
  final ExerciseAnalysis analysis;
  final Uint8List? imageBytes;
  final SkeletonFrame? skeleton;
  final String? errorMessage;

  bool get hasResult => imageBytes != null && !isAnalysing;

  ImageAnalysisState copyWith({
    bool? isAnalysing,
    ExerciseAnalysis? analysis,
    Uint8List? imageBytes,
    SkeletonFrame? skeleton,
    bool clearSkeleton = false,
    String? errorMessage,
  }) {
    return ImageAnalysisState(
      exercise: exercise,
      isAnalysing: isAnalysing ?? this.isAnalysing,
      analysis: analysis ?? this.analysis,
      imageBytes: imageBytes ?? this.imageBytes,
      skeleton: clearSkeleton ? null : (skeleton ?? this.skeleton),
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    exercise,
    isAnalysing,
    analysis,
    imageBytes?.length,
    skeleton,
    errorMessage,
  ];
}
