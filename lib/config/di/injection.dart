import 'package:fitcheck/core/utils/angle_calculator.dart';
import 'package:fitcheck/features/pose_detection/data/datasource/pose_datasource.dart';
import 'package:fitcheck/features/pose_detection/data/repository_impl/pose_repository_impl.dart';
import 'package:fitcheck/features/pose_detection/domain/exercise/exercise_detector.dart';
import 'package:fitcheck/features/pose_detection/domain/exercise/plank_detector.dart';
import 'package:fitcheck/features/pose_detection/domain/exercise/pushup_detector.dart';
import 'package:fitcheck/features/pose_detection/domain/exercise/squat_detector.dart';
import 'package:fitcheck/features/pose_detection/domain/repository/pose_repository.dart';
import 'package:fitcheck/features/pose_detection/domain/usecases/detect_pose_usecase.dart';
import 'package:fitcheck/features/pose_detection/presentation/bloc/pose_bloc.dart';
import 'package:fitcheck/features/squats_detection/data/datasource/pose_detection_client.dart';
import 'package:fitcheck/features/squats_detection/domain/usecases/squat_analyzer.dart';
import 'package:fitcheck/features/squats_detection/presentation/bloc/squats_bloc.dart';
import 'package:fitcheck/features/squats_detection/presentation/bloc/squats_live_bloc.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  getIt.registerLazySingleton<AngleCalculator>(() => const AngleCalculator());

  getIt.registerLazySingleton<PoseDatasource>(() => MockPoseDatasource());
  getIt.registerLazySingleton<PoseRepository>(
    () => PoseRepositoryImpl(getIt()),
  );
  getIt.registerLazySingleton<DetectPoseUsecase>(
    () => DetectPoseUsecase(getIt()),
  );

  getIt.registerLazySingleton<List<ExerciseDetector>>(
    () => [
      SquatDetector(angleCalculator: getIt()),
      PushupDetector(angleCalculator: getIt()),
      PlankDetector(angleCalculator: getIt()),
    ],
  );

  getIt.registerFactory<PoseBloc>(
    () => PoseBloc(
      detectPoseUsecase: getIt(),
      poseRepository: getIt(),
      exerciseDetectors: getIt(),
    ),
  );

  getIt.registerLazySingleton<PoseDetectionClient>(() => PoseDetectionClient());
  getIt.registerLazySingleton<SquatAnalyzer>(() => SquatAnalyzer());

  getIt.registerFactory<SquatsBloc>(
    () => SquatsBloc(
      poseDetectionClient: getIt(),
      squatAnalyzer: getIt(),
    ),
  );

  getIt.registerFactory<SquatsLiveBloc>(
    () => SquatsLiveBloc(getIt(), getIt()),
  );
}
