import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:closet_ai/features/notifications/application/notification_providers.dart';
import 'package:closet_ai/features/notifications/domain/notification_model.dart';

class _FilterOption {
  const _FilterOption(this.label, this.type, {this.unreadOnly = false});
  final String label;
  final String? type;
  final bool unreadOnly;
}

const _filters = [
  _FilterOption('All', null),
  _FilterOption('Unread', null, unreadOnly: true),
  _FilterOption('Outfit', 'OUTFIT_REMINDER'),
  _FilterOption('Laundry', 'LAUNDRY_REMINDER'),
  _FilterOption('Trip', 'TRIP_REMINDER'),
  _FilterOption('Premium', 'PREMIUM_EXPIRY'),
  _FilterOption('System', 'SYSTEM'),
];

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  int _selectedFilter = 0;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(notificationListProvider.notifier).loadMore();
    }
  }

  void _handleTap(NotificationModel notification) async {
    if (!notification.isRead) {
      await ref.read(notificationListProvider.notifier).markAsRead(notification.id);
    }
    if (notification.actionRoute.isNotEmpty && mounted) {
      context.go(notification.actionRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Mark all as read',
            icon: const Icon(Icons.done_all),
            onPressed: () => ref.read(notificationListProvider.notifier).markAllAsRead(),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final selected = index == _selectedFilter;
                return ChoiceChip(
                  label: Text(filter.label),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _selectedFilter = index);
                    ref.read(notificationListProvider.notifier).setFilter(
                          type: filter.type,
                          unreadOnly: filter.unreadOnly,
                        );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  Widget _buildBody(NotificationListState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 8),
            Text('Could not load notifications'),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => ref.read(notificationListProvider.notifier).load(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.notifications_none, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('No notifications yet.'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(notificationListProvider.notifier).load(),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.items.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index >= state.items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final notification = state.items[index];
          return _NotificationTile(
            notification: notification,
            onTap: () => _handleTap(notification),
            onDismiss: () => ref.read(notificationListProvider.notifier).delete(notification.id),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap, required this.onDismiss});

  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  Color _priorityColor(BuildContext context) {
    switch (notification.priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = notificationInfoFor(notification.type);
    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete_outline),
      ),
      onDismissed: (_) => onDismiss(),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: _priorityColor(context).withValues(alpha: 0.15),
          child: Icon(info.icon, color: _priorityColor(context)),
        ),
        title: Text(
          notification.title,
          style: TextStyle(fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold),
        ),
        subtitle: Text(notification.message, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(DateFormat('MMM d, HH:mm').format(notification.createdAt), style: Theme.of(context).textTheme.bodySmall),
            if (!notification.isRead)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: _priorityColor(context), shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}
