import 'dart:math' as math;

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Builders for synthetic poses, so analyzer behaviour can be exercised
/// without a camera. Coordinates are in image space with y growing downward,
/// matching what ML Kit returns.

PoseLandmark _landmark(
  PoseLandmarkType type,
  double x,
  double y, {
  double likelihood = 0.95,
}) {
  return PoseLandmark(type: type, x: x, y: y, z: 0, likelihood: likelihood);
}

Pose _pose(List<PoseLandmark> landmarks) {
  return Pose(landmarks: {for (final l in landmarks) l.type: l});
}

/// Rotates [vector] by [degrees] and scales it to [length].
({double x, double y}) _rotate(
  ({double x, double y}) vector,
  double degrees,
  double length,
) {
  final magnitude = math.sqrt((vector.x * vector.x) + (vector.y * vector.y));
  final ux = vector.x / magnitude;
  final uy = vector.y / magnitude;

  final radians = degrees * math.pi / 180;
  final cos = math.cos(radians);
  final sin = math.sin(radians);

  return (
    x: ((ux * cos) - (uy * sin)) * length,
    y: ((ux * sin) + (uy * cos)) * length,
  );
}

/// Side-on squat with an exact [kneeAngle]. [torsoLean] tips the shoulders
/// forward past vertical, which is what a "chest down" fault looks like.
Pose squatPose({
  required double kneeAngle,
  double torsoLean = 0,
  double likelihood = 0.95,
}) {
  const knee = (x: 300.0, y: 500.0);
  const ankle = (x: 300.0, y: 700.0);

  // Knee→ankle points straight down; the thigh is that vector rotated by the
  // desired interior angle.
  final thigh = _rotate((x: 0.0, y: 1.0), kneeAngle, 200);
  final hip = (x: knee.x + thigh.x, y: knee.y + thigh.y);

  final torso = _rotate((x: 0.0, y: -1.0), torsoLean, 250);
  final shoulder = (x: hip.x + torso.x, y: hip.y + torso.y);

  return _pose([
    _landmark(
      PoseLandmarkType.leftShoulder,
      shoulder.x,
      shoulder.y,
      likelihood: likelihood,
    ),
    _landmark(PoseLandmarkType.leftHip, hip.x, hip.y, likelihood: likelihood),
    _landmark(
      PoseLandmarkType.leftKnee,
      knee.x,
      knee.y,
      likelihood: likelihood,
    ),
    _landmark(
      PoseLandmarkType.leftAnkle,
      ankle.x,
      ankle.y,
      likelihood: likelihood,
    ),
  ]);
}

/// Side-on push-up with an exact [elbowAngle]. [hipSag] drops the hips below
/// the shoulder→ankle line, in pixels.
Pose pushupPose({required double elbowAngle, double hipSag = 0}) {
  const shoulder = (x: 300.0, y: 300.0);
  final hip = (x: 550.0, y: 300.0 + hipSag);
  const ankle = (x: 800.0, y: 300.0);

  const elbow = (x: 250.0, y: 420.0);
  final upperArm = (x: shoulder.x - elbow.x, y: shoulder.y - elbow.y);
  final forearm = _rotate(upperArm, elbowAngle, 150);
  final wrist = (x: elbow.x + forearm.x, y: elbow.y + forearm.y);

  return _pose([
    _landmark(PoseLandmarkType.leftShoulder, shoulder.x, shoulder.y),
    _landmark(PoseLandmarkType.leftElbow, elbow.x, elbow.y),
    _landmark(PoseLandmarkType.leftWrist, wrist.x, wrist.y),
    _landmark(PoseLandmarkType.leftHip, hip.x, hip.y),
    _landmark(PoseLandmarkType.leftAnkle, ankle.x, ankle.y),
  ]);
}

/// Side-on plank. [hipSag] is positive for dropped hips, negative for piked.
Pose plankPose({double hipSag = 0}) {
  return _pose([
    _landmark(PoseLandmarkType.leftShoulder, 200, 300),
    _landmark(PoseLandmarkType.leftHip, 450, 300 + hipSag),
    _landmark(PoseLandmarkType.leftAnkle, 700, 300),
  ]);
}

/// Someone standing upright, side-on. The shoulder→hip→ankle line is just as
/// straight as a good plank, which is why orientation has to be checked too.
Pose standingPose() {
  return _pose([
    _landmark(PoseLandmarkType.leftShoulder, 300, 200),
    _landmark(PoseLandmarkType.leftHip, 300, 450),
    _landmark(PoseLandmarkType.leftAnkle, 300, 700),
  ]);
}
