import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/models/admin_notification.dart';
import '../providers/admin_providers.dart';
import '../widgets/kpi_card.dart';
import '../widgets/paginated_list.dart';

const _audiences = ['all', 'free', 'premium', 'specificUsers'];
const _priorities = ['low', 'normal', 'high', 'urgent'];

class AdminNotificationsScreen extends ConsumerStatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  ConsumerState<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends ConsumerState<AdminNotificationsScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _priority = 'normal';
  String _audience = 'all';
  bool _sending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendAnnouncement() async {
    if (_titleController.text.trim().isEmpty || _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and message are required')),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      await ref.read(adminRepositoryProvider).createAnnouncement({
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'priority': _priority,
        'targetAudience': _audience,
      });
      _titleController.clear();
      _messageController.clear();
      ref.invalidate(adminAnnouncementsProvider);
      ref.invalidate(adminNotificationStatsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement scheduled')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send announcement: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(adminNotificationStatsProvider);
    final announcementsAsync = ref.watch(adminAnnouncementsProvider);
    final announcementsPage = ref.watch(adminAnnouncementsPageProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminNotificationStatsProvider);
        ref.invalidate(adminAnnouncementsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Notifications', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Manage admin announcements and view notification delivery stats.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          statsAsync.when(
            data: (stats) => KpiGrid(
              cards: [
                KpiCard(label: 'Total', value: '${stats.total}', icon: Icons.notifications_outlined),
                KpiCard(label: 'Read rate', value: '${stats.readRate}%', icon: Icons.mark_email_read_outlined),
                KpiCard(label: 'Unread', value: '${stats.unread}', icon: Icons.mark_email_unread_outlined),
                KpiCard(label: 'Failed', value: '${stats.failed}', icon: Icons.error_outline),
              ],
            ),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => Text('Could not load stats: $error'),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('New Announcement', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _messageController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Message', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _priority,
                          decoration: const InputDecoration(labelText: 'Priority'),
                          items: _priorities.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                          onChanged: (v) => setState(() => _priority = v ?? _priority),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _audience,
                          decoration: const InputDecoration(labelText: 'Audience'),
                          items: _audiences.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                          onChanged: (v) => setState(() => _audience = v ?? _audience),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _sending ? null : _sendAnnouncement,
                      icon: const Icon(Icons.campaign_outlined),
                      label: Text(_sending ? 'Sending...' : 'Send Announcement'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Announcement History', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          announcementsAsync.when(
            data: (result) {
              if (result.items.isEmpty) {
                return const AdminEmptyState(
                  message: 'No announcements yet.',
                  icon: Icons.campaign_outlined,
                );
              }
              return Column(
                children: [
                  for (final announcement in result.items) _buildAnnouncementCard(announcement),
                  PaginationBar(
                    page: result.page,
                    totalPages: result.totalPages,
                    total: result.total,
                    onPrevious: result.hasPreviousPage
                        ? () => ref.read(adminAnnouncementsPageProvider.notifier).state = announcementsPage - 1
                        : null,
                    onNext: result.hasNextPage
                        ? () => ref.read(adminAnnouncementsPageProvider.notifier).state = announcementsPage + 1
                        : null,
                  ),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => Text('Could not load announcements: $error'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(AdminAnnouncement announcement) {
    final scheduledDate = DateTime.tryParse(announcement.scheduledAt);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(announcement.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(announcement.message),
            const SizedBox(height: 4),
            Text(
              '${announcement.targetAudience} • ${announcement.priority} • ${announcement.status}'
              '${scheduledDate != null ? ' • ${DateFormat('MMM d, HH:mm').format(scheduledDate)}' : ''}',
            ),
            if (announcement.status == 'sent') Text('Recipients: ${announcement.recipientCount}'),
          ],
        ),
        isThreeLine: true,
        trailing: announcement.status == 'scheduled'
            ? IconButton(
                tooltip: 'Cancel',
                icon: const Icon(Icons.cancel_outlined),
                onPressed: () async {
                  await ref.read(adminRepositoryProvider).cancelAnnouncement(announcement.id);
                  ref.invalidate(adminAnnouncementsProvider);
                },
              )
            : null,
      ),
    );
  }
}
