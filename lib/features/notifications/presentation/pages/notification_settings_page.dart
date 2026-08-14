import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:closet_ai/core/theme/app_gradients.dart';
import 'package:closet_ai/core/layout/app_layout.dart';
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
            padding: EdgeInsets.only(
              bottom: AppLayout.scrollBottomPadding(context),
            ),
            children: [
              _SettingsGroup(
                title: 'General',
                children: [
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
                ],
              ),
              _SettingsGroup(
                title: 'Outfit',
                children: [
                  SwitchListTile(
                    title: const Text('Outfit reminders'),
                    value: preferences.outfitReminders,
                    onChanged: (v) => controller.update({'outfitReminders': v}),
                  ),
                ],
              ),
              _SettingsGroup(
                title: 'Laundry',
                children: [
                  SwitchListTile(
                    title: const Text('Laundry reminders'),
                    value: preferences.laundryReminders,
                    onChanged: (v) => controller.update({'laundryReminders': v}),
                  ),
                ],
              ),
              _SettingsGroup(
                title: 'Trip & Packing',
                children: [
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
                ],
              ),
              // Flagship AI feature — subtle gradient accent on the section
              // header to highlight it per the brand's cyan/blue/purple identity.
              _SettingsGroup(
                title: 'AI',
                accent: true,
                children: [
                  SwitchListTile(
                    title: const Text('AI Stylist reminders'),
                    value: preferences.aiStylistReminders,
                    onChanged: (v) => controller.update({'aiStylistReminders': v}),
                  ),
                ],
              ),
              _SettingsGroup(
                title: 'Wardrobe',
                children: [
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
                ],
              ),
              _SettingsGroup(
                title: 'Premium',
                children: [
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
                ],
              ),
              // Data-driven "smart" reminders are also an AI-powered feature —
              // give this group the same gradient accent treatment.
              _SettingsGroup(
                title: 'Smart Reminders',
                accent: true,
                children: [
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
                ],
              ),
              _SettingsGroup(
                title: 'Quiet Hours',
                children: [
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
                ],
              ),
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

/// A titled group of settings rows rendered as a single modern card.
/// When [accent] is true (used for AI-powered sections), the header gets a
/// small gradient dot to tie it to the brand's AI identity.
class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children, this.accent = false});

  final String title;
  final List<Widget> children;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title, accent: accent),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, {this.accent = false});
  final String title;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Row(
        children: [
          if (accent) ...[
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                gradient: AppGradients.blueViolet,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
