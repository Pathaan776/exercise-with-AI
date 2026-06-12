import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:fitcheck/features/squats_detection/domain/entities/squat_analysis.dart';
import 'package:fitcheck/features/squats_detection/domain/utils/pose_angle_calculator.dart';

class SquatAnalyzer {
  final PoseAngleCalculator _angleCalculator;

  SquatAnalyzer({PoseAngleCalculator? angleCalculator})
    : _angleCalculator = angleCalculator ?? const PoseAngleCalculator();

  SquatPhase _phase = SquatPhase.unknown;
  int _correct = 0;
  int _wrong = 0;

  double? _prevKnee;
  double? _prevHip;
  double? _minKnee;

  void reset() {
    _phase = SquatPhase.unknown;
    _correct = 0;
    _wrong = 0;
    _prevKnee = null;
    _prevHip = null;
    _minKnee = null;
  }

  SquatAnalysis analyzeFrame({required List<Pose> poses}) {
    final pose = _getBestPose(poses);

    if (pose == null || pose.landmarks.isEmpty) {
      return SquatAnalysis.initial();
    }

    final points = _getValidSide(pose);
    if (points == null) {
      return SquatAnalysis.initial();
    }

    final hip = points.$1;
    final knee = points.$2;
    final ankle = points.$3;
    final shoulder = points.$4;

    final rawKnee = _angleCalculator.angleDegrees(hip, knee, ankle);
    final rawHip = _angleCalculator.angleDegrees(shoulder, hip, knee);

    final kneeAngle = _smooth(rawKnee, _prevKnee);
    final hipAngle = _smooth(rawHip, _prevHip);

    _prevKnee = kneeAngle;
    _prevHip = hipAngle;

    // ✅ Phase init fix
    if (_phase == SquatPhase.unknown) {
      _phase = kneeAngle < 120 ? SquatPhase.down : SquatPhase.up;
    }

    final wentDown = kneeAngle < 110;
    final cameUp = kneeAngle > 150;

    if (wentDown) {
      _phase = SquatPhase.down;

      if (_minKnee == null || kneeAngle < _minKnee!) {
        _minKnee = kneeAngle;
      }
    }

    if (cameUp && _phase == SquatPhase.down) {
      final minKnee = _minKnee ?? 180;
      final repScore = _formScore(kneeAngle: minKnee, hipAngle: hipAngle);
      if (repScore >= 0.8) {
        _correct++;
      } else {
        _wrong++;
      }

      _phase = SquatPhase.up;
      _minKnee = null;
    }

    final score = _formScore(kneeAngle: kneeAngle, hipAngle: hipAngle);
    return SquatAnalysis(
      hasPerson: true,
      isSquatPose: kneeAngle < 130,
      isCorrectForm: score >= 0.8,
      formScore: score,
      kneeAngleDegrees: kneeAngle,
      hipAngleDegrees: hipAngle,
      phase: _phase,
      repsCorrect: _correct,
      repsWrong: _wrong,
      message:
          "knee ${kneeAngle.toStringAsFixed(0)}° • ok $_correct / wrong $_wrong",
    );
  }

  SquatAnalysis analyzeImage({required List<Pose> poses}) {
    final pose = _getBestPose(poses);
    if (pose == null || pose.landmarks.isEmpty) {
      return SquatAnalysis.initial();
    }

    final points = _getValidSide(pose);
    if (points == null) {
      return SquatAnalysis.initial();
    }

    final hip = points.$1;
    final knee = points.$2;
    final ankle = points.$3;
    final shoulder = points.$4;

    final kneeAngle = _angleCalculator.angleDegrees(hip, knee, ankle);
    final hipAngle = _angleCalculator.angleDegrees(shoulder, hip, knee);
    final score = _formScore(kneeAngle: kneeAngle, hipAngle: hipAngle);

    return SquatAnalysis(
      hasPerson: true,
      isSquatPose: kneeAngle < 130,
      isCorrectForm: score >= 0.8,
      formScore: score,
      kneeAngleDegrees: kneeAngle,
      hipAngleDegrees: hipAngle,
      phase: kneeAngle < 120 ? SquatPhase.down : SquatPhase.up,
      repsCorrect: 0,
      repsWrong: 0,
      message:
          "score ${(score * 100).round()}% • knee ${kneeAngle.toStringAsFixed(0)}°",
    );
  }

  // ✅ Best pose selection
  Pose? _getBestPose(List<Pose> poses) {
    if (poses.isEmpty) return null;

    Pose best = poses.first;

    for (final p in poses) {
      if (p.landmarks.length > best.landmarks.length) {
        best = p;
      }
    }

    return best;
  }

  // ✅ Stable side selection (LEFT or RIGHT)
  (PoseLandmark, PoseLandmark, PoseLandmark, PoseLandmark)? _getValidSide(
    Pose pose,
  ) {
    final left = _getSide(
      pose,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.leftShoulder,
    );

    final right = _getSide(
      pose,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.rightAnkle,
      PoseLandmarkType.rightShoulder,
    );

    if (left != null) return left;
    if (right != null) return right;

    return null;
  }

  (PoseLandmark, PoseLandmark, PoseLandmark, PoseLandmark)? _getSide(
    Pose pose,
    PoseLandmarkType hipType,
    PoseLandmarkType kneeType,
    PoseLandmarkType ankleType,
    PoseLandmarkType shoulderType,
  ) {
    final hip = _visible(pose, hipType);
    final knee = _visible(pose, kneeType);
    final ankle = _visible(pose, ankleType);
    final shoulder = _visible(pose, shoulderType);

    if (hip == null || knee == null || ankle == null || shoulder == null) {
      return null;
    }

    return (hip, knee, ankle, shoulder);
  }

  PoseLandmark? _visible(Pose pose, PoseLandmarkType type) {
    final lm = pose.landmarks[type]; // ✅ FIX

    if (lm == null) return null;

    if (lm.likelihood < 0.5) return null;

    return lm;
  }

  double _smooth(double current, double? prev) {
    if (prev == null) return current;
    return prev * 0.7 + current * 0.3;
  }

  double _formScore({required double kneeAngle, required double hipAngle}) {
    double score = 0.2;

    if (kneeAngle <= 95) {
      score += 0.45;
    } else if (kneeAngle <= 115) {
      score += 0.35;
    } else if (kneeAngle <= 130) {
      score += 0.2;
    }

    if (hipAngle <= 120) {
      score += 0.35;
    } else if (hipAngle <= 150) {
      score += 0.2;
    } else if (hipAngle <= 170) {
      score += 0.05;
    }

    if (score > 1) score = 1;
    if (score < 0) score = 0;
    return score;
  }
}
