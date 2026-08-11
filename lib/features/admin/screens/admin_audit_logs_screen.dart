import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/models/admin_audit_log.dart';
import '../providers/admin_providers.dart';
import '../widgets/paginated_list.dart';

const _quickActionFilters = <String>[
  'USER_SUSPENDED',
  'USER_ACTIVATED',
  'USER_ROLE_CHANGED',
  'USER_DELETED',
  'PLAN_CREATED',
  'PLAN_UPDATED',
  'PLAN_ACTIVATED',
  'PLAN_DEACTIVATED',
  'REPORT_EXPORTED',
  'SETTINGS_CHANGED',
];

IconData _iconForAction(String action) {
  if (action.contains('SUSPEND') || action.contains('BLOCK')) {
    return Icons.block_outlined;
  }
  if (action.contains('ACTIVAT')) return Icons.check_circle_outline;
  if (action.contains('ROLE')) return Icons.admin_panel_settings_outlined;
  if (action.contains('DELETE')) return Icons.delete_outline;
  if (action.contains('PLAN')) return Icons.workspace_premium_outlined;
  if (action.contains('REPORT')) return Icons.description_outlined;
  if (action.contains('SETTING')) return Icons.settings_outlined;
  if (action.contains('SUBSCRIPTION')) return Icons.card_membership_outlined;
  return Icons.fact_check_outlined;
}

String _formatDate(String iso) {
  if (iso.isEmpty) return '—';
  final date = DateTime.tryParse(iso);
  if (date == null) return iso;
  return DateFormat('MMM d, yyyy h:mm a').format(date.toLocal());
}

class AdminAuditLogsScreen extends ConsumerStatefulWidget {
  const AdminAuditLogsScreen({super.key});

  @override
  ConsumerState<AdminAuditLogsScreen> createState() =>
      _AdminAuditLogsScreenState();
}

class _AdminAuditLogsScreenState extends ConsumerState<AdminAuditLogsScreen> {
  late final TextEditingController _actionController;

  @override
  void initState() {
    super.initState();
    _actionController = TextEditingController();
  }

  @override
  void dispose() {
    _actionController.dispose();
    super.dispose();
  }

  void _applyAction(String? action) {
    final filter = ref.read(adminAuditLogsFilterProvider);
    ref.read(adminAuditLogsFilterProvider.notifier).state = filter.copyWith(
      page: 1,
      action: action,
      clearAction: action == null,
    );
    _actionController.text = action ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(adminAuditLogsProvider);
    final filter = ref.watch(adminAuditLogsFilterProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminAuditLogsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Audit Logs', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Read-only history of administrative actions.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _actionController,
            decoration: const InputDecoration(
              labelText: 'Filter by action',
              hintText: 'e.g. USER_SUSPENDED',
              prefixIcon: Icon(Icons.filter_alt_outlined),
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) =>
                _applyAction(value.trim().isEmpty ? null : value.trim()),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: (filter.action ?? '').isEmpty,
                onSelected: (_) => _applyAction(null),
              ),
              for (final action in _quickActionFilters)
                ChoiceChip(
                  label: Text(action),
                  selected: filter.action == action,
                  onSelected: (_) => _applyAction(action),
                ),
            ],
          ),
          const SizedBox(height: 16),
          logsAsync.when(
            data: (result) {
              if (result.items.isEmpty) {
                return const AdminEmptyState(
                  message: 'No audit log entries match the current filter.',
                  icon: Icons.fact_check_outlined,
                );
              }
              return Column(
                children: [
                  for (final log in result.items) _buildLogCard(context, log),
                  PaginationBar(
                    page: result.page,
                    totalPages: result.totalPages,
                    total: result.total,
                    onPrevious: result.hasPreviousPage
                        ? () => ref
                              .read(adminAuditLogsFilterProvider.notifier)
                              .state = filter.copyWith(page: filter.page - 1)
                        : null,
                    onNext: result.hasNextPage
                        ? () => ref
                              .read(adminAuditLogsFilterProvider.notifier)
                              .state = filter.copyWith(page: filter.page + 1)
                        : null,
                  ),
                ],
              );
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
                    Text('Unable to load audit logs: $error'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => ref.invalidate(adminAuditLogsProvider),
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

  Widget _buildLogCard(BuildContext context, AdminAuditLog log) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_iconForAction(log.action), color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.action,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    log.adminName.isEmpty
                        ? log.adminEmail
                        : '${log.adminName} (${log.adminEmail})',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (log.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(log.description),
                  ],
                  if (log.targetType.isNotEmpty || log.targetId.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Target: ${log.targetType} ${log.targetId}'.trim(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        _formatDate(log.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (log.ipAddress.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Icon(
                          Icons.lan_outlined,
                          size: 14,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          log.ipAddress,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
