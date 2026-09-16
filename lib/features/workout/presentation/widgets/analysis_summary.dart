import 'package:flutter/material.dart';

import 'package:fitcheck/config/theme/app_colors.dart';
import 'package:fitcheck/core/widgets/score_ring.dart';
import 'package:fitcheck/features/workout/domain/entities/exercise_analysis.dart';

/// Form score dial plus the joint angles behind it.
class AnalysisSummary extends StatelessWidget {
  const AnalysisSummary({super.key, required this.analysis, this.caption});

  final ExerciseAnalysis analysis;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scoreColor = AppColors.forScore(analysis.formScore);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ScoreRing(
                  progress: analysis.formScore,
                  color: scoreColor,
                  size: 84,
                  child: Text(
                    '${(analysis.formScore * 100).round()}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: scoreColor,
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        analysis.isCorrectForm ? 'Good form' : 'Needs work',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: scoreColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        caption ?? analysis.message,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (analysis.angles.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final angle in analysis.angles)
                    Expanded(child: _AngleReadout(angle: angle)),
                ],
              ),
            ],
            if (analysis.coachingTip != null) ...[
              const SizedBox(height: 14),
              _CoachingTip(text: analysis.coachingTip!),
            ],
          ],
        ),
      ),
    );
  }
}

class _AngleReadout extends StatelessWidget {
  const _AngleReadout({required this.angle});

  final JointAngle angle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = angle.isInRange
        ? theme.colorScheme.onSurface
        : AppColors.warning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(angle.label.toUpperCase(), style: theme.textTheme.labelSmall),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${angle.degrees.toStringAsFixed(0)}°',
              style: theme.textTheme.titleMedium?.copyWith(color: color),
            ),
            if (!angle.isInRange) ...[
              const SizedBox(width: 5),
              const Icon(
                Icons.error_outline_rounded,
                size: 14,
                color: AppColors.warning,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _CoachingTip extends StatelessWidget {
  const _CoachingTip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.tips_and_updates_outlined,
            size: 18,
            color: AppColors.warning,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
