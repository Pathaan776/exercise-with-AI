import 'package:shared_preferences/shared_preferences.dart';

/// Thin typed wrapper over [SharedPreferences] so features never touch raw
/// string keys. Created once at startup via [AppPreferences.create].
class AppPreferences {
  const AppPreferences(this._prefs);

  final SharedPreferences _prefs;

  static Future<AppPreferences> create() async {
    return AppPreferences(await SharedPreferences.getInstance());
  }

  static const _themeMode = 'theme_mode';
  static const _accent = 'theme_accent';
  static const _name = 'profile_name';
  static const _goal = 'profile_daily_goal';
  static const _units = 'profile_units_metric';
  static const _height = 'profile_height_cm';
  static const _weight = 'profile_weight_kg';
  static const _totalReps = 'stats_total_reps';
  static const _totalSessions = 'stats_total_sessions';
  static const _bestFormScore = 'stats_best_form_score';
  static const _todayReps = 'stats_today_reps';
  static const _todayDate = 'stats_today_date';

  String? get themeMode => _prefs.getString(_themeMode);
  Future<void> setThemeMode(String value) =>
      _prefs.setString(_themeMode, value);

  String? get accent => _prefs.getString(_accent);
  Future<void> setAccent(String value) => _prefs.setString(_accent, value);

  String? get name => _prefs.getString(_name);
  Future<void> setName(String value) => _prefs.setString(_name, value);

  int? get dailyGoal => _prefs.getInt(_goal);
  Future<void> setDailyGoal(int value) => _prefs.setInt(_goal, value);

  bool? get useMetric => _prefs.getBool(_units);
  Future<void> setUseMetric(bool value) => _prefs.setBool(_units, value);

  double? get heightCm => _prefs.getDouble(_height);
  Future<void> setHeightCm(double value) => _prefs.setDouble(_height, value);

  double? get weightKg => _prefs.getDouble(_weight);
  Future<void> setWeightKg(double value) => _prefs.setDouble(_weight, value);

  int get totalReps => _prefs.getInt(_totalReps) ?? 0;
  Future<void> setTotalReps(int value) => _prefs.setInt(_totalReps, value);

  int get totalSessions => _prefs.getInt(_totalSessions) ?? 0;
  Future<void> setTotalSessions(int value) =>
      _prefs.setInt(_totalSessions, value);

  double get bestFormScore => _prefs.getDouble(_bestFormScore) ?? 0;
  Future<void> setBestFormScore(double value) =>
      _prefs.setDouble(_bestFormScore, value);

  int get todayReps => _prefs.getInt(_todayReps) ?? 0;

  /// The day [todayReps] belongs to, as `yyyy-mm-dd`. Null before the first
  /// session ever recorded.
  String? get todayDate => _prefs.getString(_todayDate);

  Future<void> setToday(String date, int reps) async {
    await _prefs.setString(_todayDate, date);
    await _prefs.setInt(_todayReps, reps);
  }
}
