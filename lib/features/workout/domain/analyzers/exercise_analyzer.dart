import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'package:fitcheck/features/workout/domain/entities/exercise_analysis.dart';
import 'package:fitcheck/features/workout/domain/entities/exercise_type.dart';
import 'package:fitcheck/features/workout/domain/utils/pose_angle_calculator.dart';

enum BodyPart { shoulder, elbow, wrist, hip, knee, ankle }

/// The six landmarks of one half of the body, resolved together so an
/// analyzer always reasons about a single consistent side.
final class BodySide {
  const BodySide({
    required this.isLeft,
    required this.parts,
    required this.confidence,
  });

  final bool isLeft;
  final Map<BodyPart, PoseLandmark> parts;

  /// Mean likelihood of the parts the analyzer asked for, 0..1.
  final double confidence;

  PoseLandmark operator [](BodyPart part) => parts[part]!;
}

/// Shared plumbing for the per-exercise analyzers: pose selection, side
/// selection, landmark confidence gating and angle smoothing.
///
/// Subclasses are stateful across frames (they count reps and track phase), so
/// each live session must call [reset] before it starts.
abstract class ExerciseAnalyzer {
  ExerciseAnalyzer({PoseAngleCalculator? angleCalculator})
    : angles = angleCalculator ?? const PoseAngleCalculator();

  final PoseAngleCalculator angles;

  ExerciseType get type;

  /// Landmarks that must be visible before a frame can be scored.
  List<BodyPart> get requiredParts;

  /// Clears rep counters and phase state.
  void reset();

  /// Scores a live frame. [now] drives hold timers, so callers should pass the
  /// frame's own timestamp rather than letting it default during replay.
  ExerciseAnalysis analyzeFrame(List<Pose> poses, {DateTime? now});

  /// Scores a single still image. Rep counters are meaningless here, so this
  /// reports posture quality only and never mutates the rep state.
  ExerciseAnalysis analyzeStill(List<Pose> poses);

  // --- shared helpers -------------------------------------------------------

  static const double _minLikelihood = 0.5;

  /// The pose with the most detected landmarks — a reasonable proxy for "the
  /// subject" when bystanders are partially in frame.
  Pose? bestPose(List<Pose> poses) {
    if (poses.isEmpty) return null;
    var best = poses.first;
    for (final pose in poses) {
      if (pose.landmarks.length > best.landmarks.length) best = pose;
    }
    return best;
  }

  /// Picks whichever side of the body is more confidently visible, requiring
  /// every part in [requiredParts]. Returns null when neither side is usable.
  BodySide? resolveSide(Pose pose) {
    final left = _side(pose, isLeft: true);
    final right = _side(pose, isLeft: false);

    if (left == null) return right;
    if (right == null) return left;
    return left.confidence >= right.confidence ? left : right;
  }

  BodySide? _side(Pose pose, {required bool isLeft}) {
    final resolved = <BodyPart, PoseLandmark>{};
    var total = 0.0;

    for (final part in requiredParts) {
      final landmark = pose.landmarks[_typeFor(part, isLeft)];
      if (landmark == null || landmark.likelihood < _minLikelihood) return null;
      resolved[part] = landmark;
      total += landmark.likelihood;
    }

    return BodySide(
      isLeft: isLeft,
      parts: resolved,
      confidence: requiredParts.isEmpty ? 0 : total / requiredParts.length,
    );
  }

  PoseLandmarkType _typeFor(BodyPart part, bool isLeft) => switch (part) {
    BodyPart.shoulder =>
      isLeft ? PoseLandmarkType.leftShoulder : PoseLandmarkType.rightShoulder,
    BodyPart.elbow =>
      isLeft ? PoseLandmarkType.leftElbow : PoseLandmarkType.rightElbow,
    BodyPart.wrist =>
      isLeft ? PoseLandmarkType.leftWrist : PoseLandmarkType.rightWrist,
    BodyPart.hip =>
      isLeft ? PoseLandmarkType.leftHip : PoseLandmarkType.rightHip,
    BodyPart.knee =>
      isLeft ? PoseLandmarkType.leftKnee : PoseLandmarkType.rightKnee,
    BodyPart.ankle =>
      isLeft ? PoseLandmarkType.leftAnkle : PoseLandmarkType.rightAnkle,
  };

  /// Exponential moving average. Pose estimates jitter frame to frame; without
  /// this the rep thresholds trigger on noise.
  double smooth(double current, double? previous, {double weight = 0.7}) {
    if (previous == null) return current;
    return (previous * weight) + (current * (1 - weight));
  }

  /// Maps a measurement onto 0..1, full marks at or past [best] and zero at or
  /// past [worst]. Works in either direction depending on which bound is larger.
  double ramp(double value, {required double best, required double worst}) {
    if (best == worst) return value == best ? 1 : 0;
    final t = (value - worst) / (best - worst);
    return t.clamp(0.0, 1.0);
  }

  /// Full marks anywhere inside [lowGood]..[highGood], tapering to zero at
  /// [lowFail] / [highFail]. Used where a joint has an acceptable *range*
  /// rather than a single ideal value.
  double plateau(
    double value, {
    required double lowFail,
    required double lowGood,
    required double highGood,
    required double highFail,
  }) {
    if (value >= lowGood && value <= highGood) return 1;
    if (value < lowGood) return ramp(value, best: lowGood, worst: lowFail);
    return ramp(value, best: highGood, worst: highFail);
  }
}
