import 'dart:async';
import 'dart:math' as math;

import 'package:fitcheck/features/pose_detection/data/models/pose_model.dart';
import 'package:fitcheck/features/pose_detection/domain/entities/pose_entity.dart';

abstract interface class PoseDatasource {
  Stream<PoseModel> watchPoses();
  Future<void> start();
  Future<void> stop();
}

final class MockPoseDatasource implements PoseDatasource {
  MockPoseDatasource();

  final StreamController<PoseModel> _controller = StreamController<PoseModel>.broadcast();
  Timer? _timer;
  double _t = 0;

  @override
  Stream<PoseModel> watchPoses() => _controller.stream;

  @override
  Future<void> start() async {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) => _emitPose());
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
  }

  void _emitPose() {
    _t += 0.15;
    final kneeY = 0.6 * (0.5 + 0.5 * math.sin(_t));
    final elbowY = 0.6 * (0.5 + 0.5 * math.sin(_t + 1));
    final hipY = 0.15 * (0.5 + 0.5 * math.sin(_t + 2));

    final shoulder = const PoseLandmark(x: 0, y: 0);
    final hip = PoseLandmark(x: 0.5, y: hipY);
    final ankle = const PoseLandmark(x: 1, y: 0);

    final knee = PoseLandmark(x: 0.5, y: kneeY);
    final elbow = PoseLandmark(x: 0.5, y: elbowY);
    final wrist = const PoseLandmark(x: 1, y: 0);

    final now = DateTime.now();
    _controller.add(
      PoseModel(
        timestamp: now,
        landmarks: {
          PoseJoint.leftShoulder: shoulder,
          PoseJoint.rightShoulder: shoulder,
          PoseJoint.leftElbow: elbow,
          PoseJoint.rightElbow: elbow,
          PoseJoint.leftWrist: wrist,
          PoseJoint.rightWrist: wrist,
          PoseJoint.leftHip: hip,
          PoseJoint.rightHip: hip,
          PoseJoint.leftKnee: knee,
          PoseJoint.rightKnee: knee,
          PoseJoint.leftAnkle: ankle,
          PoseJoint.rightAnkle: ankle,
        },
      ),
    );
  }
}

