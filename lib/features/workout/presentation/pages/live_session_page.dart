import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fitcheck/config/di/injection.dart';
import 'package:fitcheck/config/theme/app_colors.dart';
import 'package:fitcheck/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:fitcheck/features/workout/domain/entities/exercise_analysis.dart';
import 'package:fitcheck/features/workout/domain/entities/exercise_type.dart';
import 'package:fitcheck/features/workout/presentation/bloc/live_session_bloc.dart';
import 'package:fitcheck/features/workout/presentation/bloc/live_session_event.dart';
import 'package:fitcheck/features/workout/presentation/bloc/live_session_state.dart';
import 'package:fitcheck/features/workout/presentation/widgets/pose_overlay.dart';

/// Full-screen coached session: live camera, skeleton overlay and running
/// form feedback.
class LiveSessionPage extends StatelessWidget {
  const LiveSessionPage({super.key, required this.exercise});

  final ExerciseType exercise;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LiveSessionBloc>(param1: exercise),
      child: _LiveSessionView(exercise: exercise),
    );
  }
}

class _LiveSessionView extends StatefulWidget {
  const _LiveSessionView({required this.exercise});

  final ExerciseType exercise;

  @override
  State<_LiveSessionView> createState() => _LiveSessionViewState();
}

class _LiveSessionViewState extends State<_LiveSessionView>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;
  bool _isSwitching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_setUpCamera());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    // The OS reclaims the camera when the app is backgrounded, so the
    // controller has to be torn down and rebuilt rather than merely paused.
    if (state == AppLifecycleState.inactive) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_setUpCamera());
    }
  }

  Future<void> _setUpCamera() async {
    final bloc = context.read<LiveSessionBloc>();

    try {
      if (_cameras.isEmpty) {
        _cameras = await availableCameras();
        // Default to the front camera so the athlete can see themselves and
        // check they are fully in frame while training alone.
        final front = _cameras.indexWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
        );
        _cameraIndex = front >= 0 ? front : 0;
      }

      if (_cameras.isEmpty) {
        bloc.add(
          const LiveSessionCameraFailed('No camera found on this device.'),
        );
        return;
      }

      final camera = _cameras[_cameraIndex];
      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        // NV21 feeds ML Kit directly on Android; iOS needs BGRA8888.
        imageFormatGroup: defaultTargetPlatform == TargetPlatform.android
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      await controller.startImageStream((image) {
        if (!mounted) return;
        bloc.add(
          LiveSessionFrameCaptured(
            image: image,
            camera: camera,
            deviceOrientation: controller.value.deviceOrientation,
          ),
        );
      });

      setState(() => _controller = controller);
      bloc.add(
        LiveSessionCameraReady(
          isFrontCamera: camera.lensDirection == CameraLensDirection.front,
        ),
      );
    } on CameraException catch (error) {
      if (!mounted) return;
      bloc.add(LiveSessionCameraFailed(_describe(error)));
    } catch (_) {
      if (!mounted) return;
      bloc.add(const LiveSessionCameraFailed('Could not start the camera.'));
    }
  }

  String _describe(CameraException error) {
    return switch (error.code) {
      'CameraAccessDenied' ||
      'CameraAccessDeniedWithoutPrompt' ||
      'CameraAccessRestricted' =>
        'Camera access is off. Enable it for FitCheck in Settings to use live '
            'coaching.',
      _ => error.description ?? 'Could not start the camera.',
    };
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isSwitching) return;
    setState(() => _isSwitching = true);

    await _disposeCamera();
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _setUpCamera();

    if (mounted) setState(() => _isSwitching = false);
  }

  Future<void> _disposeCamera() async {
    final controller = _controller;
    if (controller == null) return;
    if (mounted) setState(() => _controller = null);

    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } catch (_) {
      // Already stopped — nothing to unwind.
    }
    await controller.dispose();
  }

  /// Folds the session into the athlete's lifetime totals on the way out.
  void _recordSession() {
    final analysis = context.read<LiveSessionBloc>().state.analysis;
    if (analysis.totalReps == 0 && analysis.bestHoldSeconds == 0) return;

    context.read<ProfileCubit>().recordSession(
      reps: analysis.repsCorrect,
      formScore: analysis.formScore,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_disposeCamera());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LiveSessionBloc, LiveSessionState>(
      listenWhen: (prev, next) =>
          prev.errorMessage != next.errorMessage && next.errorMessage != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      },
      builder: (context, state) {
        return PopScope(
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) _recordSession();
          },
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              fit: StackFit.expand,
              children: [
                _CameraLayer(controller: _controller, state: state),
                const _ScrimGradient(),
                SafeArea(
                  child: Column(
                    children: [
                      _TopBar(
                        exercise: widget.exercise,
                        canSwitch: _cameras.length > 1 && !_isSwitching,
                        onSwitch: _switchCamera,
                      ),
                      const Spacer(),
                      _CoachPanel(state: state),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CameraLayer extends StatelessWidget {
  const _CameraLayer({required this.controller, required this.state});

  final CameraController? controller;
  final LiveSessionState state;

  @override
  Widget build(BuildContext context) {
    if (state.cameraStatus == CameraStatus.failed) {
      return _CameraMessage(
        icon: Icons.videocam_off_rounded,
        message: state.errorMessage ?? 'Camera unavailable.',
      );
    }

    final controller = this.controller;
    if (controller == null || !controller.value.isInitialized) {
      return const _CameraMessage(
        icon: Icons.photo_camera_outlined,
        message: 'Starting camera…',
        showSpinner: true,
      );
    }

    final preview = controller.value.previewSize;
    final isPortrait =
        controller.value.deviceOrientation == DeviceOrientation.portraitUp ||
        controller.value.deviceOrientation == DeviceOrientation.portraitDown;

    // previewSize is reported in the sensor's landscape frame, so portrait
    // display swaps the axes. The overlay maps onto the same box.
    final aspect = preview == null
        ? 3 / 4
        : (isPortrait
              ? preview.height / preview.width
              : preview.width / preview.height);

    return Center(
      child: AspectRatio(
        aspectRatio: aspect,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(controller),
            if (state.skeleton != null)
              PoseOverlay(
                frame: state.skeleton!,
                isCorrectForm: state.analysis.isCorrectForm,
              ),
          ],
        ),
      ),
    );
  }
}

class _CameraMessage extends StatelessWidget {
  const _CameraMessage({
    required this.icon,
    required this.message,
    this.showSpinner = false,
  });

  final IconData icon;
  final String message;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: Colors.white38),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, height: 1.45),
              ),
              if (showSpinner) ...[
                const SizedBox(height: 22),
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ScrimGradient extends StatelessWidget {
  const _ScrimGradient();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0, 0.22, 0.58, 1],
            colors: [
              Colors.black.withValues(alpha: 0.55),
              Colors.transparent,
              Colors.transparent,
              Colors.black.withValues(alpha: 0.75),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.exercise,
    required this.canSwitch,
    required this.onSwitch,
  });

  final ExerciseType exercise;
  final bool canSwitch;
  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
            color: Colors.white,
            tooltip: 'Finish',
          ),
          Expanded(
            child: Text(
              exercise.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: canSwitch ? onSwitch : null,
            icon: const Icon(Icons.cameraswitch_rounded),
            color: Colors.white,
            disabledColor: Colors.white24,
            tooltip: 'Switch camera',
          ),
        ],
      ),
    );
  }
}

/// The glass panel of live numbers and controls along the bottom.
class _CoachPanel extends StatelessWidget {
  const _CoachPanel({required this.state});

  final LiveSessionState state;

  @override
  Widget build(BuildContext context) {
    final analysis = state.analysis;
    final bloc = context.read<LiveSessionBloc>();
    final scoreColor = AppColors.forScore(analysis.formScore);

    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _PrimaryMetric(analysis: analysis)),
              _SecondaryMetric(
                label: 'Form',
                value: '${(analysis.formScore * 100).round()}%',
                color: scoreColor,
              ),
              const SizedBox(width: 20),
              _SecondaryMetric(
                label: 'Phase',
                value: analysis.phase.label,
                color: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _StatusLine(state: state),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: state.canStart
                      ? () => bloc.add(
                          state.isRunning
                              ? const LiveSessionPaused()
                              : const LiveSessionStarted(),
                        )
                      : null,
                  icon: Icon(
                    state.isRunning
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                  label: Text(state.isRunning ? 'Pause' : 'Start'),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                onPressed: () => bloc.add(const LiveSessionReset()),
                icon: const Icon(Icons.restart_alt_rounded),
                tooltip: 'Reset count',
                style: IconButton.styleFrom(
                  minimumSize: const Size(52, 52),
                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrimaryMetric extends StatelessWidget {
  const _PrimaryMetric({required this.analysis});

  final ExerciseAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final isHold = analysis.exercise.isHold;
    final value = isHold
        ? _formatDuration(analysis.holdSeconds)
        : '${analysis.repsCorrect}';
    final caption = isHold
        ? 'Hold · best ${_formatDuration(analysis.bestHoldSeconds)}'
        : 'Good reps · ${analysis.repsWrong} to fix';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 44,
            height: 1,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          caption,
          style: const TextStyle(color: Colors.white60, fontSize: 12.5),
        ),
      ],
    );
  }

  static String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _SecondaryMetric extends StatelessWidget {
  const _SecondaryMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// One line that explains what the app is currently seeing — the coaching tip
/// when form slips, otherwise the analyzer's own status message.
class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.state});

  final LiveSessionState state;

  @override
  Widget build(BuildContext context) {
    final analysis = state.analysis;

    final (icon, text, color) = switch (state) {
      _ when !state.isRunning => (
        Icons.info_outline_rounded,
        state.canStart
            ? 'Press start when you are in frame'
            : 'Waiting for the camera…',
        Colors.white70,
      ),
      _ when !analysis.hasPerson => (
        Icons.person_search_rounded,
        'Step back until your whole body is visible',
        AppColors.warning,
      ),
      _ when analysis.coachingTip != null => (
        Icons.tips_and_updates_outlined,
        analysis.coachingTip!,
        AppColors.warning,
      ),
      _ => (
        Icons.check_circle_outline_rounded,
        analysis.message,
        Colors.white70,
      ),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: color, fontSize: 13, height: 1.35),
          ),
        ),
      ],
    );
  }
}
