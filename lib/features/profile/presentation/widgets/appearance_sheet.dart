import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fitcheck/config/theme/app_colors.dart';
import 'package:fitcheck/config/theme/theme_cubit.dart';

/// Theme customiser: light/dark/system plus the accent colour. Every change
/// applies immediately and is written to disk, so there is no save button.
class AppearanceSheet extends StatelessWidget {
  const AppearanceSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AppearanceSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<ThemeCubit>();
    final settings = context.watch<ThemeCubit>().state;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Appearance', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Applies across the app and is remembered next time you open it.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 22),

            Text('THEME', style: theme.textTheme.labelSmall),
            const SizedBox(height: 10),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_outlined),
                  label: Text('Light'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_outlined),
                  label: Text('Dark'),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto_outlined),
                  label: Text('Auto'),
                ),
              ],
              selected: {settings.mode},
              showSelectedIcon: false,
              onSelectionChanged: (selection) => cubit.setMode(selection.first),
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.16,
                ),
                selectedForegroundColor: theme.colorScheme.primary,
                side: BorderSide(color: theme.colorScheme.outline),
              ),
            ),

            const SizedBox(height: 26),
            Text('ACCENT COLOUR', style: theme.textTheme.labelSmall),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final accent in AppAccent.values) ...[
                  _AccentSwatch(
                    accent: accent,
                    isSelected: accent == settings.accent,
                    onTap: () => cubit.setAccent(accent),
                  ),
                  if (accent != AppAccent.values.last)
                    const SizedBox(width: 14),
                ],
              ],
            ),

            const SizedBox(height: 26),
            const _ThemePreview(),
            const SizedBox(height: 20),

            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({
    required this.accent,
    required this.isSelected,
    required this.onTap,
  });

  final AppAccent accent;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accent.seedFor(theme.brightness);

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: accent.label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.onSurface
                        : Colors.transparent,
                    width: 2.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 20,
                      )
                    : null,
              ),
              const SizedBox(height: 6),
              Text(
                accent.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A miniature of the live-session panel, so the choice can be judged against
/// the surface it actually affects.
class _ThemePreview extends StatelessWidget {
  const _ThemePreview();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              Icons.accessibility_new_rounded,
              color: theme.colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Preview', style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  '12 good reps · 88% form',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Start',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
