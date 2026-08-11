import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:closet_ai/features/notifications/application/notification_providers.dart';
import 'package:closet_ai/features/notifications/domain/notification_model.dart';
import 'package:closet_ai/features/notifications/domain/reminder_model.dart';

class RemindersPage extends ConsumerWidget {
  const RemindersPage({super.key});

  Future<void> _showSnoozeSheet(BuildContext context, WidgetRef ref, ReminderModel reminder) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Snooze reminder', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ListTile(
                title: const Text('15 minutes'),
                onTap: () => Navigator.pop(context, '15m'),
              ),
              ListTile(
                title: const Text('30 minutes'),
                onTap: () => Navigator.pop(context, '30m'),
              ),
              ListTile(
                title: const Text('1 hour'),
                onTap: () => Navigator.pop(context, '1h'),
              ),
              ListTile(
                title: const Text('Tomorrow'),
                onTap: () => Navigator.pop(context, 'tomorrow'),
              ),
            ],
          ),
        );
      },
    ).then((preset) async {
      if (preset == null) return;
      await ref.read(notificationRepositoryProvider).snoozeReminder(reminder.id, preset: preset as String);
      ref.invalidate(remindersProvider);
      await ref.read(localNotificationSyncServiceProvider).sync();
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(remindersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await context.push<bool>('/reminders/create');
          if (created == true) ref.invalidate(remindersProvider);
        },
        child: const Icon(Icons.add),
      ),
      body: remindersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not load reminders'),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => ref.invalidate(remindersProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (reminders) {
          if (reminders.isEmpty) {
            return const Center(child: Text('No reminders yet. Tap + to create one.'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(remindersProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: reminders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final reminder = reminders[index];
                final info = notificationInfoFor(reminder.type);
                return Card(
                  child: ListTile(
                    leading: Icon(info.icon),
                    title: Text(reminder.title),
                    subtitle: Text(
                      [
                        reminder.frequency,
                        if (reminder.nextTriggerAt != null)
                          DateFormat('MMM d, HH:mm').format(reminder.nextTriggerAt!),
                      ].join(' • '),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.snooze),
                          onPressed: () => _showSnoozeSheet(context, ref, reminder),
                        ),
                        Switch(
                          value: reminder.enabled,
                          onChanged: (_) async {
                            await ref.read(notificationRepositoryProvider).toggleReminder(reminder.id);
                            ref.invalidate(remindersProvider);
                            await ref.read(localNotificationSyncServiceProvider).sync();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await ref.read(notificationRepositoryProvider).deleteReminder(reminder.id);
                            ref.invalidate(remindersProvider);
                            await ref.read(localNotificationSyncServiceProvider).sync();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
