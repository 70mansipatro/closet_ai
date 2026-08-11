import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/admin_user.dart';
import '../providers/admin_access_provider.dart';
import '../providers/admin_providers.dart';

String _extractErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
      if (data['data'] is Map) {
        final nestedMessage = data['data']['message'] ?? data['data']['error'];
        if (nestedMessage is String && nestedMessage.isNotEmpty) {
          return nestedMessage;
        }
      }
    }
    if (error.response?.statusCode != null) {
      return 'The server returned ${error.response!.statusCode}. Please try again.';
    }
    if (error.message != null && error.message!.isNotEmpty) {
      return error.message!;
    }
  }
  return error.toString();
}

const _roleOptions = ['user', 'admin', 'super_admin'];

class AdminUserDetailScreen extends ConsumerWidget {
  const AdminUserDetailScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(adminUserDetailProvider(userId));
    final permissions = ref.watch(currentUserPermissionsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminUserDetailProvider(userId));
      },
      child: userAsync.when(
        data: (user) => _buildDetail(context, ref, user, permissions),
        loading: () => ListView(
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 96),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
        error: (error, stack) => ListView(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 64),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Unable to load user: $error'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () =>
                          ref.invalidate(adminUserDetailProvider(userId)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetail(
    BuildContext context,
    WidgetRef ref,
    AdminUser user,
    List<String> permissions,
  ) {
    final canSuspend = permissions.contains('users.suspend');
    final canManage = permissions.contains('users.manage');
    final canDelete = permissions.contains('users.delete');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name.isEmpty ? user.email : user.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(user.email),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text('Role: ${user.role}')),
                    Chip(label: Text('Status: ${user.status}')),
                    Chip(label: Text('Plan: ${user.subscriptionPlan}')),
                    Chip(
                      label: Text('Subscription: ${user.subscriptionStatus}'),
                    ),
                    if (user.isVerified) const Chip(label: Text('Verified')),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.phone_outlined),
                title: const Text('Phone'),
                trailing: Text(user.phone.isEmpty ? '—' : user.phone),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.event_available_outlined),
                title: const Text('Created'),
                trailing: Text(user.createdAt),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.login_outlined),
                title: const Text('Last login'),
                trailing: Text(user.lastLoginAt ?? '—'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.checkroom_outlined),
                title: const Text('Wardrobe items'),
                trailing: Text('${user.wardrobeCount ?? 0}'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.style_outlined),
                title: const Text('Outfits'),
                trailing: Text('${user.outfitCount ?? 0}'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.flight_outlined),
                title: const Text('Trips'),
                trailing: Text('${user.tripCount ?? 0}'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.local_laundry_service_outlined),
                title: const Text('Laundry records'),
                trailing: Text('${user.laundryCount ?? 0}'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI usage',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (user.aiUsage.isEmpty)
                  const Text('No AI usage recorded.')
                else
                  for (final entry in user.aiUsage)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '${entry['feature'] ?? 'unknown'}: ${entry['count'] ?? 0}'
                        '${entry['period'] != null ? ' (${entry['period']})' : ''}',
                      ),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (canSuspend)
          FilledButton.tonalIcon(
            onPressed: () => _toggleStatus(context, ref, user),
            icon: Icon(
              user.isSuspended ? Icons.check_circle_outline : Icons.block_outlined,
            ),
            label: Text(user.isSuspended ? 'Activate User' : 'Suspend User'),
          ),
        if (canSuspend) const SizedBox(height: 8),
        if (canManage)
          OutlinedButton.icon(
            onPressed: () => _showChangeRoleDialog(context, ref, user),
            icon: const Icon(Icons.admin_panel_settings_outlined),
            label: const Text('Change Role'),
          ),
        if (canManage) const SizedBox(height: 8),
        if (canDelete)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              side: BorderSide(color: Theme.of(context).colorScheme.error),
            ),
            onPressed: () => _confirmDelete(context, ref, user),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete User'),
          ),
      ],
    );
  }

  Future<void> _toggleStatus(
    BuildContext context,
    WidgetRef ref,
    AdminUser user,
  ) async {
    final newStatus = user.isSuspended ? 'active' : 'suspended';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(newStatus == 'suspended' ? 'Suspend user?' : 'Activate user?'),
        content: Text(
          newStatus == 'suspended'
              ? 'This will prevent ${user.name.isEmpty ? user.email : user.name} from signing in.'
              : 'This will restore access for ${user.name.isEmpty ? user.email : user.name}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(adminRepositoryProvider).updateUserStatus(
            user.id,
            newStatus,
          );
      ref.invalidate(adminUserDetailProvider(user.id));
      ref.invalidate(adminUsersProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User status updated to $newStatus.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_extractErrorMessage(error))),
      );
    }
  }

  Future<void> _showChangeRoleDialog(
    BuildContext context,
    WidgetRef ref,
    AdminUser user,
  ) async {
    final isSuperAdmin = ref.read(isSuperAdminProvider);
    var selectedRole = user.role;

    final newRole = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: const Text('Change role'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: [
                      for (final role in _roleOptions)
                        DropdownMenuItem(
                          value: role,
                          enabled: role != 'super_admin' || isSuperAdmin,
                          child: Text(role),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => selectedRole = value);
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Note: admins cannot change their own role. The server '
                    'will reject the change if this account belongs to you.',
                    style: Theme.of(dialogContext).textTheme.bodySmall,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(selectedRole),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (newRole == null || newRole == user.role) return;

    try {
      await ref.read(adminRepositoryProvider).updateUserRole(user.id, newRole);
      ref.invalidate(adminUserDetailProvider(user.id));
      ref.invalidate(adminUsersProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Role updated to $newRole.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_extractErrorMessage(error))),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AdminUser user,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete user?'),
        content: Text(
          'This will anonymize ${user.name.isEmpty ? user.email : user.name}\'s '
          'account. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(adminRepositoryProvider).deleteUser(user.id);
      ref.invalidate(adminUsersProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted.')),
      );
      context.pop();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_extractErrorMessage(error))),
      );
    }
  }
}
