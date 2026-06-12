import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fitcheck/config/di/injection.dart';
import 'package:fitcheck/core/utils/constants.dart';
import 'package:fitcheck/features/pose_detection/presentation/bloc/pose_bloc.dart';
import 'package:fitcheck/features/pose_detection/presentation/bloc/pose_event.dart';
import 'package:fitcheck/features/pose_detection/presentation/bloc/pose_state.dart';
import 'package:fitcheck/features/pose_detection/presentation/widgets/camera_view.dart';
import 'package:fitcheck/features/pose_detection/presentation/widgets/pose_overlay.dart';

class PosePage extends StatelessWidget {
  const PosePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PoseBloc>(),
      child: const _PoseView(),
    );
  }
}

class _PoseView extends StatelessWidget {
  const _PoseView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PoseBloc, PoseState>(
      listenWhen: (prev, next) =>
          prev.errorMessage != next.errorMessage && next.errorMessage != null,
      listener: (context, state) {
        final msg = state.errorMessage;
        if (msg == null) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      },
      builder: (context, state) {
        final bloc = context.read<PoseBloc>();

        return Scaffold(
          appBar: AppBar(
            title: const Text(AppConstants.appName),
            actions: [
              TextButton(
                onPressed: state.isRunning
                    ? () => bloc.add(const PoseStopped())
                    : () => bloc.add(const PoseStarted()),
                child: Text(state.isRunning ? 'Stop' : 'Start'),
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: CameraView(overlay: PoseOverlay(pose: state.pose)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(flex: 2, child: _ResultsList(state: state)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ResultsList extends StatelessWidget {
  const _ResultsList({required this.state});
  final PoseState state;

  @override
  Widget build(BuildContext context) {
    final results = state.resultsByDetectorId.values.toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));

    if (!state.isRunning && results.isEmpty) {
      return const Center(child: Text('Tap Start to begin pose detection'));
    }

    if (results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final r = results[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.displayName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(r.status),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (r.repetitions > 0)
                  Text(
                    'x${r.repetitions}',
                    style: Theme.of(context).textTheme.titleLarge,
                  )
                else
                  Text(
                    '${r.holdSeconds}s',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
