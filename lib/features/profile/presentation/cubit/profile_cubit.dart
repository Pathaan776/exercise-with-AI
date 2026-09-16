import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fitcheck/core/storage/app_preferences.dart';
import 'package:fitcheck/features/profile/domain/entities/user_profile.dart';

/// Owns the athlete's details and lifetime totals, persisting every change.
class ProfileCubit extends Cubit<UserProfile> {
  ProfileCubit(this._prefs)
    : super(
        UserProfile(
          name: _prefs.name ?? UserProfile.defaultName,
          dailyGoal: _prefs.dailyGoal ?? UserProfile.defaultDailyGoal,
          useMetric: _prefs.useMetric ?? true,
          heightCm: _prefs.heightCm,
          weightKg: _prefs.weightKg,
          totalReps: _prefs.totalReps,
          totalSessions: _prefs.totalSessions,
          bestFormScore: _prefs.bestFormScore,
          // Yesterday's count must not carry over into today's ring.
          todayReps: _prefs.todayDate == _dayKey(DateTime.now())
              ? _prefs.todayReps
              : 0,
        ),
      );

  final AppPreferences _prefs;

  /// Local calendar day, as `yyyy-mm-dd`.
  static String _dayKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Future<void> updateName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == state.name) return;
    emit(state.copyWith(name: trimmed));
    await _prefs.setName(trimmed);
  }

  Future<void> updateDailyGoal(int goal) async {
    final clamped = goal.clamp(5, 500).toInt();
    if (clamped == state.dailyGoal) return;
    emit(state.copyWith(dailyGoal: clamped));
    await _prefs.setDailyGoal(clamped);
  }

  Future<void> updateUseMetric(bool useMetric) async {
    if (useMetric == state.useMetric) return;
    emit(state.copyWith(useMetric: useMetric));
    await _prefs.setUseMetric(useMetric);
  }

  Future<void> updateMeasurements({double? heightCm, double? weightKg}) async {
    emit(state.copyWith(heightCm: heightCm, weightKg: weightKg));
    if (heightCm != null) await _prefs.setHeightCm(heightCm);
    if (weightKg != null) await _prefs.setWeightKg(weightKg);
  }

  /// Folds a finished session into the lifetime totals and today's count. A
  /// session with no reps (a plank, or one abandoned before the first rep)
  /// still counts as a session so the average stays honest.
  Future<void> recordSession({
    required int reps,
    required double formScore,
  }) async {
    final earned = math.max<int>(0, reps);
    final totalReps = state.totalReps + earned;
    final totalSessions = state.totalSessions + 1;
    final best = math.max<double>(
      state.bestFormScore,
      formScore.clamp(0.0, 1.0),
    );

    // Recomputed rather than read from state, in case the app has been open
    // across midnight.
    final today = _dayKey(DateTime.now());
    final todayReps =
        (_prefs.todayDate == today ? _prefs.todayReps : 0) + earned;

    emit(
      state.copyWith(
        totalReps: totalReps,
        totalSessions: totalSessions,
        bestFormScore: best,
        todayReps: todayReps,
      ),
    );

    await _prefs.setTotalReps(totalReps);
    await _prefs.setTotalSessions(totalSessions);
    await _prefs.setBestFormScore(best);
    await _prefs.setToday(today, todayReps);
  }

  Future<void> resetStats() async {
    emit(
      state.copyWith(
        totalReps: 0,
        totalSessions: 0,
        bestFormScore: 0,
        todayReps: 0,
      ),
    );
    await _prefs.setTotalReps(0);
    await _prefs.setTotalSessions(0);
    await _prefs.setBestFormScore(0);
    await _prefs.setToday(_dayKey(DateTime.now()), 0);
  }
}
