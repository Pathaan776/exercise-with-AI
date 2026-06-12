import 'dart:math' as math;

import 'package:fitcheck/features/pose_detection/domain/entities/pose_entity.dart';

class AngleCalculator {
  const AngleCalculator();

  double angleDegrees(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final ab = _vector(from: b, to: a);
    final cb = _vector(from: b, to: c);

    final dot = (ab.dx * cb.dx) + (ab.dy * cb.dy) + (ab.dz * cb.dz);
    final mag = _magnitude(ab) * _magnitude(cb);
    if (mag == 0) return 0;

    final cosTheta = (dot / mag).clamp(-1.0, 1.0);
    final radians = math.acos(cosTheta);
    return radians * (180 / math.pi);
  }

  _Vec3 _vector({required PoseLandmark from, required PoseLandmark to}) {
    return _Vec3(to.x - from.x, to.y - from.y, to.z - from.z);
  }

  double _magnitude(_Vec3 v) => math.sqrt((v.dx * v.dx) + (v.dy * v.dy) + (v.dz * v.dz));
}

class _Vec3 {
  _Vec3(this.dx, this.dy, this.dz);
  final double dx;
  final double dy;
  final double dz;
}

