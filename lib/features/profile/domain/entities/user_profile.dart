import 'package:equatable/equatable.dart';

final class UserProfile extends Equatable {
  const UserProfile({
    required this.name,
    required this.dailyGoal,
    required this.useMetric,
    required this.totalReps,
    required this.totalSessions,
    required this.bestFormScore,
    required this.todayReps,
    this.heightCm,
    this.weightKg,
  });

  static const defaultName = 'Athlete';
  static const defaultDailyGoal = 40;

  final String name;

  /// Target reps per day, used by the Home ring.
  final int dailyGoal;
  final bool useMetric;
  final double? heightCm;
  final double? weightKg;

  final int totalReps;
  final int totalSessions;

  /// Best single-session form score, 0..1.
  final double bestFormScore;

  /// Good reps logged since midnight — what the Home ring measures.
  final int todayReps;

  /// Progress toward today's goal, 0..1 (clamped, so 120% reads as full).
  double get goalProgress =>
      dailyGoal == 0 ? 0 : (todayReps / dailyGoal).clamp(0.0, 1.0);

  /// First name only — what the greeting uses.
  String get shortName => name.trim().split(RegExp(r'\s+')).first;

  /// Up to two letters for the avatar.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String? get heightLabel {
    final cm = heightCm;
    if (cm == null) return null;
    if (useMetric) return '${cm.round()} cm';

    final totalInches = cm / 2.54;
    return "${(totalInches ~/ 12)}' ${(totalInches % 12).round()}\"";
  }

  String? get weightLabel {
    final kg = weightKg;
    if (kg == null) return null;
    return useMetric
        ? '${kg.toStringAsFixed(1)} kg'
        : '${(kg * 2.20462).round()} lb';
  }

  UserProfile copyWith({
    String? name,
    int? dailyGoal,
    bool? useMetric,
    double? heightCm,
    double? weightKg,
    int? totalReps,
    int? totalSessions,
    double? bestFormScore,
    int? todayReps,
  }) {
    return UserProfile(
      name: name ?? this.name,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      useMetric: useMetric ?? this.useMetric,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      totalReps: totalReps ?? this.totalReps,
      totalSessions: totalSessions ?? this.totalSessions,
      bestFormScore: bestFormScore ?? this.bestFormScore,
      todayReps: todayReps ?? this.todayReps,
    );
  }

  @override
  List<Object?> get props => [
    name,
    dailyGoal,
    useMetric,
    heightCm,
    weightKg,
    totalReps,
    totalSessions,
    bestFormScore,
    todayReps,
  ];
}
