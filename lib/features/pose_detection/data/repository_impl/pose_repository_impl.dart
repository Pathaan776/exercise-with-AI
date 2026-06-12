import 'package:fitcheck/features/pose_detection/data/datasource/pose_datasource.dart';
import 'package:fitcheck/features/pose_detection/domain/entities/pose_entity.dart';
import 'package:fitcheck/features/pose_detection/domain/repository/pose_repository.dart';

final class PoseRepositoryImpl implements PoseRepository {
  const PoseRepositoryImpl(this._datasource);
  final PoseDatasource _datasource;

  @override
  Stream<PoseEntity> watchPoses() {
    return _datasource.watchPoses().map((model) => model.toEntity());
  }

  @override
  Future<void> start() => _datasource.start();

  @override
  Future<void> stop() => _datasource.stop();
}

