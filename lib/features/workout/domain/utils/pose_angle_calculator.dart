import 'dart:math' as math;

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Joint-angle maths over ML Kit landmarks.
///
/// Angles are computed in 2D image space on purpose: ML Kit's `z` is a coarse
/// relative depth estimate from a single camera and adding it makes the angles
/// noticeably noisier than dropping it.
class PoseAngleCalculator {
  const PoseAngleCalculator();

  /// Interior angle at [b], in degrees (0..180).
  double angleDegrees(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final abx = a.x - b.x;
    final aby = a.y - b.y;
    final cbx = c.x - b.x;
    final cby = c.y - b.y;

    final dot = (abx * cbx) + (aby * cby);
    final magnitude =
        math.sqrt((abx * abx) + (aby * aby)) *
        math.sqrt((cbx * cbx) + (cby * cby));
    if (magnitude == 0) return 0;

    return math.acos((dot / magnitude).clamp(-1.0, 1.0)) * (180 / math.pi);
  }

  /// How far [point] sits below the line [a]→[b], in pixels, measured
  /// vertically at the point's own position along that line.
  ///
  /// Positive means lower on screen — for a side-on plank, a sagging hip;
  /// negative is a piked hip. Measuring vertically rather than
  /// perpendicular keeps the sign stable when the image is mirrored, which
  /// the front camera does.
  double verticalOffsetFromLine(
    PoseLandmark a,
    PoseLandmark b,
    PoseLandmark point,
  ) {
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    final lengthSquared = (dx * dx) + (dy * dy);
    if (lengthSquared == 0) return 0;

    final t = (((point.x - a.x) * dx) + ((point.y - a.y) * dy)) / lengthSquared;
    return point.y - (a.y + (t * dy));
  }

  /// Straight-line distance between two landmarks, in pixels. Used to turn
  /// pixel offsets into body-relative ratios that survive a change of
  /// camera distance.
  double distance(PoseLandmark a, PoseLandmark b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return math.sqrt((dx * dx) + (dy * dy));
  }
}
