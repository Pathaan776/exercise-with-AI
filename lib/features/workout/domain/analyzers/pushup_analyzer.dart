import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'package:fitcheck/features/workout/domain/analyzers/exercise_analyzer.dart';
import 'package:fitcheck/features/workout/domain/entities/exercise_analysis.dart';
import 'package:fitcheck/features/workout/domain/entities/exercise_type.dart';

/// Counts push-ups from elbow flexion and grades each rep on depth plus how
/// straight the body stayed from shoulder through hip to ankle.
class PushupAnalyzer extends ExerciseAnalyzer {
  PushupAnalyzer({super.angleCalculator});

  static const _downThreshold = 100.0;
  static const _upThreshold = 155.0;
  static const _passMark = 0.75;

  ExercisePhase _phase = ExercisePhase.idle;
  int _correct = 0;
  int _wrong = 0;

  double? _smoothedElbow;
  double? _smoothedBody;

  double? _minElbow;

  /// Worst (smallest) body angle seen during the current rep — a hip that sags
  /// only at the bottom still costs the rep its grade.
  double? _worstBody;

  @override
  ExerciseType get type => ExerciseType.pushup;

  @override
  List<BodyPart> get requiredParts => const [
    BodyPart.shoulder,
    BodyPart.elbow,
    BodyPart.wrist,
    BodyPart.hip,
    BodyPart.ankle,
  ];

  @override
  void reset() {
    _phase = ExercisePhase.idle;
    _correct = 0;
    _wrong = 0;
    _smoothedElbow = null;
    _smoothedBody = null;
    _minElbow = null;
    _worstBody = null;
  }

  @override
  ExerciseAnalysis analyzeFrame(List<Pose> poses, {DateTime? now}) {
    final side = _resolve(poses);
    if (side == null) return ExerciseAnalysis.empty(type);

    final elbow = smooth(_elbowAngle(side), _smoothedElbow);
    final body = smooth(_bodyAngle(side), _smoothedBody);
    _smoothedElbow = elbow;
    _smoothedBody = body;

    if (_phase == ExercisePhase.idle) {
      _phase = elbow < 120 ? ExercisePhase.down : ExercisePhase.up;
    }

    if (_worstBody == null || body < _worstBody!) _worstBody = body;

    if (elbow < _downThreshold) {
      _phase = ExercisePhase.down;
      if (_minElbow == null || elbow < _minElbow!) _minElbow = elbow;
    }

    if (elbow > _upThreshold && _phase == ExercisePhase.down) {
      final repScore = _score(
        elbowAngle: _minElbow ?? elbow,
        bodyAngle: _worstBody ?? body,
      );
      repScore >= _passMark ? _correct++ : _wrong++;

      _phase = ExercisePhase.up;
      _minElbow = null;
      _worstBody = null;
    }

    return _build(elbow: elbow, body: body, phase: _phase, live: true);
  }

  @override
  ExerciseAnalysis analyzeStill(List<Pose> poses) {
    final side = _resolve(poses);
    if (side == null) return ExerciseAnalysis.empty(type);

    final elbow = _elbowAngle(side);
    final body = _bodyAngle(side);
    return _build(
      elbow: elbow,
      body: body,
      phase: elbow < 120 ? ExercisePhase.down : ExercisePhase.up,
      live: false,
    );
  }

  BodySide? _resolve(List<Pose> poses) {
    final pose = bestPose(poses);
    if (pose == null || pose.landmarks.isEmpty) return null;
    return resolveSide(pose);
  }

  double _elbowAngle(BodySide side) => angles.angleDegrees(
    side[BodyPart.shoulder],
    side[BodyPart.elbow],
    side[BodyPart.wrist],
  );

  double _bodyAngle(BodySide side) => angles.angleDegrees(
    side[BodyPart.shoulder],
    side[BodyPart.hip],
    side[BodyPart.ankle],
  );

  double _score({required double elbowAngle, required double bodyAngle}) {
    final depth = ramp(elbowAngle, best: 85, worst: 135);
    final straight = ramp(bodyAngle, best: 172, worst: 140);
    return ((depth * 0.55) + (straight * 0.45)).clamp(0.0, 1.0);
  }

  ExerciseAnalysis _build({
    required double elbow,
    required double body,
    required ExercisePhase phase,
    required bool live,
  }) {
    final score = _score(elbowAngle: elbow, bodyAngle: body);
    final inPosition = body > 150 && elbow < 170;

    String? tip;
    if (body < 160) {
      tip = 'Brace your core — keep hips level with shoulders and heels.';
    } else if (phase == ExercisePhase.down && elbow > 110) {
      tip = 'Go deeper — bend the elbows past 90°.';
    }

    final message = live
        ? (_correct + _wrong == 0
              ? 'Get into position and start pressing'
              : '$_correct good · $_wrong to fix')
        : '${(score * 100).round()}% form · elbow ${elbow.toStringAsFixed(0)}°';

    return ExerciseAnalysis(
      exercise: type,
      hasPerson: true,
      inPosition: inPosition,
      isCorrectForm: score >= _passMark,
      formScore: score,
      angles: [
        JointAngle(label: 'Elbow', degrees: elbow, isInRange: elbow <= 100),
        JointAngle(label: 'Body', degrees: body, isInRange: body >= 160),
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
