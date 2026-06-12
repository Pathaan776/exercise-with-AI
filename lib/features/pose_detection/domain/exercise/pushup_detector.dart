import 'package:fitcheck/core/utils/angle_calculator.dart';
import 'package:fitcheck/features/pose_detection/domain/entities/pose_entity.dart';
import 'package:fitcheck/features/pose_detection/domain/exercise/exercise_detector.dart';
import 'package:fitcheck/features/pose_detection/domain/exercise/exercise_result.dart';

final class PushupDetector implements ExerciseDetector {
  PushupDetector({required AngleCalculator angleCalculator}) : _angleCalculator = angleCalculator;

  final AngleCalculator _angleCalculator;

  String? _stage;
  int _repetitions = 0;

  @override
  String get id => 'pushup';

  @override
  String get displayName => 'Push-up';

  @override
  void reset() {
    _stage = null;
    _repetitions = 0;
  }

  @override
  ExerciseResult? onPose(PoseEntity pose) {
    final shoulder = pose.landmark(PoseJoint.leftShoulder);
    final elbow = pose.landmark(PoseJoint.leftElbow);
    final wrist = pose.landmark(PoseJoint.leftWrist);
    if (shoulder == null || elbow == null || wrist == null) return null;

    final elbowAngle = _angleCalculator.angleDegrees(shoulder, elbow, wrist);
    final now = pose.timestamp;

    if (elbowAngle < 95) {
      _stage = 'down';
    } else if (elbowAngle > 160 && _stage == 'down') {
      _stage = 'up';
      _repetitions += 1;
    } else {
      _stage ??= 'up';
    }

    final status = 'elbow ${elbowAngle.toStringAsFixed(0)}° • ${_stage ?? '-'}';
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

