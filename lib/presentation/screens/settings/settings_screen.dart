import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/settings_providers.dart';
import '../../providers/theme_provider.dart';
import 'pin_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsStreamProvider);
    final settings = settingsAsync.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settings == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                _SectionHeader('Appearance'),
                _ThemeTile(),
                _SectionCard(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.currency_rupee_rounded),
                      title: const Text('Currency'),
                      subtitle: Text('${settings.currencySymbol} (${settings.currencyCode})'),
                      onTap: () => _showComingSoonNote(context, 'Multi-currency support is a planned future feature.'),
                    ),
                  ],
                ),

                _SectionHeader('Security'),
                _SectionCard(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.lock_outline_rounded),
                      title: const Text('PIN Lock'),
                      subtitle: const Text('Require a PIN to open the app'),
                      value: settings.pinEnabled,
                      onChanged: (enabled) => _togglePin(context, ref, enabled),
                    ),
                    if (settings.pinEnabled)
                      ListTile(
                        leading: const Icon(Icons.password_rounded),
                        title: const Text('Change PIN'),
                        onTap: () => _changePin(context),
                      ),
                    SwitchListTile(
                      secondary: const Icon(Icons.fingerprint_rounded),
                      title: const Text('Fingerprint / Face Unlock'),
                      subtitle: const Text('Use biometrics instead of typing your PIN'),
                      value: settings.biometricEnabled,
                      onChanged: settings.pinEnabled
                          ? (enabled) => _toggleBiometric(context, ref, enabled)
                          : null,
                    ),
                  ],
                ),

                _SectionHeader('Reminders'),
                _SectionCard(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.notifications_active_outlined),
                      title: const Text('Daily Reminder'),
                      subtitle: Text(
                        settings.reminderEnabled
                            ? "Don't forget to record today's expenses"
                            : 'Reminders are off',
                      ),
                      value: settings.reminderEnabled,
                      onChanged: (enabled) => _toggleReminder(context, ref, enabled, settings.reminderMinutesOfDay),
                    ),
                    if (settings.reminderEnabled)
                      ListTile(
                        leading: const Icon(Icons.access_time_rounded),
                        title: const Text('Reminder Time'),
                        subtitle: Text(_formatMinutes(settings.reminderMinutesOfDay)),
                        onTap: () => _pickReminderTime(context, ref, settings.reminderMinutesOfDay),
                      ),
                  ],
                ),

                _SectionHeader('Data'),
                _SectionCard(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.backup_outlined),
                      title: const Text('Backup Data'),
                      subtitle: const Text('Save a local .json backup and share it'),
                      onTap: () => _createBackup(context, ref),
                    ),
                    ListTile(
                      leading: const Icon(Icons.restore_outlined),
                      title: const Text('Restore Data'),
                      subtitle: const Text('Restore from a previously saved backup file'),
                      onTap: () => _restoreBackup(context, ref),
                    ),
                  ],
                ),

                _SectionHeader('About'),
                _SectionCard(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info_outline_rounded),
                      title: const Text(AppConstants.appName),
                      subtitle: const Text('${AppConstants.appTagline}\nVersion 0.1.0 · Offline, no account needed'),
                      isThreeLine: true,
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Future<void> _changePin(BuildContext context) async {
    // Require the current PIN before letting the user set a new one --
    // PinScreenMode.change on its own would otherwise behave identically
    // to `create`, letting anyone with the phone unlocked silently swap
    // the PIN without proving they know the old one.
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PinScreen(
          mode: PinScreenMode.unlock,
          onSuccess: () {
            Navigator.of(context).pop(); // dismiss the "verify old PIN" step
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PinScreen(
                  mode: PinScreenMode.create,
                  // NOTE: PinScreen's own confirm step already pops both
                  // the create and confirm routes internally (via
                  // popUntil) once the new PIN is saved, landing back on
                  // this Settings screen -- so onSuccess here must NOT
                  // call Navigator.pop() again, or it pops one route too
                  // many. It only needs to report success to the user.
                  onSuccess: () => _showSnackbar(context, 'PIN updated.'),
                  onCancel: () => Navigator.of(context).pop(),
                ),
              ),
            );
          },
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _showSnackbar(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatMinutes(int minutesOfDay) {
    final hour = minutesOfDay ~/ 60;
    final minute = minutesOfDay % 60;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _togglePin(BuildContext context, WidgetRef ref, bool enable) async {
    if (enable) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PinScreen(
            mode: PinScreenMode.create,
            // See the note in _changePin: PinScreen already pops itself
            // (and its internal confirm step) once the PIN is saved, so
            // onSuccess here reports success rather than popping again.
            onSuccess: () => _showSnackbar(context, 'PIN Lock enabled.'),
            onCancel: () => Navigator.of(context).pop(),
          ),
        ),
      );
    } else {
      await ref.read(pinServiceProvider).clearPin();
      await ref.read(settingsControllerProvider).update((s) => s
        ..pinEnabled = false
        ..biometricEnabled = false);
    }
  }

  Future<void> _toggleBiometric(BuildContext context, WidgetRef ref, bool enable) async {
    if (enable) {
      final available = await ref.read(biometricServiceProvider).isAvailable();
      if (!available) {
        if (context.mounted) {
          _showComingSoonNote(context, 'No biometric hardware/enrollment found on this device.');
        }
        return;
      }
      final ok = await ref.read(biometricServiceProvider).authenticate(
            reason: 'Confirm to enable biometric unlock',
          );
      if (!ok) return;
    }
    await ref.read(settingsControllerProvider).update((s) => s..biometricEnabled = enable);
  }

  Future<void> _toggleReminder(BuildContext context, WidgetRef ref, bool enable, int minutes) async {
    await ref.read(settingsControllerProvider).update((s) => s..reminderEnabled = enable);
    final notifications = ref.read(notificationServiceProvider);
    if (enable) {
      final granted = await notifications.requestPermissions();
      if (granted) {
        await notifications.scheduleDailyReminder(minutes, body: "Don't forget to record today's expenses.");
      }
    } else {
      await notifications.cancelDailyReminder();
    }
  }

  Future<void> _pickReminderTime(BuildContext context, WidgetRef ref, int currentMinutes) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentMinutes ~/ 60, minute: currentMinutes % 60),
    );
    if (picked == null) return;
    final minutes = picked.hour * 60 + picked.minute;
    await ref.read(settingsControllerProvider).update((s) => s..reminderMinutesOfDay = minutes);
    await ref
        .read(notificationServiceProvider)
        .scheduleDailyReminder(minutes, body: "Don't forget to record today's expenses.");
  }

  Future<void> _createBackup(BuildContext context, WidgetRef ref) async {
    final backup = ref.read(backupServiceProvider);
    try {
      final file = await backup.createBackup();
      await backup.shareBackup(file);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
      }
    }
  }

  Future<void> _restoreBackup(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restore Data'),
        content: const Text(
          'This will replace your current expenses and income with the contents of the backup file. Continue?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Restore')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref.read(backupServiceProvider).pickAndRestore(merge: false);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
    }
  }

  void _showComingSoonNote(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondaryLight,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(children: children),
    );
  }
}

class _ThemeTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return _SectionCard(
      children: [
        ListTile(
          leading: const Icon(Icons.brightness_6_outlined),
          title: const Text('Theme'),
          trailing: SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('Auto'), icon: Icon(Icons.brightness_auto, size: 16)),
              ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode, size: 16)),
              ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode, size: 16)),
            ],
            selected: {mode},
            showSelectedIcon: false,
            onSelectionChanged: (s) {
              final mode = s.first;
              ref.read(themeModeProvider.notifier).setThemeMode(mode);
              final label = switch (mode) {
                ThemeMode.light => 'light',
                ThemeMode.dark => 'dark',
                ThemeMode.system => 'system',
              };
              ref.read(settingsControllerProvider).update((sett) => sett..themeMode = label);
            },
          ),
        ),
      ],
    );
  }
}
