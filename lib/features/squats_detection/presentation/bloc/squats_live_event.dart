import 'package:camera/camera.dart';

abstract class SquatsLiveEvent {}

class SquatsLiveStarted extends SquatsLiveEvent {}

class SquatsLiveStopped extends SquatsLiveEvent {}

class SquatsLiveFrameCaptured extends SquatsLiveEvent {
  final CameraImage image;
  final CameraDescription camera;

  SquatsLiveFrameCaptured(this.image, this.camera);
}