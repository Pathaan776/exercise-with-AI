import 'package:get_it/get_it.dart';

import 'package:fitcheck/config/theme/theme_cubit.dart';
import 'package:fitcheck/core/storage/app_preferences.dart';
import 'package:fitcheck/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:fitcheck/features/workout/data/datasource/pose_detection_client.dart';
import 'package:fitcheck/features/workout/domain/analyzers/analyzer_factory.dart';
import 'package:fitcheck/features/workout/domain/entities/exercise_type.dart';
import 'package:fitcheck/features/workout/presentation/bloc/image_analysis_bloc.dart';
import 'package:fitcheck/features/workout/presentation/bloc/live_session_bloc.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  getIt.registerSingleton<AppPreferences>(await AppPreferences.create());

  // App-wide state. Both are singletons because the shell and every screen
  // must observe the same instance.
  getIt.registerLazySingleton<ThemeCubit>(() => ThemeCubit(getIt()));
  getIt.registerLazySingleton<ProfileCubit>(() => ProfileCubit(getIt()));

  // ML Kit detectors are expensive to build, so one client is shared and
  // closed in [disposeDependencies].
  getIt.registerLazySingleton<PoseDetectionClient>(() => PoseDetectionClient());
  getIt.registerLazySingleton<ExerciseAnalyzerFactory>(
    () => const ExerciseAnalyzerFactory(),
  );

  // Analyzers carry per-session rep state, so these blocs are factories keyed
  // on the exercise being trained.
  getIt.registerFactoryParam<LiveSessionBloc, ExerciseType, void>(
    (exercise, _) => LiveSessionBloc(
      poseDetectionClient: getIt(),
      analyzerFactory: getIt(),
      exercise: exercise,
    ),
  );

  getIt.registerFactoryParam<ImageAnalysisBloc, ExerciseType, void>(
    (exercise, _) => ImageAnalysisBloc(
      poseDetectionClient: getIt(),
      analyzerFactory: getIt(),
      exercise: exercise,
    ),
  );
}

/// Releases the native ML Kit detectors. Call before tearing the app down or
/// between tests so the platform side does not leak.
Future<void> disposeDependencies() async {
  if (getIt.isRegistered<PoseDetectionClient>()) {
    await getIt<PoseDetectionClient>().dispose();
  }
  await getIt.reset();
}
