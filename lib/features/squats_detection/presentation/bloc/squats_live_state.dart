import '../../domain/entities/squat_analysis.dart';

class SquatsLiveState {
  final bool isRunning;
  final SquatAnalysis analysis;

  const SquatsLiveState({
    required this.isRunning,
    required this.analysis,
  });

  factory SquatsLiveState.initial() {
    return SquatsLiveState(
      isRunning: false,
      analysis: SquatAnalysis.initial(),
    );
  }

  SquatsLiveState copyWith({
    bool? isRunning,
    SquatAnalysis? analysis,
  }) {
    return SquatsLiveState(
      isRunning: isRunning ?? this.isRunning,
      analysis: analysis ?? this.analysis,
    );
  }
}