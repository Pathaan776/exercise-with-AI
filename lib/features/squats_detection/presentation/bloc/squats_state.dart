import 'dart:typed_data';
import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:fitcheck/features/squats_detection/domain/entities/squat_analysis.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

final class SquatsLandmark extends Equatable {
  const SquatsLandmark({
    required this.type,
    required this.x,
    required this.y,
    required this.visibility,
  });

  final PoseLandmarkType type;
  final double x;
  final double y;
  final double visibility;

  @override
  List<Object?> get props => [type, x, y, visibility];
}

final class SquatsOverlayData extends Equatable {
  const SquatsOverlayData({required this.imageSize, required this.landmarks});

  final Size imageSize;
  final List<SquatsLandmark> landmarks;

  @override
  List<Object?> get props => [imageSize, landmarks];
}

final class SquatsState extends Equatable {
  const SquatsState({
    required this.isLoading,
    required this.analysis,
    required this.landmarkLines,
    this.overlay,
    this.imageBytes,
  });

  final bool isLoading;
  final Uint8List? imageBytes;
  final SquatAnalysis analysis;
  final List<String> landmarkLines;
  final SquatsOverlayData? overlay;

  SquatsState copyWith({
    bool? isLoading,
    Uint8List? imageBytes,
    SquatAnalysis? analysis,
    List<String>? landmarkLines,
    SquatsOverlayData? overlay,
  }) {
    return SquatsState(
      isLoading: isLoading ?? this.isLoading,
      imageBytes: imageBytes ?? this.imageBytes,
      analysis: analysis ?? this.analysis,
      landmarkLines: landmarkLines ?? this.landmarkLines,
      overlay: overlay ?? this.overlay,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    imageBytes,
    analysis,
    landmarkLines,
    overlay,
  ];

  static SquatsState initial() => SquatsState(
    isLoading: false,
    analysis: SquatAnalysis.initial(),
    landmarkLines: const [],
  );
}
