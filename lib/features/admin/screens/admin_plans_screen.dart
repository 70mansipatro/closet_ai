import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../data/models/admin_plan.dart';
import '../providers/admin_access_provider.dart';
import '../providers/admin_providers.dart';
import '../widgets/paginated_list.dart';

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

const _billingPeriods = ['none', 'monthly', 'yearly'];

class AdminPlansScreen extends ConsumerWidget {
  const AdminPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(adminPlansProvider);
    final permissions = ref.watch(currentUserPermissionsProvider);
    final canManage = permissions.contains('plans.manage');

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminPlansProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Plans',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (canManage)
                FilledButton.icon(
                  onPressed: () => _showPlanFormDialog(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('New Plan'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          plansAsync.when(
            data: (plans) {
              if (plans.isEmpty) {
                return const AdminEmptyState(
                  message: 'No plans have been created yet.',
                  icon: Icons.workspace_premium_outlined,
                );
              }
              final sorted = [...plans]
                ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
              return Column(
                children: [
                  for (final plan in sorted)
                    _buildPlanCard(context, ref, plan, canManage),
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
                    Text('Unable to load plans: $error'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => ref.invalidate(adminPlansProvider),
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

  Widget _buildPlanCard(
    BuildContext context,
    WidgetRef ref,
    AdminPlan plan,
    bool canManage,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: canManage ? () => _showPlanFormDialog(context, ref, plan: plan) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      plan.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Chip(
                    label: Text(plan.isActive ? 'Active' : 'Inactive'),
                    backgroundColor: plan.isActive
                        ? AppColors.success.withValues(alpha: 0.15)
                        : Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: plan.isActive
                          ? AppColors.success
                          : Theme.of(context).colorScheme.outline,
                      fontWeight: FontWeight.w600,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                plan.planCode,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                '${plan.currency} ${plan.price.toStringAsFixed(0)} / ${plan.billingPeriod}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (plan.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(plan.description),
              ],
              if (plan.features.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final feature in plan.features)
                      Chip(
                        label: Text(feature),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
              ],
              if (plan.limits.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Limits',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 4),
                for (final entry in plan.limits.entries)
                  Text('${entry.key}: ${entry.value.toString()}'),
              ],
              if (canManage) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmStatusChange(context, ref, plan),
                    icon: Icon(
                      plan.isActive
                          ? Icons.toggle_off_outlined
                          : Icons.toggle_on_outlined,
                    ),
                    label: Text(plan.isActive ? 'Deactivate' : 'Activate'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmStatusChange(
    BuildContext context,
    WidgetRef ref,
    AdminPlan plan,
  ) async {
    final newStatus = !plan.isActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(newStatus ? 'Activate plan?' : 'Deactivate plan?'),
        content: Text(
          newStatus
              ? '${plan.name} will become available for subscription.'
              : '${plan.name} will no longer be available for new subscriptions.',
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
      await ref.read(adminRepositoryProvider).setPlanStatus(plan.id, newStatus);
      ref.invalidate(adminPlansProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus ? 'Plan activated.' : 'Plan deactivated.'),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_extractErrorMessage(error))),
      );
    }
  }

  Future<void> _showPlanFormDialog(
    BuildContext context,
    WidgetRef ref, {
    AdminPlan? plan,
  }) async {
    final isEditing = plan != null;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: plan?.name ?? '');
    final planCodeController =
        TextEditingController(text: plan?.planCode ?? '');
    final descriptionController =
        TextEditingController(text: plan?.description ?? '');
    final priceController = TextEditingController(
      text: plan != null ? plan.price.toString() : '',
    );
    final currencyController =
        TextEditingController(text: plan?.currency ?? 'INR');
    final featuresController =
        TextEditingController(text: plan?.features.join(', ') ?? '');
    final sortOrderController = TextEditingController(
      text: plan != null ? plan.sortOrder.toString() : '0',
    );
    var billingPeriod = plan?.billingPeriod ?? 'monthly';

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit plan' : 'New plan'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (value) => (value == null || value.trim().isEmpty)
                            ? 'Name is required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: planCodeController,
                        enabled: !isEditing,
                        decoration: const InputDecoration(labelText: 'Plan code'),
                        validator: (value) => (value == null || value.trim().isEmpty)
                            ? 'Plan code is required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(labelText: 'Description'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: priceController,
                        decoration: const InputDecoration(labelText: 'Price'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Price is required';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: currencyController,
                        decoration: const InputDecoration(labelText: 'Currency'),
                        validator: (value) => (value == null || value.trim().isEmpty)
                            ? 'Currency is required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: billingPeriod,
                        decoration: const InputDecoration(labelText: 'Billing period'),
                        items: [
                          for (final period in _billingPeriods)
                            DropdownMenuItem(value: period, child: Text(period)),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => billingPeriod = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: featuresController,
                        decoration: const InputDecoration(
                          labelText: 'Features (comma separated)',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: sortOrderController,
                        decoration: const InputDecoration(labelText: 'Sort order'),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() != true) return;
                    Navigator.of(dialogContext).pop(true);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) return;

    final payload = <String, dynamic>{
      'name': nameController.text.trim(),
      'description': descriptionController.text.trim(),
      'price': double.tryParse(priceController.text.trim()) ?? 0,
      'currency': currencyController.text.trim(),
      'billingPeriod': billingPeriod,
      'features': featuresController.text
          .split(',')
          .map((feature) => feature.trim())
          .where((feature) => feature.isNotEmpty)
          .toList(),
      'sortOrder': int.tryParse(sortOrderController.text.trim()) ?? 0,
    };
    if (!isEditing) {
      payload['planCode'] = planCodeController.text.trim();
    }

    try {
      final repository = ref.read(adminRepositoryProvider);
      if (isEditing) {
        await repository.updatePlan(plan.id, payload);
      } else {
        await repository.createPlan(payload);
      }
      ref.invalidate(adminPlansProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Plan updated.' : 'Plan created.'),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_extractErrorMessage(error))),
      );
    }
  }
}
