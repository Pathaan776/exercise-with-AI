import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'package:fitcheck/features/workout/presentation/models/skeleton_frame.dart';

const _bones = <(PoseLandmarkType, PoseLandmarkType)>[
  (PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder),
  (PoseLandmarkType.leftHip, PoseLandmarkType.rightHip),
  (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip),
  (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip),
  (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow),
  (PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist),
  (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow),
  (PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist),
  (PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee),
  (PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle),
  (PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee),
  (PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle),
];

/// Draws the detected skeleton over a photo or camera preview, tinted by
/// whether the current form passes.
class PoseOverlay extends StatelessWidget {
  const PoseOverlay({
    super.key,
    required this.frame,
    required this.isCorrectForm,
  });

  final SkeletonFrame frame;
  final bool isCorrectForm;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return IgnorePointer(
      child: CustomPaint(
        painter: _SkeletonPainter(
          frame: frame,
          color: isCorrectForm ? scheme.primary : scheme.error,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _SkeletonPainter extends CustomPainter {
  _SkeletonPainter({required this.frame, required this.color});

  final SkeletonFrame frame;
  final Color color;

  /// Landmarks below this confidence are noise and are not drawn.
  static const _minLikelihood = 0.35;

  @override
  void paint(Canvas canvas, Size size) {
    final image = frame.imageSize;
    if (image.isEmpty || size.isEmpty) return;

    // Matches BoxFit.contain, which is how both the photo and the camera
    // preview are laid out.
    final scale = math.min(
      size.width / image.width,
      size.height / image.height,
    );
    final dx = (size.width - (image.width * scale)) / 2;
    final dy = (size.height - (image.height * scale)) / 2;

    Offset project(SkeletonNode node) {
      final x = frame.mirrored ? image.width - node.x : node.x;
      return Offset((x * scale) + dx, (node.y * scale) + dy);
    }

    final byType = {for (final node in frame.nodes) node.type: node};

    final bonePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    final haloPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.18);

    for (final (a, b) in _bones) {
      final start = byType[a];
      final end = byType[b];
      if (start == null || end == null) continue;

      final confidence = math.min(start.likelihood, end.likelihood);
      if (confidence < _minLikelihood) continue;

      final from = project(start);
      final to = project(end);

      // The halo keeps the skeleton readable over bright or busy backgrounds.
      canvas.drawLine(from, to, haloPaint);
      canvas.drawLine(
        from,
        to,
        bonePaint..color = color.withValues(alpha: 0.45 + (0.55 * confidence)),
      );
    }

    final jointPaint = Paint()..style = PaintingStyle.fill;
    final jointCore = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;

    for (final node in byType.values) {
      if (node.likelihood < _minLikelihood) continue;
      final center = project(node);
      canvas.drawCircle(center, 6, jointPaint..color = color);
      canvas.drawCircle(center, 2.4, jointCore);
    }
  }

  @override
  bool shouldRepaint(covariant _SkeletonPainter old) =>
      old.frame != frame || old.color != color;
}
