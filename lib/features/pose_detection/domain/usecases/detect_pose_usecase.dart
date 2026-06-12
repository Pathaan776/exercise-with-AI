import 'package:fitcheck/features/pose_detection/domain/entities/pose_entity.dart';
import 'package:fitcheck/features/pose_detection/domain/repository/pose_repository.dart';

final class DetectPoseUsecase {
  const DetectPoseUsecase(this._repository);
  final PoseRepository _repository;

  Stream<PoseEntity> call() => _repository.watchPoses();
}

