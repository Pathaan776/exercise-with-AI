import 'dart:typed_data';

import 'package:equatable/equatable.dart';

sealed class ImageAnalysisEvent extends Equatable {
  const ImageAnalysisEvent();

  @override
  List<Object?> get props => [];
}

final class ImageAnalysisRequested extends ImageAnalysisEvent {
  const ImageAnalysisRequested({required this.path, required this.bytes});

  final String path;
  final Uint8List bytes;

  @override
  List<Object?> get props => [path, bytes.length];
}

final class ImageAnalysisCleared extends ImageAnalysisEvent {
  const ImageAnalysisCleared();
}
