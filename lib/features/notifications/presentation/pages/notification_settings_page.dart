import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:closet_ai/features/notifications/application/notification_providers.dart';

class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencesAsync = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: preferencesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not load preferences'),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => ref.read(notificationPreferencesProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (preferences) {
          final controller = ref.read(notificationPreferencesProvider.notifier);
          return ListView(
            children: [
              const _SectionHeader('General'),
              SwitchListTile(
                title: const Text('In-app notifications'),
                value: preferences.inAppEnabled,
                onChanged: (v) => controller.update({'inAppEnabled': v}),
              ),
              SwitchListTile(
                title: const Text('Local device notifications'),
                subtitle: const Text('Reminders while the app is closed'),
                value: preferences.localEnabled,
                onChanged: (v) => controller.update({'localEnabled': v}),
              ),
              const _SectionHeader('Outfit'),
              SwitchListTile(
                title: const Text('Outfit reminders'),
                value: preferences.outfitReminders,
                onChanged: (v) => controller.update({'outfitReminders': v}),
              ),
              const _SectionHeader('Laundry'),
              SwitchListTile(
                title: const Text('Laundry reminders'),
                value: preferences.laundryReminders,
                onChanged: (v) => controller.update({'laundryReminders': v}),
              ),
              const _SectionHeader('Trip & Packing'),
              SwitchListTile(
                title: const Text('Trip reminders'),
                value: preferences.tripReminders,
                onChanged: (v) => controller.update({'tripReminders': v}),
              ),
              SwitchListTile(
                title: const Text('Packing reminders'),
                value: preferences.packingReminders,
                onChanged: (v) => controller.update({'packingReminders': v}),
              ),
              const _SectionHeader('AI'),
              SwitchListTile(
                title: const Text('AI Stylist reminders'),
                value: preferences.aiStylistReminders,
                onChanged: (v) => controller.update({'aiStylistReminders': v}),
              ),
              const _SectionHeader('Wardrobe'),
              SwitchListTile(
                title: const Text('Wardrobe reminders'),
                value: preferences.wardrobeReminders,
                onChanged: (v) => controller.update({'wardrobeReminders': v}),
              ),
              SwitchListTile(
                title: const Text('Wear history reminders'),
                value: preferences.wearHistoryReminders,
                onChanged: (v) => controller.update({'wearHistoryReminders': v}),
              ),
              const _SectionHeader('Premium'),
              SwitchListTile(
                title: const Text('Subscription reminders'),
                value: preferences.subscriptionReminders,
                onChanged: (v) => controller.update({'subscriptionReminders': v}),
              ),
              SwitchListTile(
                title: const Text('Premium expiry reminders'),
                value: preferences.premiumExpiryReminders,
                onChanged: (v) => controller.update({'premiumExpiryReminders': v}),
              ),
              const _SectionHeader('Smart Reminders'),
              SwitchListTile(
                title: const Text('Smart reminders'),
                subtitle: const Text('Data-driven reminders based on your usage'),
                value: preferences.smartReminders,
                onChanged: (v) => controller.update({'smartReminders': v}),
              ),
              SwitchListTile(
                title: const Text('Admin announcements'),
                value: preferences.adminAnnouncements,
                onChanged: (v) => controller.update({'adminAnnouncements': v}),
              ),
              const _SectionHeader('Quiet Hours'),
              SwitchListTile(
                title: const Text('Enable quiet hours'),
                subtitle: const Text('Suppress non-urgent reminders during this window'),
                value: preferences.quietHoursEnabled,
                onChanged: (v) => controller.update({'quietHoursEnabled': v}),
              ),
              ListTile(
                enabled: preferences.quietHoursEnabled,
                title: const Text('Start'),
                trailing: Text(preferences.quietHoursStart),
                onTap: () async {
                  final time = await _pickTime(context, preferences.quietHoursStart);
                  if (time != null) controller.update({'quietHoursStart': time});
                },
              ),
              ListTile(
                enabled: preferences.quietHoursEnabled,
                title: const Text('End'),
                trailing: Text(preferences.quietHoursEnd),
                onTap: () async {
                  final time = await _pickTime(context, preferences.quietHoursEnd);
                  if (time != null) controller.update({'quietHoursEnd': time});
                },
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Future<String?> _pickTime(BuildContext context, String current) async {
    final parts = current.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.isNotEmpty ? parts[0] : '0') ?? 0,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return null;
    return '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
