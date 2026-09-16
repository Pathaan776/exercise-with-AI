import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fitcheck/config/routes/app_router.dart';
import 'package:fitcheck/config/theme/app_colors.dart';
import 'package:fitcheck/core/widgets/score_ring.dart';
import 'package:fitcheck/core/widgets/section_header.dart';
import 'package:fitcheck/core/widgets/stat_tile.dart';
import 'package:fitcheck/features/profile/domain/entities/user_profile.dart';
import 'package:fitcheck/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:fitcheck/features/workout/domain/entities/exercise_type.dart';
import 'package:fitcheck/features/workout/presentation/widgets/exercise_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onBrowseExercises});

  final VoidCallback onBrowseExercises;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileCubit>().state;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _Greeting(profile: profile),
            const SizedBox(height: 20),
            _GoalCard(profile: profile, onStart: onBrowseExercises),
            const SizedBox(height: 16),
            _StatsRow(profile: profile),
            const SizedBox(height: 28),
            SectionHeader(
              title: 'Exercises',
              subtitle: 'Real-time form coaching',
              action: TextButton(
                onPressed: onBrowseExercises,
                child: const Text('See all'),
              ),
            ),
            for (final exercise in ExerciseType.values) ...[
              ExerciseCard(
                exercise: exercise,
                onTap: () => Navigator.of(
                  context,
                ).pushNamed(AppRouter.exerciseDetail, arguments: exercise),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 16),
            const _FormTipCard(),
          ],
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hour = DateTime.now().hour;
    final part = hour < 12
        ? 'Good morning'
        : (hour < 18 ? 'Good afternoon' : 'Good evening');

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(part, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 2),
              Text(profile.shortName, style: theme.textTheme.headlineMedium),
            ],
          ),
        ),
        CircleAvatar(
          radius: 22,
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.14),
          child: Text(
            profile.initials,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.profile, required this.onStart});

  final UserProfile profile;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            ScoreRing(
              progress: profile.goalProgress,
              color: theme.colorScheme.primary,
              size: 92,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(profile.goalProgress * 100).round()}%',
                    style: theme.textTheme.titleLarge,
                  ),
                  Text('of goal', style: theme.textTheme.labelSmall),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Today', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    '${profile.todayReps} of ${profile.dailyGoal} good reps',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 40,
                    child: FilledButton(
                      onPressed: onStart,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      child: const Text('Start training'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final best = (profile.bestFormScore * 100).round();

    return Row(
      spacing: 12,
      children: [
        Expanded(
          child: StatTile(
            value: '${profile.totalSessions}',
            label: 'Sessions',
            icon: Icons.calendar_today_rounded,
          ),
        ),
        Expanded(
          child: StatTile(
            value: '${profile.totalReps}',
            label: 'Total reps',
            icon: Icons.repeat_rounded,
          ),
        ),
        Expanded(
          child: StatTile(
            value: profile.bestFormScore == 0 ? '—' : '$best%',
            label: 'Best form',
            icon: Icons.workspace_premium_rounded,
            valueColor: profile.bestFormScore == 0
                ? null
                : AppColors.forScore(profile.bestFormScore),
          ),
        ),
      ],
    );
  }
}

class _FormTipCard extends StatelessWidget {
  const _FormTipCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.lightbulb_outline_rounded,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Get the best reading',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Prop the phone about 2 m away at hip height and stand '
                    'side-on, so your shoulder, hip, knee and ankle are all in '
                    'frame. Everything runs on-device — nothing is uploaded.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
