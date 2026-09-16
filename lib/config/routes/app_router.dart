import 'package:flutter/material.dart';

import 'package:fitcheck/features/shell/presentation/pages/app_shell.dart';
import 'package:fitcheck/features/workout/domain/entities/exercise_type.dart';
import 'package:fitcheck/features/workout/presentation/pages/exercise_detail_page.dart';
import 'package:fitcheck/features/workout/presentation/pages/live_session_page.dart';

abstract final class AppRouter {
  static const home = '/';
  static const exerciseDetail = '/exercise';
  static const liveSession = '/exercise/live';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case exerciseDetail:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) =>
              ExerciseDetailPage(exercise: _exerciseFrom(settings.arguments)),
        );

      case liveSession:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) =>
              LiveSessionPage(exercise: _exerciseFrom(settings.arguments)),
        );

      case home:
      default:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const AppShell(),
        );
    }
  }

  /// Exercise routes are always pushed with an [ExerciseType] argument;
  /// squats are the fallback if a caller forgets.
  static ExerciseType _exerciseFrom(Object? arguments) {
    if (arguments is ExerciseType) return arguments;
    if (arguments is String) return ExerciseType.fromId(arguments);
    return ExerciseType.squat;
  }
}
