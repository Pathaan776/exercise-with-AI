
enum SquatPhase { up, down, unknown }

class SquatAnalysis {
  final bool hasPerson;
  final bool isSquatPose;
  final bool isCorrectForm;
  final double formScore;
  final double? kneeAngleDegrees;
  final double? hipAngleDegrees;
  final SquatPhase phase;
  final int repsCorrect;
  final int repsWrong;
  final String message;

  const SquatAnalysis({
    required this.hasPerson,
    required this.isSquatPose,
    required this.isCorrectForm,
    required this.formScore,
    required this.kneeAngleDegrees,
    required this.hipAngleDegrees,
    required this.phase,
    required this.repsCorrect,
    required this.repsWrong,
    required this.message,
  });

  factory SquatAnalysis.initial() {
    return const SquatAnalysis(
      hasPerson: false,
      isSquatPose: false,
      isCorrectForm: false,
      formScore: 0,
      kneeAngleDegrees: null,
      hipAngleDegrees: null,
      phase: SquatPhase.unknown,
      repsCorrect: 0,
      repsWrong: 0,
      message: "No data",
    );
  }
}