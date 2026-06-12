import 'dart:math';
import 'dart:ui';

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseAngleCalculator {
  const PoseAngleCalculator();

  double angleDegrees(
    PoseLandmark a,
    PoseLandmark b,
    PoseLandmark c,
  ) {
    final ab = Offset(a.x - b.x, a.y - b.y);
    final cb = Offset(c.x - b.x, c.y - b.y);

    final dot = (ab.dx * cb.dx + ab.dy * cb.dy);
    final magnitude = ab.distance * cb.distance;

    if (magnitude == 0) return 0;

    final angle = acos(dot / magnitude);

    return angle * (180 / pi);
  }
}