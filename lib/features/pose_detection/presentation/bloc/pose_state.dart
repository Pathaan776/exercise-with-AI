import 'package:equatable/equatable.dart';
import 'package:fitcheck/features/pose_detection/domain/entities/pose_entity.dart';
import 'package:fitcheck/features/pose_detection/domain/exercise/exercise_result.dart';

final class PoseState extends Equatable {
  const PoseState({
    required this.isRunning,
    required this.resultsByDetectorId,
    this.pose,
    this.errorMessage,
  });

  final bool isRunning;
  final PoseEntity? pose;
  final Map<String, ExerciseResult> resultsByDetectorId;
  final String? errorMessage;

  PoseState copyWith({
    bool? isRunning,
    PoseEntity? pose,
    Map<String, ExerciseResult>? resultsByDetectorId,
    String? errorMessage,
  }) {
    return PoseState(
      isRunning: isRunning ?? this.isRunning,
      pose: pose ?? this.pose,
      resultsByDetectorId: resultsByDetectorId ?? this.resultsByDetectorId,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isRunning, pose, resultsByDetectorId, errorMessage];

  static PoseState initial() => const PoseState(isRunning: false, resultsByDetectorId: {});
}

