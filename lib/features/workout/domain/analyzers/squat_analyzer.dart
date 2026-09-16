import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'package:fitcheck/features/workout/domain/analyzers/exercise_analyzer.dart';
import 'package:fitcheck/features/workout/domain/entities/exercise_analysis.dart';
import 'package:fitcheck/features/workout/domain/entities/exercise_type.dart';

/// Counts squats from a side-on view using knee flexion, and grades each rep
/// on depth plus torso position at the bottom.
class SquatAnalyzer extends ExerciseAnalyzer {
  SquatAnalyzer({super.angleCalculator});

  static const _downThreshold = 110.0;
  static const _upThreshold = 150.0;
  static const _passMark = 0.75;

  ExercisePhase _phase = ExercisePhase.idle;
  int _correct = 0;
  int _wrong = 0;

  double? _smoothedKnee;
  double? _smoothedHip;

  /// Deepest knee angle reached during the current descent, and the torso
  /// angle measured at that moment — a rep is graded on these, not on the
  /// angles at lockout.
  double? _minKnee;
  double? _hipAtBottom;

  @override
  ExerciseType get type => ExerciseType.squat;

  @override
  List<BodyPart> get requiredParts => const [
    BodyPart.shoulder,
    BodyPart.hip,
    BodyPart.knee,
    BodyPart.ankle,
  ];

  @override
  void reset() {
    _phase = ExercisePhase.idle;
    _correct = 0;
    _wrong = 0;
    _smoothedKnee = null;
    _smoothedHip = null;
    _minKnee = null;
    _hipAtBottom = null;
  }

  @override
  ExerciseAnalysis analyzeFrame(List<Pose> poses, {DateTime? now}) {
    final side = _resolve(poses);
    if (side == null) return ExerciseAnalysis.empty(type);

    final knee = smooth(_kneeAngle(side), _smoothedKnee);
    final hip = smooth(_hipAngle(side), _smoothedHip);
    _smoothedKnee = knee;
    _smoothedHip = hip;

    if (_phase == ExercisePhase.idle) {
      _phase = knee < 120 ? ExercisePhase.down : ExercisePhase.up;
    }

    if (knee < _downThreshold) {
      _phase = ExercisePhase.down;
      if (_minKnee == null || knee < _minKnee!) {
        _minKnee = knee;
        _hipAtBottom = hip;
      }
    }

    if (knee > _upThreshold && _phase == ExercisePhase.down) {
      final repScore = _score(
        kneeAngle: _minKnee ?? knee,
        hipAngle: _hipAtBottom ?? hip,
      );
      repScore >= _passMark ? _correct++ : _wrong++;

      _phase = ExercisePhase.up;
      _minKnee = null;
      _hipAtBottom = null;
    }

    return _build(knee: knee, hip: hip, phase: _phase, live: true);
  }

  @override
  ExerciseAnalysis analyzeStill(List<Pose> poses) {
    final side = _resolve(poses);
    if (side == null) return ExerciseAnalysis.empty(type);

    final knee = _kneeAngle(side);
    final hip = _hipAngle(side);
    return _build(
      knee: knee,
      hip: hip,
      phase: knee < 120 ? ExercisePhase.down : ExercisePhase.up,
      live: false,
    );
  }

  BodySide? _resolve(List<Pose> poses) {
    final pose = bestPose(poses);
    if (pose == null || pose.landmarks.isEmpty) return null;
    return resolveSide(pose);
  }

  double _kneeAngle(BodySide side) => angles.angleDegrees(
    side[BodyPart.hip],
    side[BodyPart.knee],
    side[BodyPart.ankle],
  );

  double _hipAngle(BodySide side) => angles.angleDegrees(
    side[BodyPart.shoulder],
    side[BodyPart.hip],
    side[BodyPart.knee],
  );

  /// Depth is most of the grade; torso angle guards against folding forward
  /// to fake depth. The torso band is wide because a legitimate squat bottom
  /// closes the hip well past vertical.
  double _score({required double kneeAngle, required double hipAngle}) {
    final depth = ramp(kneeAngle, best: 90, worst: 145);
    final torso = plateau(
      hipAngle,
      lowFail: 25,
      lowGood: 55,
      highGood: 125,
      highFail: 175,
    );
    return ((depth * 0.65) + (torso * 0.35)).clamp(0.0, 1.0);
  }

  ExerciseAnalysis _build({
    required double knee,
    required double hip,
    required ExercisePhase phase,
    required bool live,
  }) {
    final score = _score(kneeAngle: knee, hipAngle: hip);
    final inPosition = knee < 130;

    String? tip;
    if (inPosition && knee > 110) {
      tip = 'Sink lower — aim for thighs parallel to the floor.';
    } else if (inPosition && hip < 50) {
      tip = 'Chest up. You are folding forward instead of sitting back.';
    }

    final message = live
        ? (_correct + _wrong == 0
              ? 'Ready — start your first rep'
              : '$_correct good · $_wrong to fix')
        : '${(score * 100).round()}% form · knee ${knee.toStringAsFixed(0)}°';

    return ExerciseAnalysis(
      exercise: type,
      hasPerson: true,
      inPosition: inPosition,
      isCorrectForm: score >= _passMark,
      formScore: score,
      angles: [
        JointAngle(label: 'Knee', degrees: knee, isInRange: knee <= 110),
        JointAngle(
          label: 'Hip',
          degrees: hip,
          isInRange: hip >= 50 && hip <= 175,
        ),
      ],
      phase: phase,
      repsCorrect: live ? _correct : 0,
      repsWrong: live ? _wrong : 0,
      holdSeconds: 0,
      bestHoldSeconds: 0,
      message: message,
      coachingTip: tip,
    );
  }
}
