import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Detected poses together with the coordinate space their landmarks live in,
/// which the overlay painter needs in order to map them onto the preview.
class PoseFrameResult {
  const PoseFrameResult({required this.poses, required this.imageSize});

  const PoseFrameResult.empty() : poses = const [], imageSize = Size.zero;

  final List<Pose> poses;
  final Size imageSize;

  bool get isEmpty => poses.isEmpty;
}

/// Wraps ML Kit pose detection. Holds two detectors because the streaming and
/// single-image modes trade accuracy against latency differently, and switching
/// a detector's mode at runtime is not supported.
class PoseDetectionClient {
  PoseDetectionClient()
    : _streamDetector = PoseDetector(
        options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
      ),
      _imageDetector = PoseDetector(
        options: PoseDetectorOptions(mode: PoseDetectionMode.single),
      );

  final PoseDetector _streamDetector;
  final PoseDetector _imageDetector;

  /// Rotation the camera plugin reports for each device orientation.
  static const _orientationDegrees = <DeviceOrientation, int>{
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  Future<PoseFrameResult> detectStream(
    CameraImage image,
    CameraDescription camera,
    DeviceOrientation deviceOrientation,
  ) async {
    final input = _toInputImage(image, camera, deviceOrientation);
    if (input == null) return const PoseFrameResult.empty();

    try {
      final poses = await _streamDetector.processImage(input);
      return PoseFrameResult(
        poses: poses,
        imageSize: _rotatedSize(input.metadata!),
      );
    } catch (_) {
      // A dropped frame is not worth surfacing; the next one arrives in ~30ms.
      return const PoseFrameResult.empty();
    }
  }

  Future<List<Pose>> detectFile(String imagePath) {
    return _imageDetector.processImage(InputImage.fromFilePath(imagePath));
  }

  Future<void> dispose() async {
    await _streamDetector.close();
    await _imageDetector.close();
  }

  /// ML Kit reports landmarks in the upright image, so a quarter turn swaps
  /// the axes.
  Size _rotatedSize(InputImageMetadata metadata) {
    final isQuarterTurn =
        metadata.rotation == InputImageRotation.rotation90deg ||
        metadata.rotation == InputImageRotation.rotation270deg;
    return isQuarterTurn
        ? Size(metadata.size.height, metadata.size.width)
        : metadata.size;
  }

  InputImage? _toInputImage(
    CameraImage image,
    CameraDescription camera,
    DeviceOrientation deviceOrientation,
  ) {
    final rotation = _resolveRotation(camera, deviceOrientation);
    if (rotation == null) return null;

    final size = Size(image.width.toDouble(), image.height.toDouble());
    final format = InputImageFormatValue.fromRawValue(image.format.raw);

    // iOS delivers BGRA8888 and Android delivers NV21 (or YUV420 on older
    // devices, which is converted below) — anything else is unsupported.
    if (format == InputImageFormat.bgra8888 ||
        format == InputImageFormat.nv21) {
      return InputImage.fromBytes(
        bytes: image.planes.first.bytes,
        metadata: InputImageMetadata(
          size: size,
          rotation: rotation,
          format: format!,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    }

    if (format == InputImageFormat.yuv_420_888 && image.planes.length >= 3) {
      return InputImage.fromBytes(
        bytes: _yuv420ToNv21(image),
        metadata: InputImageMetadata(
          size: size,
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: image.width,
        ),
      );
    }

    return null;
  }

  /// Combines the sensor's fixed mounting angle with how the device is being
  /// held. Without this the landmarks are rotated 90° in portrait, which
  /// silently wrecks every joint angle.
  InputImageRotation? _resolveRotation(
    CameraDescription camera,
    DeviceOrientation deviceOrientation,
  ) {
    if (Platform.isIOS) {
      return InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    }

    final deviceDegrees = _orientationDegrees[deviceOrientation];
    if (deviceDegrees == null) return null;

    // The front camera is mirrored, so its compensation runs the other way.
    final compensated = camera.lensDirection == CameraLensDirection.front
        ? (camera.sensorOrientation + deviceDegrees) % 360
        : (camera.sensorOrientation - deviceDegrees + 360) % 360;

    return InputImageRotationValue.fromRawValue(compensated);
  }

  Uint8List _yuv420ToNv21(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final yRowStride = yPlane.bytesPerRow;
    final uvRowStride = uPlane.bytesPerRow;
    final uvPixelStride = uPlane.bytesPerPixel ?? 1;

    final out = Uint8List((width * height) + (width * height ~/ 2));
    var outIndex = 0;

    for (var row = 0; row < height; row++) {
      out.setRange(outIndex, outIndex + width, yPlane.bytes, row * yRowStride);
      outIndex += width;
    }

    final uvHeight = height ~/ 2;
    final uvWidth = width ~/ 2;
    for (var row = 0; row < uvHeight; row++) {
      final rowStart = row * uvRowStride;
      for (var col = 0; col < uvWidth; col++) {
        final uvIndex = rowStart + (col * uvPixelStride);
        out[outIndex++] = vPlane.bytes[uvIndex];
        out[outIndex++] = uPlane.bytes[uvIndex];
      }
    }

    return out;
  }
}
