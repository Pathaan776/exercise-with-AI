import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fitcheck/config/di/injection.dart';
import 'package:fitcheck/config/routes/app_router.dart';
import 'package:fitcheck/config/theme/app_theme.dart';
import 'package:fitcheck/config/theme/theme_cubit.dart';
import 'package:fitcheck/core/utils/constants.dart';
import 'package:fitcheck/features/profile/presentation/cubit/profile_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const FitCheckApp());
}

class FitCheckApp extends StatelessWidget {
  const FitCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<ThemeCubit>()),
        BlocProvider.value(value: getIt<ProfileCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeSettings>(
        builder: (context, settings) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(settings.accent),
            darkTheme: AppTheme.dark(settings.accent),
            themeMode: settings.mode,
            onGenerateRoute: AppRouter.onGenerateRoute,
            initialRoute: AppRouter.home,
          );
        },
      ),
    );
  }
}
