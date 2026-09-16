import 'package:fitcheck/features/workout/domain/analyzers/exercise_analyzer.dart';
import 'package:fitcheck/features/workout/domain/analyzers/plank_analyzer.dart';
import 'package:fitcheck/features/workout/domain/analyzers/pushup_analyzer.dart';
import 'package:fitcheck/features/workout/domain/analyzers/squat_analyzer.dart';
import 'package:fitcheck/features/workout/domain/entities/exercise_type.dart';

/// Builds a fresh analyzer per session. Analyzers carry rep counters and phase
/// state across frames, so they must never be shared between two screens.
class ExerciseAnalyzerFactory {
  const ExerciseAnalyzerFactory();

  ExerciseAnalyzer create(ExerciseType type) => switch (type) {
    ExerciseType.squat => SquatAnalyzer(),
    ExerciseType.pushup => PushupAnalyzer(),
    ExerciseType.plank => PlankAnalyzer(),
  };
}
