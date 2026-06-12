import 'package:fitcheck/features/pose_detection/domain/entities/pose_entity.dart';

final class PoseModel {
  const PoseModel({
    required this.landmarks,
    required this.timestamp,
  });

  final Map<PoseJoint, PoseLandmark> landmarks;
  final DateTime timestamp;

  PoseEntity toEntity() {
    return PoseEntity(
      landmarks: landmarks,
      timestamp: timestamp,
    );
  }
}

