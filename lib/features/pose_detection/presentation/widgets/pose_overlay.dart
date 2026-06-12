import 'package:flutter/material.dart';
import 'package:fitcheck/features/pose_detection/domain/entities/pose_entity.dart';

class PoseOverlay extends StatelessWidget {
  const PoseOverlay({super.key, required this.pose});

  final PoseEntity? pose;

  @override
  Widget build(BuildContext context) {
    final pose = this.pose;
    if (pose == null) return const SizedBox.shrink();
    return CustomPaint(painter: _PosePainter(pose));
  }
}

class _PosePainter extends CustomPainter {
  _PosePainter(this.pose);
  final PoseEntity pose;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.fill;

    for (final landmark in pose.landmarks.values) {
      final dx = (landmark.x.clamp(0, 1)) * size.width;
      final dy = (landmark.y.clamp(0, 1)) * size.height;
      canvas.drawCircle(Offset(dx, dy), 6, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PosePainter oldDelegate) =>
      oldDelegate.pose != pose;
}
