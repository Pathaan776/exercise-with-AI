import 'package:flutter/material.dart';
import 'package:fitcheck/config/di/injection.dart';
import 'package:fitcheck/config/routes/app_router.dart';
import 'package:fitcheck/config/theme/app_theme.dart';
import 'package:fitcheck/core/utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const FitCheckApp());
}

class FitCheckApp extends StatelessWidget {
  const FitCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.light(),
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRouter.squats,
    );
  }
}
