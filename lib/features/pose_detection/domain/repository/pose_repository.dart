import 'package:fitcheck/features/pose_detection/domain/entities/pose_entity.dart';

abstract interface class PoseRepository {
  Stream<PoseEntity> watchPoses();
  Future<void> start();
  Future<void> stop();
}

