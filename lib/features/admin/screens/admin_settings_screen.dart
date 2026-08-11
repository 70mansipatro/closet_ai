import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/admin_settings.dart';
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

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final _messageController = TextEditingController();
  final _announcementController = TextEditingController();
  bool _maintenanceEnabled = false;
  bool _seeded = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _messageController.dispose();
    _announcementController.dispose();
    super.dispose();
  }

  void _seedFrom(AdminSettings settings) {
    if (_seeded) return;
    _messageController.text = settings.maintenanceMessage;
    _announcementController.text = settings.announcementBanner;
    _maintenanceEnabled = settings.maintenanceModeEnabled;
    _seeded = true;
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final updated = AdminSettings(
        maintenanceModeEnabled: _maintenanceEnabled,
        maintenanceMessage: _messageController.text.trim(),
        announcementBanner: _announcementController.text.trim(),
      );
      await ref.read(adminRepositoryProvider).updateSettings(updated);
      ref.invalidate(adminSettingsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_extractErrorMessage(error))),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(adminSettingsProvider);
    final permissions = ref.watch(currentUserPermissionsProvider);
    final canManage = permissions.contains('settings.manage');

    return RefreshIndicator(
      onRefresh: () async {
        _seeded = false;
        ref.invalidate(adminSettingsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Settings', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          settingsAsync.when(
            data: (settings) {
              _seedFrom(settings);
              return _buildForm(context, canManage);
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 64),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Unable to load settings: $error'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => ref.invalidate(adminSettingsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context, bool canManage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!canManage)
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.visibility_outlined),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "View-only — you don't have permission to change settings.",
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Maintenance mode'),
                subtitle: const Text(
                  'When enabled, non-admin users will see the maintenance message '
                  'instead of the app.',
                ),
                value: _maintenanceEnabled,
                onChanged: canManage
                    ? (value) => setState(() => _maintenanceEnabled = value)
                    : null,
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _messageController,
                  enabled: canManage,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Maintenance message',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Announcement banner',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _announcementController,
                  enabled: canManage,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Banner text',
                    hintText: 'Shown to all users at the top of the app.',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Per-plan feature limits (free/premium wardrobe, AI and trip '
                    'limits) are managed from the Plans screen\'s limits editor, '
                    'not here, to avoid duplicating that configuration in two '
                    'places.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (canManage) ...[
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_isSaving ? 'Saving...' : 'Save Settings'),
          ),
        ],
      ],
    );
  }
}
