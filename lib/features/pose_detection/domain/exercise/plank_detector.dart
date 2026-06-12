import 'package:fitcheck/core/utils/angle_calculator.dart';
import 'package:fitcheck/features/pose_detection/domain/entities/pose_entity.dart';
import 'package:fitcheck/features/pose_detection/domain/exercise/exercise_detector.dart';
import 'package:fitcheck/features/pose_detection/domain/exercise/exercise_result.dart';

final class PlankDetector implements ExerciseDetector {
  PlankDetector({required AngleCalculator angleCalculator}) : _angleCalculator = angleCalculator;

  final AngleCalculator _angleCalculator;

  DateTime? _holdStart;
  int _bestHoldSeconds = 0;

  @override
  String get id => 'plank';

  @override
  String get displayName => 'Plank';

  @override
  void reset() {
    _holdStart = null;
    _bestHoldSeconds = 0;
  }

  @override
  ExerciseResult? onPose(PoseEntity pose) {
    final shoulder = pose.landmark(PoseJoint.leftShoulder);
    final hip = pose.landmark(PoseJoint.leftHip);
    final ankle = pose.landmark(PoseJoint.leftAnkle);
    if (shoulder == null || hip == null || ankle == null) return null;

    final alignmentAngle = _angleCalculator.angleDegrees(shoulder, hip, ankle);
    final isAligned = alignmentAngle > 160;
    final now = pose.timestamp;

    if (isAligned) {
      _holdStart ??= now;
    } else {
      _holdStart = null;
    }

    final currentHoldSeconds = _holdStart == null ? 0 : now.difference(_holdStart!).inSeconds;
    if (currentHoldSeconds > _bestHoldSeconds) {
      _bestHoldSeconds = currentHoldSeconds;
    }

    final status = 'align ${alignmentAngle.toStringAsFixed(0)}° • ${isAligned ? 'hold' : 'reset'}';
    return ExerciseResult(
      detectorId: id,
      displayName: displayName,
      status: status,
      repetitions: 0,
      holdSeconds: currentHoldSeconds,
      updatedAt: now,
    );
  }
}

