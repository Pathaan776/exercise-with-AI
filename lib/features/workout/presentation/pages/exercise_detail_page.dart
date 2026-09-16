import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'package:fitcheck/config/di/injection.dart';
import 'package:fitcheck/config/routes/app_router.dart';
import 'package:fitcheck/features/workout/domain/entities/exercise_type.dart';
import 'package:fitcheck/features/workout/presentation/bloc/image_analysis_bloc.dart';
import 'package:fitcheck/features/workout/presentation/bloc/image_analysis_event.dart';
import 'package:fitcheck/features/workout/presentation/bloc/image_analysis_state.dart';
import 'package:fitcheck/features/workout/presentation/widgets/analysis_summary.dart';
import 'package:fitcheck/features/workout/presentation/widgets/pose_overlay.dart';

/// Exercise briefing, plus the two ways to get feedback: a still photo check
/// or a live coached session.
class ExerciseDetailPage extends StatelessWidget {
  const ExerciseDetailPage({super.key, required this.exercise});

  final ExerciseType exercise;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ImageAnalysisBloc>(param1: exercise),
      child: _ExerciseDetailView(exercise: exercise),
    );
  }
}

class _ExerciseDetailView extends StatelessWidget {
  const _ExerciseDetailView({required this.exercise});

  final ExerciseType exercise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<ImageAnalysisBloc, ImageAnalysisState>(
      listenWhen: (prev, next) =>
          prev.errorMessage != next.errorMessage && next.errorMessage != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(exercise.label),
            actions: [
              if (state.imageBytes != null)
                IconButton(
                  tooltip: 'Clear',
                  onPressed: () => context.read<ImageAnalysisBloc>().add(
                    const ImageAnalysisCleared(),
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              _Briefing(exercise: exercise),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => Navigator.of(
                  context,
                ).pushNamed(AppRouter.liveSession, arguments: exercise),
                icon: const Icon(Icons.videocam_rounded),
                label: const Text('Start live session'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: state.isAnalysing ? null : () => _pickImage(context),
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(
                  state.imageBytes == null
                      ? 'Check a photo'
                      : 'Check another photo',
                ),
              ),
              if (state.isAnalysing) ...[
                const SizedBox(height: 20),
                const LinearProgressIndicator(),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'Analysing pose…',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
              if (state.hasResult) ...[
                const SizedBox(height: 24),
                _ImageResult(state: state),
                const SizedBox(height: 14),
                AnalysisSummary(
                  analysis: state.analysis,
                  caption: state.analysis.hasPerson
                      ? 'Snapshot of a single moment — start a live session to '
                            'count reps.'
                      : null,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    final bloc = context.read<ImageAnalysisBloc>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
      );
      if (file == null) return;

      final Uint8List bytes = await file.readAsBytes();
      bloc.add(ImageAnalysisRequested(path: file.path, bytes: bytes));
    } catch (_) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open the gallery. Check photo permissions.',
            ),
          ),
        );
    }
  }
}

class _Briefing extends StatelessWidget {
  const _Briefing({required this.exercise});

  final ExerciseType exercise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    exercise.icon,
                    color: theme.colorScheme.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    exercise.tagline,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(exercise.description, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _ImageResult extends StatelessWidget {
  const _ImageResult({required this.state});

  final ImageAnalysisState state;

  @override
  Widget build(BuildContext context) {
    final skeleton = state.skeleton;
    final aspect = skeleton == null || skeleton.imageSize.isEmpty
        ? 3 / 4
        : skeleton.imageSize.width / skeleton.imageSize.height;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: aspect,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(state.imageBytes!, fit: BoxFit.contain),
            if (skeleton != null)
              PoseOverlay(
                frame: skeleton,
                isCorrectForm: state.analysis.isCorrectForm,
              ),
          ],
        ),
      ),
    );
  }
}
