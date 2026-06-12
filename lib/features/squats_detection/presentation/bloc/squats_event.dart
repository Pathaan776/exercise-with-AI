import 'dart:typed_data';

import 'package:equatable/equatable.dart';

sealed class SquatsEvent extends Equatable {
  const SquatsEvent();

  @override
  List<Object?> get props => [];
}

final class SquatsImageSelected extends SquatsEvent {
  const SquatsImageSelected({
    required this.imagePath,
    required this.imageBytes,
  });

  final String imagePath;
  final Uint8List imageBytes;

  @override
  List<Object?> get props => [imagePath, imageBytes];
}

final class SquatsReset extends SquatsEvent {
  const SquatsReset();
}
