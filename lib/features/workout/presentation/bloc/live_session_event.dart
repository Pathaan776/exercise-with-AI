import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';

sealed class LiveSessionEvent extends Equatable {
  const LiveSessionEvent();

  @override
  List<Object?> get props => [];
}

final class LiveSessionStarted extends LiveSessionEvent {
  const LiveSessionStarted();
}

final class LiveSessionPaused extends LiveSessionEvent {
  const LiveSessionPaused();
}

final class LiveSessionReset extends LiveSessionEvent {
  const LiveSessionReset();
}

final class LiveSessionCameraReady extends LiveSessionEvent {
  const LiveSessionCameraReady({required this.isFrontCamera});

  final bool isFrontCamera;

  @override
  List<Object?> get props => [isFrontCamera];
}

final class LiveSessionCameraFailed extends LiveSessionEvent {
  const LiveSessionCameraFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class LiveSessionFrameCaptured extends LiveSessionEvent {
  const LiveSessionFrameCaptured({
    required this.image,
    required this.camera,
    required this.deviceOrientation,
  });

  final CameraImage image;
  final CameraDescription camera;
  final DeviceOrientation deviceOrientation;

  // Frames are high-frequency and never deduplicated, so identity comparison
  // is both correct and cheaper than comparing pixel buffers.
  @override
  List<Object?> get props => [identityHashCode(image)];
}
