import 'package:equatable/equatable.dart';

import 'package:fitcheck/features/workout/domain/entities/exercise_type.dart';

/// Where the athlete is in the movement.
enum ExercisePhase {
  /// No usable pose, or standing between sets.
  idle,

  /// Eccentric / lowering portion.
  down,

  /// Concentric / lockout portion.
  up,

  /// Isometric position is being held (plank).
  holding,
}

extension ExercisePhaseLabel on ExercisePhase {
  String get label => switch (this) {
    ExercisePhase.idle => 'Ready',
    ExercisePhase.down => 'Down',
    ExercisePhase.up => 'Up',
    ExercisePhase.holding => 'Holding',
  };
}

/// One measured joint angle, ready to render.
final class JointAngle extends Equatable {
  const JointAngle({
    required this.label,
    required this.degrees,
    this.isInRange = true,
  });

  final String label;
  final double degrees;

  /// False when the angle sits outside the target band for this exercise,
  /// which is what drives the red highlight in the UI.
  final bool isInRange;

  @override
  List<Object?> get props => [label, degrees, isInRange];
}

final class ExerciseAnalysis extends Equatable {
  const ExerciseAnalysis({
    required this.exercise,
    required this.hasPerson,
    required this.inPosition,
    required this.isCorrectForm,
    required this.formScore,
    required this.angles,
    required this.phase,
    required this.repsCorrect,
    required this.repsWrong,
    required this.holdSeconds,
    required this.bestHoldSeconds,
    required this.message,
    this.coachingTip,
  });

  factory ExerciseAnalysis.empty(ExerciseType exercise) => ExerciseAnalysis(
    exercise: exercise,
    hasPerson: false,
    inPosition: false,
    isCorrectForm: false,
    formScore: 0,
    angles: const [],
    phase: ExercisePhase.idle,
    repsCorrect: 0,
    repsWrong: 0,
    holdSeconds: 0,
    bestHoldSeconds: 0,
    message: 'Point the camera at your whole body',
  );

  final ExerciseType exercise;
  final bool hasPerson;

  /// True once the athlete is recognisably performing this movement, as
  /// opposed to merely standing in frame.
  final bool inPosition;
  final bool isCorrectForm;

  /// Form quality in the range 0..1.
  final double formScore;
  final List<JointAngle> angles;
  final ExercisePhase phase;
  final int repsCorrect;
  final int repsWrong;
  final int holdSeconds;
  final int bestHoldSeconds;
  final String message;

  /// Short, actionable correction shown when form slips.
  final String? coachingTip;

  int get totalReps => repsCorrect + repsWrong;

  /// Share of reps performed with acceptable form, 0..1.
  double get accuracy => totalReps == 0 ? 0 : repsCorrect / totalReps;

  ExerciseAnalysis copyWith({ExerciseType? exercise}) => ExerciseAnalysis(
    exercise: exercise ?? this.exercise,
    hasPerson: hasPerson,
    inPosition: inPosition,
    isCorrectForm: isCorrectForm,
    formScore: formScore,
    angles: angles,
    phase: phase,
    repsCorrect: repsCorrect,
    repsWrong: repsWrong,
    holdSeconds: holdSeconds,
    bestHoldSeconds: bestHoldSeconds,
    message: message,
    coachingTip: coachingTip,
  );

  @override
  List<Object?> get props => [
    exercise,
    hasPerson,
    inPosition,
    isCorrectForm,
    formScore,
    angles,
    phase,
    repsCorrect,
    repsWrong,
    holdSeconds,
    bestHoldSeconds,
    message,
    coachingTip,
  ];
}
