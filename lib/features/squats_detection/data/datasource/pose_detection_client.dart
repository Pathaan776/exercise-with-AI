import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

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

  Future<List<Pose>> detectStream(
    CameraImage image,
    CameraDescription camera,
  ) async {
    final inputImage = _inputImageFromCameraImage(image, camera);
    if (inputImage == null) return const [];
    try {
      return await _streamDetector.processImage(inputImage);
    } catch (_) {
      return const [];
    }
  }

  Future<List<Pose>> detectFile(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    return _imageDetector.processImage(inputImage);
  }

  Future<void> dispose() async {
    await _streamDetector.close();
    await _imageDetector.close();
  }

  InputImage? _inputImageFromCameraImage(
    CameraImage image,
    CameraDescription camera,
  ) {
    final rotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
        InputImageRotation.rotation0deg;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final Size size = Size(image.width.toDouble(), image.height.toDouble());

    if (format == InputImageFormat.nv21) {
      final bytes = image.planes.first.bytes;
      final metadata = InputImageMetadata(
        size: size,
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes.first.bytesPerRow,
      );
      return InputImage.fromBytes(bytes: bytes, metadata: metadata);
    }

    if (format == InputImageFormat.yuv_420_888) {
      final bytes = _yuv420ToNv21(image);
      final metadata = InputImageMetadata(
        size: size,
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: image.width,
      );
      return InputImage.fromBytes(bytes: bytes, metadata: metadata);
    }

    return null;
  }

  Uint8List _yuv420ToNv21(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final yBytes = yPlane.bytes;
    final uBytes = uPlane.bytes;
    final vBytes = vPlane.bytes;

    final yRowStride = yPlane.bytesPerRow;
    final uvRowStride = uPlane.bytesPerRow;
    final uvPixelStride = uPlane.bytesPerPixel ?? 1;

    final out = Uint8List((width * height) + (width * height ~/ 2));

    var outIndex = 0;
    for (int row = 0; row < height; row++) {
      final rowStart = row * yRowStride;
      out.setRange(outIndex, outIndex + width, yBytes, rowStart);
      outIndex += width;
    }

    final uvHeight = height ~/ 2;
    final uvWidth = width ~/ 2;
    for (int row = 0; row < uvHeight; row++) {
      final rowStart = row * uvRowStride;
      for (int col = 0; col < uvWidth; col++) {
        final uvIndex = rowStart + (col * uvPixelStride);
        out[outIndex++] = vBytes[uvIndex];
        out[outIndex++] = uBytes[uvIndex];
      }
    }

    return out;
  }
}
