import 'package:flutter/material.dart';
import 'package:fitcheck/features/pose_detection/presentation/pages/pose_page.dart';
import 'package:fitcheck/features/squats_detection/presentation/pages/squats/squats.dart';
import 'package:fitcheck/features/squats_detection/presentation/pages/squats/squats_live.dart';

class AppRouter {
  static const pose = '/';
  static const squats = '/squats';
  static const squatsLive = '/squats/live';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case pose:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const PosePage(),
        );
      case squats:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const SquatsPage(),
        );
      case squatsLive:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const SquatsLivePage(),
        );
      default:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const SquatsPage(),
        );
    }
  }
}
