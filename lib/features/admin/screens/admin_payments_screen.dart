import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/models/admin_payment.dart';
import '../providers/admin_providers.dart';
import '../widgets/paginated_list.dart';

const _statusOptions = <String, String>{
  '': 'All',
  'success': 'Success',
  'pending': 'Pending',
  'failed': 'Failed',
  'refunded': 'Refunded',
  'created': 'Created',
};

Color _statusColor(BuildContext context, String status) {
  switch (status) {
    case 'success':
      return Colors.green;
    case 'failed':
      return Colors.red;
    case 'pending':
    case 'refunded':
      return Colors.orange;
    default:
      return Theme.of(context).colorScheme.outline;
  }
}

String _formatDate(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  final date = DateTime.tryParse(iso);
  if (date == null) return iso;
  return DateFormat('MMM d, yyyy h:mm a').format(date.toLocal());
}

String _money(double amount, String currency) {
  final symbol = currency.toUpperCase() == 'INR' ? '₹' : '$currency ';
  return '$symbol${amount.toStringAsFixed(2)}';
}

class AdminPaymentsScreen extends ConsumerStatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  ConsumerState<AdminPaymentsScreen> createState() =>
      _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends ConsumerState<AdminPaymentsScreen> {
  late final TextEditingController _searchController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final filter = ref.read(adminPaymentsFilterProvider);
      ref.read(adminPaymentsFilterProvider.notifier).state = filter.copyWith(
        page: 1,
        search: value.trim().isEmpty ? null : value.trim(),
        clearStatus: false,
      );
    });
  }

  void _onStatusSelected(String statusValue) {
    final filter = ref.read(adminPaymentsFilterProvider);
    ref.read(adminPaymentsFilterProvider.notifier).state = filter.copyWith(
      page: 1,
      status: statusValue.isEmpty ? null : statusValue,
      clearStatus: statusValue.isEmpty,
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(adminPaymentsProvider);
    final filter = ref.watch(adminPaymentsFilterProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminPaymentsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Payments', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search by user, order or payment ID',
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
              for (final entry in _statusOptions.entries)
                ChoiceChip(
                  label: Text(entry.value),
                  selected: (filter.status ?? '') == entry.key,
                  onSelected: (_) => _onStatusSelected(entry.key),
                ),
            ],
          ),
          const SizedBox(height: 16),
          paymentsAsync.when(
            data: (result) {
              if (result.items.isEmpty) {
                return const AdminEmptyState(
                  message: 'No payments match the current filters.',
                  icon: Icons.payments_outlined,
                );
              }
              return Column(
                children: [
                  for (final payment in result.items)
                    _buildPaymentCard(context, payment),
                  PaginationBar(
                    page: result.page,
                    totalPages: result.totalPages,
                    total: result.total,
                    onPrevious: result.hasPreviousPage
                        ? () => ref
                              .read(adminPaymentsFilterProvider.notifier)
                              .state = filter.copyWith(page: filter.page - 1)
                        : null,
                    onNext: result.hasNextPage
                        ? () => ref
                              .read(adminPaymentsFilterProvider.notifier)
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
                    Text('Unable to load payments: $error'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => ref.invalidate(adminPaymentsProvider),
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

  Widget _buildPaymentCard(BuildContext context, AdminPayment payment) {
    final displayName = payment.userName.isNotEmpty
        ? payment.userName
        : payment.userEmail;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showPaymentDetail(context, payment),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      displayName.isEmpty ? 'Unknown user' : displayName,
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Chip(
                    label: Text(payment.status),
                    backgroundColor: _statusColor(
                      context,
                      payment.status,
                    ).withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: _statusColor(context, payment.status),
                      fontWeight: FontWeight.bold,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              if (payment.userEmail.isNotEmpty && payment.userName.isNotEmpty)
                Text(
                  payment.userEmail,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const SizedBox(height: 8),
              Text(
                _money(payment.amount, payment.currency),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text('Order: ${payment.orderId.isEmpty ? '—' : payment.orderId}'),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    payment.provider,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(payment.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentDetail(BuildContext context, AdminPayment payment) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Payment Detail'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('User', payment.userName),
              _detailRow('Email', payment.userEmail),
              _detailRow('Order ID', payment.orderId),
              _detailRow('Payment ID', payment.paymentId),
              _detailRow('Provider', payment.provider),
              _detailRow(
                'Amount',
                _money(payment.amount, payment.currency),
              ),
              _detailRow('Status', payment.status),
              if (payment.failureReason.isNotEmpty)
                _detailRow('Failure reason', payment.failureReason),
              _detailRow('Created', _formatDate(payment.createdAt)),
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value.isEmpty ? '—' : value)),
        ],
      ),
    );
  }
}
