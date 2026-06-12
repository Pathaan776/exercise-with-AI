import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fitcheck/config/di/injection.dart';
import 'package:fitcheck/config/routes/app_router.dart';
import 'package:fitcheck/features/squats_detection/presentation/bloc/squats_bloc.dart';
import 'package:fitcheck/features/squats_detection/presentation/bloc/squats_event.dart';
import 'package:fitcheck/features/squats_detection/presentation/bloc/squats_state.dart';
import 'package:fitcheck/features/squats_detection/presentation/widgets/squats_pose_overlay.dart';
import 'package:image_picker/image_picker.dart';

class SquatsPage extends StatelessWidget {
  const SquatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SquatsBloc>(),
      child: const _SquatsView(),
    );
  }
}

class _SquatsView extends StatefulWidget {
  const _SquatsView();

  @override
  State<_SquatsView> createState() => _SquatsViewState();
}

class _SquatsViewState extends State<_SquatsView> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SquatsBloc, SquatsState>(
      builder: (context, state) {
        final bloc = context.read<SquatsBloc>();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Squats Detection'),
            actions: [
              IconButton(
                onPressed: () => bloc.add(const SquatsReset()),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                FilledButton.icon(
                  onPressed: state.isLoading
                      ? null
                      : () => _pickAndAnalyzeImage(context),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Pick Image (Gallery)'),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRouter.squatsLive),
                  icon: const Icon(Icons.videocam),
                  label: const Text('Live Camera (Realtime)'),
                ),
                const SizedBox(height: 16),
                if (state.isLoading) const LinearProgressIndicator(),
                const SizedBox(height: 16),
                _ResultCard(state: state),
                const SizedBox(height: 16),
                if (state.imageBytes != null)
                  _ImagePreview(
                    bytes: state.imageBytes!,
                    overlay: state.overlay,
                    isCorrect: state.analysis.isCorrectForm,
                  ),
                const SizedBox(height: 16),
                if (state.landmarkLines.isNotEmpty)
                  _LandmarksList(lines: state.landmarkLines),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndAnalyzeImage(BuildContext context) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final Uint8List bytes = await file.readAsBytes();
    if (!context.mounted) return;
    context.read<SquatsBloc>().add(
      SquatsImageSelected(imagePath: file.path, imageBytes: bytes),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.state});

  final SquatsState state;

  @override
  Widget build(BuildContext context) {
    final analysis = state.analysis;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Result', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(analysis.message),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _Chip(
                  label: 'Person',
                  value: analysis.hasPerson ? 'Yes' : 'No',
                ),
                _Chip(
                  label: 'Squat',
                  value: analysis.isSquatPose ? 'Yes' : 'No',
                ),
                _Chip(
                  label: 'Form',
                  value: analysis.isCorrectForm ? 'Correct' : 'Wrong',
                ),
                _Chip(
                  label: 'Score',
                  value: '${(analysis.formScore * 100).round()}%',
                ),
                _Chip(
                  label: 'Knee',
                  value: analysis.kneeAngleDegrees == null
                      ? '-'
                      : '${analysis.kneeAngleDegrees!.toStringAsFixed(0)}°',
                ),
                _Chip(
                  label: 'Hip',
                  value: analysis.hipAngleDegrees == null
                      ? '-'
                      : '${analysis.hipAngleDegrees!.toStringAsFixed(0)}°',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label: $value'));
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({
    required this.bytes,
    required this.overlay,
    required this.isCorrect,
  });

  final Uint8List bytes;
  final SquatsOverlayData? overlay;
  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: overlay == null
                ? 1
                : (overlay!.imageSize.width / overlay!.imageSize.height),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(bytes, fit: BoxFit.contain),
                if (overlay != null)
                  SquatsPoseOverlay(overlay: overlay!, isCorrect: isCorrect),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LandmarksList extends StatelessWidget {
  const _LandmarksList({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Landmarks', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...lines.take(33).map((e) => Text(e)),
          ],
        ),
      ),
    );
  }
}
