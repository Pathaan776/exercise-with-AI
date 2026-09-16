import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fitcheck/config/theme/app_colors.dart';
import 'package:fitcheck/config/theme/theme_cubit.dart';
import 'package:fitcheck/core/utils/constants.dart';
import 'package:fitcheck/core/widgets/section_header.dart';
import 'package:fitcheck/core/widgets/stat_tile.dart';
import 'package:fitcheck/features/profile/domain/entities/user_profile.dart';
import 'package:fitcheck/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:fitcheck/features/profile/presentation/widgets/appearance_sheet.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileCubit>().state;
    final settings = context.watch<ThemeCubit>().state;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          _ProfileHeader(profile: profile),
          const SizedBox(height: 18),
          _LifetimeStats(profile: profile),
          const SizedBox(height: 28),

          const SectionHeader(
            title: 'Appearance',
            subtitle: 'Choose how FitCheck looks',
          ),
          _SettingsGroup(
            children: [
              SwitchListTile(
                value: _isDark(context, settings.mode),
                onChanged: (_) =>
                    context.read<ThemeCubit>().toggleDark(context),
                secondary: const _TileIcon(Icons.dark_mode_outlined),
                title: const Text('Dark mode'),
                subtitle: Text(_modeLabel(settings.mode)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              const Divider(indent: 16, endIndent: 16),
              ListTile(
                leading: const _TileIcon(Icons.palette_outlined),
                title: const Text('Customise theme'),
                subtitle: Text('${settings.accent.label} accent'),
                trailing: _AccentDot(
                  color: settings.accent.seedFor(Theme.of(context).brightness),
                ),
                onTap: () => AppearanceSheet.show(context),
              ),
            ],
          ),

          const SizedBox(height: 26),
          const SectionHeader(
            title: 'Training',
            subtitle: 'Targets and measurement units',
          ),
          _SettingsGroup(
            children: [
              ListTile(
                leading: const _TileIcon(Icons.flag_outlined),
                title: const Text('Daily rep goal'),
                subtitle: Text('${profile.dailyGoal} reps'),
                trailing: const _Chevron(),
                onTap: () => _editGoal(context, profile),
              ),
              const Divider(indent: 16, endIndent: 16),
              ListTile(
                leading: const _TileIcon(Icons.straighten_rounded),
                title: const Text('Units'),
                subtitle: Text(
                  profile.useMetric ? 'Metric (kg, cm)' : 'Imperial (lb, ft)',
                ),
                trailing: Switch(
                  value: profile.useMetric,
                  onChanged: (value) =>
                      context.read<ProfileCubit>().updateUseMetric(value),
                ),
              ),
              const Divider(indent: 16, endIndent: 16),
              ListTile(
                leading: const _TileIcon(Icons.height_rounded),
                title: const Text('Height'),
                subtitle: Text(profile.heightLabel ?? 'Not set'),
                trailing: const _Chevron(),
                onTap: () => _editMeasurement(context, profile, isHeight: true),
              ),
              const Divider(indent: 16, endIndent: 16),
              ListTile(
                leading: const _TileIcon(Icons.monitor_weight_outlined),
                title: const Text('Weight'),
                subtitle: Text(profile.weightLabel ?? 'Not set'),
                trailing: const _Chevron(),
                onTap: () =>
                    _editMeasurement(context, profile, isHeight: false),
              ),
            ],
          ),

          const SizedBox(height: 26),
          const SectionHeader(title: 'Data & privacy'),
          _SettingsGroup(
            children: [
              const ListTile(
                leading: _TileIcon(Icons.phonelink_lock_outlined),
                title: Text('On-device analysis'),
                subtitle: Text(
                  'Poses are detected on your phone. No photo or video ever '
                  'leaves the device.',
                ),
                isThreeLine: true,
              ),
              const Divider(indent: 16, endIndent: 16),
              ListTile(
                leading: _TileIcon(
                  Icons.delete_outline_rounded,
                  color: AppColors.danger,
                ),
                title: const Text('Reset training stats'),
                subtitle: const Text('Clears sessions, reps and best form'),
                onTap: () => _confirmReset(context),
              ),
            ],
          ),

          const SizedBox(height: 24),
          Center(
            child: Text(
              '${AppConstants.appName} ${AppConstants.version}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }

  static bool _isDark(BuildContext context, ThemeMode mode) => switch (mode) {
    ThemeMode.dark => true,
    ThemeMode.light => false,
    ThemeMode.system =>
      MediaQuery.platformBrightnessOf(context) == Brightness.dark,
  };

  static String _modeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.dark => 'Always dark',
    ThemeMode.light => 'Always light',
    ThemeMode.system => 'Following your device setting',
  };

  Future<void> _editGoal(BuildContext context, UserProfile profile) async {
    final cubit = context.read<ProfileCubit>();
    final value = await _NumberPrompt.show(
      context,
      title: 'Daily rep goal',
      helper: 'Total good reps to aim for each day (5–500).',
      suffix: 'reps',
      initial: profile.dailyGoal.toString(),
      allowDecimal: false,
    );
    if (value != null) await cubit.updateDailyGoal(value.round());
  }

  Future<void> _editMeasurement(
    BuildContext context,
    UserProfile profile, {
    required bool isHeight,
  }) async {
    final cubit = context.read<ProfileCubit>();
    final metric = profile.useMetric;

    final unit = isHeight ? (metric ? 'cm' : 'in') : (metric ? 'kg' : 'lb');
    final current = isHeight ? profile.heightCm : profile.weightKg;
    final shown = current == null
        ? ''
        : _toDisplayUnits(
            current,
            isHeight: isHeight,
            metric: metric,
          ).toStringAsFixed(isHeight ? 0 : 1);

    final value = await _NumberPrompt.show(
      context,
      title: isHeight ? 'Height' : 'Weight',
      helper: 'Used to personalise your profile. Optional.',
      suffix: unit,
      initial: shown,
      allowDecimal: !isHeight,
    );
    if (value == null) return;

    final stored = _toStorageUnits(value, isHeight: isHeight, metric: metric);
    await cubit.updateMeasurements(
      heightCm: isHeight ? stored : null,
      weightKg: isHeight ? null : stored,
    );
  }

  // Height and weight are always stored in cm/kg; only the input is converted.
  static double _toDisplayUnits(
    double value, {
    required bool isHeight,
    required bool metric,
  }) {
    if (metric) return value;
    return isHeight ? value / 2.54 : value * 2.20462;
  }

  static double _toStorageUnits(
    double value, {
    required bool isHeight,
    required bool metric,
  }) {
    if (metric) return value;
    return isHeight ? value * 2.54 : value / 2.20462;
  }

  Future<void> _confirmReset(BuildContext context) async {
    final cubit = context.read<ProfileCubit>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset training stats?'),
        content: const Text(
          'Your sessions, total reps and best form score will be set back to '
          'zero. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await cubit.resetStats();
    messenger
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('Training stats reset')));
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: theme.colorScheme.primary.withValues(
                alpha: 0.14,
              ),
              child: Text(
                profile.initials,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.name, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 2),
                  Text(
                    profile.totalSessions == 0
                        ? 'No sessions yet — start your first'
                        : '${profile.totalSessions} sessions completed',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Edit name',
              onPressed: () => _editName(context),
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editName(BuildContext context) async {
    final cubit = context.read<ProfileCubit>();
    final controller = TextEditingController(text: profile.name);

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Your name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (name != null) await cubit.updateName(name);
  }
}

class _LifetimeStats extends StatelessWidget {
  const _LifetimeStats({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
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
            value: profile.bestFormScore == 0
                ? '—'
                : '${(profile.bestFormScore * 100).round()}%',
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

/// Rounded container that groups settings rows into one visual block.
class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _TileIcon extends StatelessWidget {
  const _TileIcon(this.icon, {this.color});

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = color ?? theme.colorScheme.onSurfaceVariant;

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, size: 19, color: tint),
    );
  }
}

class _AccentDot extends StatelessWidget {
  const _AccentDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.arrow_forward_ios_rounded,
      size: 14,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
}

/// Numeric entry dialog shared by the goal and body-measurement rows.
class _NumberPrompt extends StatefulWidget {
  const _NumberPrompt({
    required this.title,
    required this.helper,
    required this.suffix,
    required this.initial,
    required this.allowDecimal,
  });

  final String title;
  final String helper;
  final String suffix;
  final String initial;
  final bool allowDecimal;

  static Future<double?> show(
    BuildContext context, {
    required String title,
    required String helper,
    required String suffix,
    required String initial,
    required bool allowDecimal,
  }) {
    return showDialog<double>(
      context: context,
      builder: (_) => _NumberPrompt(
        title: title,
        helper: helper,
        suffix: suffix,
        initial: initial,
        allowDecimal: allowDecimal,
      ),
    );
  }

  @override
  State<_NumberPrompt> createState() => _NumberPromptState();
}

class _NumberPromptState extends State<_NumberPrompt> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = double.tryParse(_controller.text.trim());
    if (value == null || value <= 0) {
      setState(() => _error = 'Enter a number greater than zero');
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.numberWithOptions(
              decimal: widget.allowDecimal,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                widget.allowDecimal ? RegExp(r'[0-9.]') : RegExp(r'[0-9]'),
              ),
            ],
            decoration: InputDecoration(
              suffixText: widget.suffix,
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 10),
          Text(widget.helper, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
