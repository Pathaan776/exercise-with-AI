import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitcheck/core/storage/app_preferences.dart';
import 'package:fitcheck/features/profile/presentation/cubit/profile_cubit.dart';

String _dayKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

Future<ProfileCubit> _cubit() async =>
    ProfileCubit(await AppPreferences.create());

void main() {
  test('starts with sensible defaults', () async {
    SharedPreferences.setMockInitialValues({});
    final cubit = await _cubit();

    expect(cubit.state.name, 'Athlete');
    expect(cubit.state.dailyGoal, 40);
    expect(cubit.state.todayReps, 0);
    expect(cubit.state.goalProgress, 0);
  });

  test('a session adds to both today and the lifetime totals', () async {
    SharedPreferences.setMockInitialValues({});
    final cubit = await _cubit();

    await cubit.recordSession(reps: 12, formScore: 0.9);
    await cubit.recordSession(reps: 8, formScore: 0.7);

    expect(cubit.state.totalSessions, 2);
    expect(cubit.state.totalReps, 20);
    expect(cubit.state.todayReps, 20);
    expect(cubit.state.bestFormScore, 0.9, reason: 'best score is kept');
    expect(cubit.state.goalProgress, closeTo(0.5, 0.0001));
  });

  test("yesterday's reps do not carry into today's ring", () async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    SharedPreferences.setMockInitialValues({
      'stats_today_reps': 35,
      'stats_today_date': _dayKey(yesterday),
      'stats_total_reps': 35,
      'stats_total_sessions': 2,
    });

    final cubit = await _cubit();

    expect(cubit.state.todayReps, 0);
    expect(cubit.state.totalReps, 35, reason: 'lifetime totals still stand');
  });

  test('goal progress is capped at 100%', () async {
    SharedPreferences.setMockInitialValues({});
    final cubit = await _cubit();

    await cubit.updateDailyGoal(10);
    await cubit.recordSession(reps: 40, formScore: 0.8);

    expect(cubit.state.goalProgress, 1.0);
  });

  test('settings persist across a restart', () async {
    SharedPreferences.setMockInitialValues({});
    final cubit = await _cubit();

    await cubit.updateName('  Rahish Khan  ');
    await cubit.updateDailyGoal(60);
    await cubit.updateUseMetric(false);
    await cubit.updateMeasurements(heightCm: 178, weightKg: 74.5);

    final reloaded = await _cubit();

    expect(reloaded.state.name, 'Rahish Khan');
    expect(reloaded.state.initials, 'RK');
    expect(reloaded.state.dailyGoal, 60);
    expect(reloaded.state.useMetric, isFalse);
    expect(reloaded.state.heightLabel, "5' 10\"");
    expect(reloaded.state.weightLabel, '164 lb');
  });

  test('the daily goal is clamped to a usable range', () async {
    SharedPreferences.setMockInitialValues({});
    final cubit = await _cubit();

    await cubit.updateDailyGoal(0);
    expect(cubit.state.dailyGoal, 5);

    await cubit.updateDailyGoal(10000);
    expect(cubit.state.dailyGoal, 500);
  });

  test('resetting stats clears today as well as the totals', () async {
    SharedPreferences.setMockInitialValues({});
    final cubit = await _cubit();

    await cubit.recordSession(reps: 15, formScore: 0.95);
    await cubit.resetStats();

    expect(cubit.state.totalReps, 0);
    expect(cubit.state.totalSessions, 0);
    expect(cubit.state.bestFormScore, 0);
    expect(cubit.state.todayReps, 0);

    final reloaded = await _cubit();
    expect(reloaded.state.todayReps, 0);
  });
}
