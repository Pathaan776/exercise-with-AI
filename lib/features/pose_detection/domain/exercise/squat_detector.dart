import 'package:fitcheck/core/utils/angle_calculator.dart';
import 'package:fitcheck/features/pose_detection/domain/entities/pose_entity.dart';
import 'package:fitcheck/features/pose_detection/domain/exercise/exercise_detector.dart';
import 'package:fitcheck/features/pose_detection/domain/exercise/exercise_result.dart';

final class SquatDetector implements ExerciseDetector {
  SquatDetector({required AngleCalculator angleCalculator}) : _angleCalculator = angleCalculator;

  final AngleCalculator _angleCalculator;

  String? _stage;
  int _repetitions = 0;

  @override
  String get id => 'squat';

  @override
  String get displayName => 'Squat';

  @override
  void reset() {
    _stage = null;
    _repetitions = 0;
  }

  @override
  ExerciseResult? onPose(PoseEntity pose) {
    final hip = pose.landmark(PoseJoint.leftHip);
    final knee = pose.landmark(PoseJoint.leftKnee);
    final ankle = pose.landmark(PoseJoint.leftAnkle);
    if (hip == null || knee == null || ankle == null) return null;

    final kneeAngle = _angleCalculator.angleDegrees(hip, knee, ankle);
    final now = pose.timestamp;

    if (kneeAngle < 95) {
      _stage = 'down';
    } else if (kneeAngle > 160 && _stage == 'down') {
      _stage = 'up';
      _repetitions += 1;
    } else {
      _stage ??= 'up';
    }

    final status = 'knee ${kneeAngle.toStringAsFixed(0)}° • ${_stage ?? '-'}';
    return ExerciseResult(
      detectorId: id,
      displayName: displayName,
      status: status,
      repetitions: _repetitions,
      holdSeconds: 0,
      updatedAt: now,
    );
  }
}

