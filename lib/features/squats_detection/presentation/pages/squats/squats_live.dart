import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fitcheck/config/di/injection.dart';
import 'package:fitcheck/features/squats_detection/presentation/bloc/squats_live_bloc.dart';
import 'package:fitcheck/features/squats_detection/presentation/bloc/squats_live_event.dart';
import 'package:fitcheck/features/squats_detection/presentation/bloc/squats_live_state.dart';

class SquatsLivePage extends StatelessWidget {
  const SquatsLivePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SquatsLiveBloc>(),
      child: const _SquatsLiveView(),
    );
  }
}

class _SquatsLiveView extends StatefulWidget {
  const _SquatsLiveView();

  @override
  State<_SquatsLiveView> createState() => _SquatsLiveViewState();
}

class _SquatsLiveViewState extends State<_SquatsLiveView> {
  CameraController? _controller;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.first;

    final controller = CameraController(
      camera,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    await controller.initialize();
    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() => _controller = controller);

    final bloc = context.read<SquatsLiveBloc>();
    await controller.startImageStream((image) {
      if (!bloc.state.isRunning) return;
      bloc.add(SquatsLiveFrameCaptured(image, controller.description));
    });
  }

  @override
  void dispose() {
    final controller = _controller;
    if (controller != null) {
      controller.stopImageStream().catchError((_) {});
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SquatsLiveBloc, SquatsLiveState>(
      builder: (context, state) {
        final bloc = context.read<SquatsLiveBloc>();
        final controller = _controller;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Live Squats'),
            actions: [
              TextButton(
                onPressed: controller == null
                    ? null
                    : () => bloc.add(
                          state.isRunning
                              ? SquatsLiveStopped()
                              : SquatsLiveStarted(),
                        ),
                child: Text(state.isRunning ? 'Stop' : 'Start'),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: controller == null
                    ? const Center(child: Text('Loading'))
                    : CameraPreview(controller),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(state.analysis.message),
              ),
            ],
          ),
        );
      },
    );
  }
}
