import 'package:equatable/equatable.dart';
import 'package:fitcheck/features/pose_detection/domain/entities/pose_entity.dart';

sealed class PoseEvent extends Equatable {
  const PoseEvent();

  @override
  List<Object?> get props => [];
}

final class PoseStarted extends PoseEvent {
  const PoseStarted();
}

final class PoseStopped extends PoseEvent {
  const PoseStopped();
}

final class PoseReceived extends PoseEvent {
  const PoseReceived(this.pose);
  final PoseEntity pose;

  @override
  List<Object?> get props => [pose];
}

final class PoseFailed extends PoseEvent {
  const PoseFailed(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
