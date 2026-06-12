import 'package:equatable/equatable.dart';

enum PoseJoint {
  leftShoulder,
  rightShoulder,
  leftElbow,
  rightElbow,
  leftWrist,
  rightWrist,
  leftHip,
  rightHip,
  leftKnee,
  rightKnee,
  leftAnkle,
  rightAnkle,
}

final class PoseLandmark extends Equatable {
  const PoseLandmark({
    required this.x,
    required this.y,
    this.z = 0,
    this.visibility = 1,
  });

  final double x;
  final double y;
  final double z;
  final double visibility;

  @override
  List<Object?> get props => [x, y, z, visibility];
}

final class PoseEntity extends Equatable {
  const PoseEntity({
    required this.landmarks,
    required this.timestamp,
  });

  final Map<PoseJoint, PoseLandmark> landmarks;
  final DateTime timestamp;

  PoseLandmark? landmark(PoseJoint joint) => landmarks[joint];

  @override
  List<Object?> get props => [landmarks, timestamp];
}

