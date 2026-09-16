import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'package:fitcheck/features/workout/domain/analyzers/exercise_analyzer.dart';
import 'package:fitcheck/features/workout/domain/entities/exercise_analysis.dart';
import 'package:fitcheck/features/workout/domain/entities/exercise_type.dart';

/// Times a plank hold and grades it on how straight the shoulder→hip→ankle
/// line stays, calling out sagging and piked hips separately.
class PlankAnalyzer extends ExerciseAnalyzer {
  PlankAnalyzer({super.angleCalculator});

  static const _alignedThreshold = 160.0;
  static const _passMark = 0.75;

  /// A hold survives this much wobble before the timer resets, so a single
  /// bad frame from pose jitter does not wipe out a legitimate hold.
  static const _graceWindow = Duration(milliseconds: 900);

  DateTime? _holdStart;
  DateTime? _brokeAt;
  int _bestHold = 0;

  double? _smoothedBody;
  double? _smoothedSag;

  @override
  ExerciseType get type => ExerciseType.plank;

  @override
  List<BodyPart> get requiredParts => const [
    BodyPart.shoulder,
    BodyPart.hip,
    BodyPart.ankle,
  ];

  @override
  void reset() {
    _holdStart = null;
    _brokeAt = null;
    _bestHold = 0;
    _smoothedBody = null;
    _smoothedSag = null;
  }

  @override
  ExerciseAnalysis analyzeFrame(List<Pose> poses, {DateTime? now}) {
    final timestamp = now ?? DateTime.now();
    final side = _resolve(poses);
    if (side == null) {
      _breakHold(timestamp, force: true);
      return ExerciseAnalysis.empty(type);
    }

    final body = smooth(_bodyAngle(side), _smoothedBody);
    final sag = smooth(_sagRatio(side), _smoothedSag);
    _smoothedBody = body;
    _smoothedSag = sag;

    final horizontal = _isHorizontal(side);
    final aligned =
        horizontal && body >= _alignedThreshold && sag.abs() <= 0.35;
    if (aligned) {
      _holdStart ??= timestamp;
      _brokeAt = null;
    } else {
      _breakHold(timestamp);
    }

    final held = _holdStart == null
        ? 0
        : timestamp.difference(_holdStart!).inSeconds;
    if (held > _bestHold) _bestHold = held;

    return _build(
      body: body,
      sag: sag,
      horizontal: horizontal,
      holdSeconds: held,
      phase: aligned ? ExercisePhase.holding : ExercisePhase.idle,
      live: true,
    );
  }

  @override
  ExerciseAnalysis analyzeStill(List<Pose> poses) {
    final side = _resolve(poses);
    if (side == null) return ExerciseAnalysis.empty(type);

    final body = _bodyAngle(side);
    final sag = _sagRatio(side);
    final horizontal = _isHorizontal(side);
    return _build(
      body: body,
      sag: sag,
      horizontal: horizontal,
      holdSeconds: 0,
      phase: horizontal && body >= _alignedThreshold
          ? ExercisePhase.holding
          : ExercisePhase.idle,
      live: false,
    );
  }

  /// Ends the current hold, but only once the wobble has outlasted
  /// [_graceWindow]. [force] skips the grace period, for when the athlete
  /// leaves the frame entirely.
  void _breakHold(DateTime now, {bool force = false}) {
    if (_holdStart == null) return;

    if (force) {
      _holdStart = null;
      _brokeAt = null;
      return;
    }

    _brokeAt ??= now;
    if (now.difference(_brokeAt!) >= _graceWindow) {
      _holdStart = null;
      _brokeAt = null;
    }
  }

  BodySide? _resolve(List<Pose> poses) {
    final pose = bestPose(poses);
    if (pose == null || pose.landmarks.isEmpty) return null;
    return resolveSide(pose);
  }

  /// A plank is a horizontal hold. Without this check, standing upright also
  /// produces a straight shoulder-hip-ankle line and would score as a
  /// flawless plank.
  bool _isHorizontal(BodySide side) {
    final shoulder = side[BodyPart.shoulder];
    final ankle = side[BodyPart.ankle];
    return (ankle.x - shoulder.x).abs() > (ankle.y - shoulder.y).abs();
  }

  double _bodyAngle(BodySide side) => angles.angleDegrees(
    side[BodyPart.shoulder],
    side[BodyPart.hip],
    side[BodyPart.ankle],
  );

  /// Hip drop as a fraction of torso length: positive sags, negative pikes.
  /// Normalising by the torso keeps the reading stable as the athlete moves
  /// nearer to or further from the camera.
  double _sagRatio(BodySide side) {
    final shoulder = side[BodyPart.shoulder];
    final hip = side[BodyPart.hip];
    final ankle = side[BodyPart.ankle];

    final torso = angles.distance(shoulder, hip);
    if (torso == 0) return 0;

    return angles.verticalOffsetFromLine(shoulder, ankle, hip) / torso;
  }

  double _score({required double bodyAngle, required double sag}) {
    final straight = ramp(bodyAngle, best: 175, worst: 140);
    final level = ramp(sag.abs(), best: 0.05, worst: 0.45);
    return ((straight * 0.65) + (level * 0.35)).clamp(0.0, 1.0);
  }

  ExerciseAnalysis _build({
    required double body,
    required double sag,
    required bool horizontal,
    required int holdSeconds,
    required ExercisePhase phase,
    required bool live,
  }) {
    final score = _score(bodyAngle: body, sag: sag);
    // Deliberately loose on the body angle: a sagging plank is still a plank,
    // and it is precisely the position that needs coaching.
    final inPosition = horizontal && body >= 115;

    String? tip;
    if (inPosition && sag > 0.18) {
      tip = 'Hips are dropping — squeeze your glutes and brace.';
    } else if (inPosition && sag < -0.18) {
      tip = 'Hips are too high — lower them into line with your shoulders.';
    }

    final message = live
        ? (phase == ExercisePhase.holding
              ? 'Holding ${_format(holdSeconds)} · best ${_format(_bestHold)}'
              : (inPosition
                    ? 'Straighten up to start the timer'
                    : 'Get into a plank position'))
        : '${(score * 100).round()}% form · body ${body.toStringAsFixed(0)}°';

    return ExerciseAnalysis(
      exercise: type,
      hasPerson: true,
      inPosition: inPosition,
      isCorrectForm: score >= _passMark,
      formScore: score,
      angles: [
        JointAngle(
          label: 'Body',
          degrees: body,
          isInRange: body >= _alignedThreshold,
        ),
        JointAngle(
          label: 'Hip',
          degrees: (sag * 100).abs(),
          isInRange: sag.abs() <= 0.18,
        ),
      ],
      phase: phase,
      repsCorrect: 0,
      repsWrong: 0,
      holdSeconds: live ? holdSeconds : 0,
      bestHoldSeconds: live ? _bestHold : 0,
      message: message,
      coachingTip: tip,
    );
  }

  static String _format(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return m > 0 ? '${m}m ${s}s' : '${s}s';
  }
}
