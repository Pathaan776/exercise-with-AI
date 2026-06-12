import 'package:equatable/equatable.dart';

final class ExerciseResult extends Equatable {
  const ExerciseResult({
    required this.detectorId,
    required this.displayName,
    required this.status,
    required this.repetitions,
    required this.holdSeconds,
    required this.updatedAt,
  });

  final String detectorId;
  final String displayName;
  final String status;
  final int repetitions;
  final int holdSeconds;
  final DateTime updatedAt;

  ExerciseResult copyWith({
    String? status,
    int? repetitions,
    int? holdSeconds,
    DateTime? updatedAt,
  }) {
    return ExerciseResult(
      detectorId: detectorId,
      displayName: displayName,
      status: status ?? this.status,
      repetitions: repetitions ?? this.repetitions,
      holdSeconds: holdSeconds ?? this.holdSeconds,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [detectorId, displayName, status, repetitions, holdSeconds, updatedAt];
}

