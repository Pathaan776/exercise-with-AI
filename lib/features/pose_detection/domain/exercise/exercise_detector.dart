import 'package:fitcheck/features/pose_detection/domain/entities/pose_entity.dart';
import 'package:fitcheck/features/pose_detection/domain/exercise/exercise_result.dart';

abstract interface class ExerciseDetector {
  String get id;
  String get displayName;

  void reset();
  ExerciseResult? onPose(PoseEntity pose);
}

