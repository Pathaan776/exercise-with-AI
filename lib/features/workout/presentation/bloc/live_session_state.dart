import 'package:equatable/equatable.dart';

import 'package:fitcheck/features/workout/domain/entities/exercise_analysis.dart';
import 'package:fitcheck/features/workout/domain/entities/exercise_type.dart';
import 'package:fitcheck/features/workout/presentation/models/skeleton_frame.dart';

enum CameraStatus { initialising, ready, failed }

final class LiveSessionState extends Equatable {
  const LiveSessionState({
    required this.exercise,
    required this.isRunning,
    required this.analysis,
    required this.cameraStatus,
    this.skeleton,
    this.isFrontCamera = false,
    this.errorMessage,
  });

  factory LiveSessionState.initial(ExerciseType exercise) => LiveSessionState(
    exercise: exercise,
    isRunning: false,
    analysis: ExerciseAnalysis.empty(exercise),
    cameraStatus: CameraStatus.initialising,
  );

  final ExerciseType exercise;
  final bool isRunning;
  final ExerciseAnalysis analysis;
  final CameraStatus cameraStatus;
  final SkeletonFrame? skeleton;
  final bool isFrontCamera;
  final String? errorMessage;

  bool get canStart => cameraStatus == CameraStatus.ready;

  LiveSessionState copyWith({
    bool? isRunning,
    ExerciseAnalysis? analysis,
    CameraStatus? cameraStatus,
    SkeletonFrame? skeleton,
    bool clearSkeleton = false,
    bool? isFrontCamera,
    String? errorMessage,
  }) {
    return LiveSessionState(
      exercise: exercise,
      isRunning: isRunning ?? this.isRunning,
      analysis: analysis ?? this.analysis,
      cameraStatus: cameraStatus ?? this.cameraStatus,
      skeleton: clearSkeleton ? null : (skeleton ?? this.skeleton),
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    exercise,
    isRunning,
    analysis,
    cameraStatus,
    skeleton,
    isFrontCamera,
    errorMessage,
  ];
}
