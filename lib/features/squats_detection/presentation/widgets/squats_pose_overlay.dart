import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fitcheck/features/squats_detection/presentation/bloc/squats_state.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

const _skeletonConnections = <List<PoseLandmarkType>>[
  [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
  [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
  [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
  [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
  [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
  [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
  [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
  [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
  [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
  [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
  [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
  [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
];

class SquatsPoseOverlay extends StatelessWidget {
  const SquatsPoseOverlay({
    super.key,
    required this.overlay,
    required this.isCorrect,
  });

  final SquatsOverlayData overlay;
  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SquatsPosePainter(overlay: overlay, isCorrect: isCorrect),
    );
  }
}

class _SquatsPosePainter extends CustomPainter {
  _SquatsPosePainter({required this.overlay, required this.isCorrect});

  final SquatsOverlayData overlay;
  final bool isCorrect;

  @override
  void paint(Canvas canvas, Size size) {
    final imageW = overlay.imageSize.width;
    final imageH = overlay.imageSize.height;
    if (imageW <= 0 || imageH <= 0) return;

    final scale = math.min(size.width / imageW, size.height / imageH);
    final dx = (size.width - (imageW * scale)) / 2;
    final dy = (size.height - (imageH * scale)) / 2;

    final color = isCorrect ? Colors.blueAccent : Colors.redAccent;
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final jointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final byType = <PoseLandmarkType, SquatsLandmark>{};
    for (final lm in overlay.landmarks) {
      byType[lm.type] = lm;
    }

    Offset mapPoint(SquatsLandmark lm) {
      return Offset((lm.x * scale) + dx, (lm.y * scale) + dy);
    }

    for (final pair in _skeletonConnections) {
      final a = byType[pair.first];
      final b = byType[pair.last];
      if (a == null || b == null) continue;
      final vis = math.min(a.visibility, b.visibility);
      if (vis < 0.3) continue;
      canvas.drawLine(
        mapPoint(a),
        mapPoint(b),
        linePaint
          ..color = color.withValues(alpha: (0.3 + (0.7 * vis)).clamp(0.3, 1)),
      );
    }

    for (final lm in byType.values) {
      final vis = lm.visibility.clamp(0.0, 1.0);
      if (vis < 0.15) continue;
      canvas.drawCircle(
        mapPoint(lm),
        6,
        jointPaint
          ..color = color.withValues(alpha: (0.2 + (0.8 * vis)).clamp(0.2, 1)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SquatsPosePainter oldDelegate) {
    return oldDelegate.overlay != overlay || oldDelegate.isCorrect != isCorrect;
  }
}
