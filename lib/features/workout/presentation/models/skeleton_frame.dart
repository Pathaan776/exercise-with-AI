import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

final class SkeletonNode extends Equatable {
  const SkeletonNode({
    required this.type,
    required this.x,
    required this.y,
    required this.likelihood,
  });

  final PoseLandmarkType type;
  final double x;
  final double y;
  final double likelihood;

  @override
  List<Object?> get props => [type, x, y, likelihood];
}

/// A pose reduced to what the overlay painter needs, decoupled from ML Kit's
/// mutable `Pose` so it can live in bloc state and compare cleanly.
final class SkeletonFrame extends Equatable {
  const SkeletonFrame({
    required this.imageSize,
    required this.nodes,
    this.mirrored = false,
  });

  /// Coordinate space [nodes] are expressed in.
  final Size imageSize;
  final List<SkeletonNode> nodes;

  /// True when the source preview is horizontally flipped (front camera), so
  /// the painter must flip the landmarks to match what the user sees.
  final bool mirrored;

  static SkeletonFrame? fromPose(
    Pose? pose, {
    required Size imageSize,
    bool mirrored = false,
  }) {
    if (pose == null || pose.landmarks.isEmpty || imageSize.isEmpty) {
      return null;
    }

    return SkeletonFrame(
      imageSize: imageSize,
      mirrored: mirrored,
      nodes: [
        for (final landmark in pose.landmarks.values)
          SkeletonNode(
            type: landmark.type,
            x: landmark.x,
            y: landmark.y,
            likelihood: landmark.likelihood,
          ),
      ],
    );
  }

  @override
  List<Object?> get props => [imageSize, nodes, mirrored];
}
