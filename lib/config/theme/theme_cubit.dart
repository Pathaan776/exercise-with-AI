import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fitcheck/config/theme/app_colors.dart';
import 'package:fitcheck/core/storage/app_preferences.dart';

final class ThemeSettings extends Equatable {
  const ThemeSettings({required this.mode, required this.accent});

  final ThemeMode mode;
  final AppAccent accent;

  ThemeSettings copyWith({ThemeMode? mode, AppAccent? accent}) =>
      ThemeSettings(mode: mode ?? this.mode, accent: accent ?? this.accent);

  @override
  List<Object?> get props => [mode, accent];
}

/// Owns the app-wide appearance choice and mirrors every change to disk so it
/// survives a cold start.
class ThemeCubit extends Cubit<ThemeSettings> {
  ThemeCubit(this._prefs)
    : super(
        ThemeSettings(
          mode: _decodeMode(_prefs.themeMode),
          accent: AppAccent.fromName(_prefs.accent),
        ),
      );

  final AppPreferences _prefs;

  Future<void> setMode(ThemeMode mode) async {
    if (mode == state.mode) return;
    emit(state.copyWith(mode: mode));
    await _prefs.setThemeMode(mode.name);
  }

  Future<void> setAccent(AppAccent accent) async {
    if (accent == state.accent) return;
    emit(state.copyWith(accent: accent));
    await _prefs.setAccent(accent.name);
  }

  /// Flips between light and dark. If the app is following the system, this
  /// moves to the opposite of whatever is currently on screen.
  Future<void> toggleDark(BuildContext context) async {
    final isDark = switch (state.mode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system =>
        MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    };
    await setMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }

  static ThemeMode _decodeMode(String? value) {
    return ThemeMode.values.firstWhere(
      (m) => m.name == value,
      orElse: () => ThemeMode.system,
    );
  }
}
