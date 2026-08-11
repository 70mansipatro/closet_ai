import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/admin_user.dart';
import '../providers/admin_providers.dart';
import '../widgets/paginated_list.dart';

class _ChipOption {
  const _ChipOption(this.label, this.value);
  final String label;
  final String? value;
}

const _statusOptions = [
  _ChipOption('All', null),
  _ChipOption('Active', 'active'),
  _ChipOption('Suspended', 'suspended'),
  _ChipOption('Inactive', 'inactive'),
];

const _subscriptionOptions = [
  _ChipOption('All', null),
  _ChipOption('Free', 'free'),
  _ChipOption('Premium', 'premium'),
];

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
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
      final filter = ref.read(adminUsersFilterProvider);
      ref.read(adminUsersFilterProvider.notifier).state = filter.copyWith(
        search: value,
        page: 1,
        clearSearch: value.isEmpty,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);
    final filter = ref.watch(adminUsersFilterProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminUsersProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search by name, email or ID',
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
                    ref.read(adminUsersFilterProvider.notifier).state = filter
                        .copyWith(
                          status: option.value,
                          page: 1,
                          clearStatus: option.value == null,
                        );
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in _subscriptionOptions)
                ChoiceChip(
                  label: Text(option.label),
                  selected: filter.subscription == option.value,
                  onSelected: (selected) {
                    if (!selected) return;
                    ref.read(adminUsersFilterProvider.notifier).state = filter
                        .copyWith(
                          subscription: option.value,
                          page: 1,
                          clearSubscription: option.value == null,
                        );
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          usersAsync.when(
            data: (result) {
              if (result.items.isEmpty) {
                return const AdminEmptyState(
                  message: 'No users match these filters.',
                  icon: Icons.people_outline,
                );
              }
              return Column(
                children: [
                  for (final user in result.items) _buildUserCard(user),
                  PaginationBar(
                    page: result.page,
                    totalPages: result.totalPages,
                    total: result.total,
                    onPrevious: result.hasPreviousPage
                        ? () {
                            ref.read(adminUsersFilterProvider.notifier).state =
                                filter.copyWith(page: filter.page - 1);
                          }
                        : null,
                    onNext: result.hasNextPage
                        ? () {
                            ref.read(adminUsersFilterProvider.notifier).state =
                                filter.copyWith(page: filter.page + 1);
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
                    Text('Unable to load users: $error'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => ref.invalidate(adminUsersProvider),
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

  Widget _buildUserCard(AdminUser user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(user.name.isEmpty ? user.email : user.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                Chip(
                  label: Text(user.role),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                Chip(
                  label: Text(user.status),
                  backgroundColor: user.isSuspended
                      ? Colors.red.withValues(alpha: 0.15)
                      : Colors.green.withValues(alpha: 0.15),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                Chip(
                  label: Text(user.subscriptionPlan),
                  backgroundColor: user.isPremium
                      ? Colors.amber.withValues(alpha: 0.2)
                      : null,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Joined ${user.createdAt}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/admin/users/${user.id}'),
      ),
    );
  }
}
