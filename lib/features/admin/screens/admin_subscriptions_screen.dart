import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/admin_subscription.dart';
import '../providers/admin_providers.dart';
import '../widgets/paginated_list.dart';

class _ChipOption {
  const _ChipOption(this.label, this.value);
  final String label;
  final String? value;
}

const _statusOptions = [
  _ChipOption('All', null),
  _ChipOption('Pending', 'pending'),
  _ChipOption('Active', 'active'),
  _ChipOption('Cancelled', 'cancelled'),
  _ChipOption('Expired', 'expired'),
  _ChipOption('Past Due', 'past_due'),
  _ChipOption('Failed', 'failed'),
];

class AdminSubscriptionsScreen extends ConsumerStatefulWidget {
  const AdminSubscriptionsScreen({super.key});

  @override
  ConsumerState<AdminSubscriptionsScreen> createState() =>
      _AdminSubscriptionsScreenState();
}

class _AdminSubscriptionsScreenState
    extends ConsumerState<AdminSubscriptionsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final filter = ref.read(adminSubscriptionsFilterProvider);
      ref.read(adminSubscriptionsFilterProvider.notifier).state = filter
          .copyWith(search: value, page: 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionsAsync = ref.watch(adminSubscriptionsProvider);
    final filter = ref.watch(adminSubscriptionsFilterProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminSubscriptionsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search by user name or email',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in _statusOptions)
                ChoiceChip(
                  label: Text(option.label),
                  selected: filter.status == option.value,
                  onSelected: (selected) {
                    if (!selected) return;
                    ref.read(adminSubscriptionsFilterProvider.notifier).state =
                        filter.copyWith(
                      status: option.value,
                      page: 1,
                      clearStatus: option.value == null,
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          subscriptionsAsync.when(
            data: (result) {
              if (result.items.isEmpty) {
                return const AdminEmptyState(
                  message: 'No subscriptions match these filters.',
                  icon: Icons.card_membership_outlined,
                );
              }
              return Column(
                children: [
                  for (final subscription in result.items)
                    _buildSubscriptionCard(subscription),
                  PaginationBar(
                    page: result.page,
                    totalPages: result.totalPages,
                    total: result.total,
                    onPrevious: result.hasPreviousPage
                        ? () {
                            ref
                                .read(adminSubscriptionsFilterProvider.notifier)
                                .state = filter.copyWith(page: filter.page - 1);
                          }
                        : null,
                    onNext: result.hasNextPage
                        ? () {
                            ref
                                .read(adminSubscriptionsFilterProvider.notifier)
                                .state = filter.copyWith(page: filter.page + 1);
                          }
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
                    Text('Unable to load subscriptions: $error'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () =>
                          ref.invalidate(adminSubscriptionsProvider),
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

  Widget _buildSubscriptionCard(AdminSubscription subscription) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          subscription.userName.isEmpty
              ? subscription.userEmail
              : subscription.userName,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subscription.userEmail),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                Chip(
                  label: Text(subscription.planName ?? subscription.planType),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                Chip(
                  label: Text(subscription.status),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ],
        ),
        trailing: Text('${subscription.currency} ${subscription.amount.toStringAsFixed(0)}'),
        isThreeLine: true,
        onTap: () => _showDetailDialog(subscription),
      ),
    );
  }

  void _showDetailDialog(AdminSubscription subscription) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          subscription.userName.isEmpty
              ? subscription.userEmail
              : subscription.userName,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('User: ${subscription.userEmail}'),
              const SizedBox(height: 8),
              Text('Plan: ${subscription.planName ?? subscription.planType}'),
              Text('Status: ${subscription.status}'),
              const SizedBox(height: 8),
              Text('Start date: ${subscription.startDate ?? '—'}'),
              Text('End date: ${subscription.endDate ?? '—'}'),
              Text('Auto renew: ${subscription.autoRenew ? 'Yes' : 'No'}'),
              const SizedBox(height: 8),
              Text(
                'Amount: ${subscription.currency} ${subscription.amount.toStringAsFixed(2)}',
              ),
              Text('Payment provider: ${subscription.paymentProvider.isEmpty ? '—' : subscription.paymentProvider}'),
              Text(
                'Provider subscription ID: ${subscription.providerSubscriptionId.isEmpty ? '—' : subscription.providerSubscriptionId}',
              ),
              if (subscription.createdAt != null)
                Text('Created: ${subscription.createdAt}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
