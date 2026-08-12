import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:closet_ai/core/theme/app_gradients.dart';
import 'package:closet_ai/features/notifications/application/notification_providers.dart';

class SmartRemindersPage extends ConsumerWidget {
  const SmartRemindersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(smartReminderSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Smart Reminders')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not load smart reminder settings'),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => ref.read(smartReminderSettingsProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (settings) {
          final controller = ref.read(smartReminderSettingsProvider.notifier);
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: SwitchListTile(
                  secondary: const _GradientIconChip(icon: Icons.auto_awesome),
                  title: const Text('Smart Reminders'),
                  subtitle: const Text('Master switch for all data-driven reminders'),
                  value: settings.enabled,
                  onChanged: (v) => controller.update({'enabled': v}),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Maximum daily reminders'),
                      trailing: DropdownButton<int>(
                        value: settings.maxDailyReminders,
                        items: List.generate(11, (i) => i)
                            .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) controller.update({'maxDailyReminders': v});
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Minimum interval (minutes)'),
                      trailing: DropdownButton<int>(
                        value: settings.minimumIntervalMinutes,
                        items: const [30, 60, 90, 120, 180, 240]
                            .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) controller.update({'minimumIntervalMinutes': v});
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Smart Outfit'),
                      value: settings.smartOutfit,
                      onChanged: (v) => controller.update({'smartOutfit': v}),
                    ),
                    SwitchListTile(
                      title: const Text('Smart Laundry'),
                      value: settings.smartLaundry,
                      onChanged: (v) => controller.update({'smartLaundry': v}),
                    ),
                    SwitchListTile(
                      title: const Text('Smart Packing'),
                      value: settings.smartPacking,
                      onChanged: (v) => controller.update({'smartPacking': v}),
                    ),
                    SwitchListTile(
                      title: const Text('Smart Trip'),
                      value: settings.smartTrip,
                      onChanged: (v) => controller.update({'smartTrip': v}),
                    ),
                    SwitchListTile(
                      title: const Text('Smart Wardrobe'),
                      value: settings.smartWardrobe,
                      onChanged: (v) => controller.update({'smartWardrobe': v}),
                    ),
                    SwitchListTile(
                      title: const Text('Smart Wear History'),
                      value: settings.smartWearHistory,
                      onChanged: (v) => controller.update({'smartWearHistory': v}),
                    ),
                    SwitchListTile(
                      secondary: const _GradientIconChip(icon: Icons.auto_awesome_outlined),
                      title: const Text('Smart AI Stylist'),
                      value: settings.smartAIStylist,
                      onChanged: (v) => controller.update({'smartAIStylist': v}),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Small gradient-filled icon chip used as the `secondary` slot on AI-powered
/// switch rows, so the flagship smart/AI features carry a cyan/blue/purple
/// accent instead of a plain icon.
class _GradientIconChip extends StatelessWidget {
  const _GradientIconChip({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: AppGradients.blueViolet,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}
