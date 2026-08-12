import 'package:closet_ai/core/theme/app_colors.dart';
import 'package:closet_ai/features/subscription/data/models/subscription.dart';
import 'package:closet_ai/features/subscription/data/models/subscription_plan.dart';
import 'package:closet_ai/features/subscription/data/utils/payment_signature.dart';
import 'package:closet_ai/features/subscription/presentation/widgets/plan_card.dart';
import 'package:closet_ai/features/subscription/presentation/widgets/premium_banner.dart';
import 'package:closet_ai/features/subscription/providers/subscription_providers.dart';
import 'package:closet_ai/widgets/gradient_button.dart';
import 'package:closet_ai/widgets/gradient_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SubscriptionPage extends ConsumerStatefulWidget {
  const SubscriptionPage({super.key});

  @override
  ConsumerState<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends ConsumerState<SubscriptionPage> {
  String _selectedPlan = 'premium_monthly';
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(subscriptionPlansProvider);
    final currentAsync = ref.watch(currentSubscriptionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Upgrade to ClosetAI Premium')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(subscriptionPlansProvider);
          ref.invalidate(currentSubscriptionProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Unlock your complete AI wardrobe experience.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const PremiumBanner(),
            if (currentAsync.hasValue)
              _buildSubscriptionStatus(currentAsync.valueOrNull),
            const SizedBox(height: 12),
            const Text(
              'Choose a plan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            plansAsync.when(
              data: (plans) => Column(
                children: [
                  for (final plan in plans)
                    PlanCard(
                      plan: plan,
                      selected: _selectedPlan == plan.planCode,
                      onTap: () =>
                          setState(() => _selectedPlan = plan.planCode),
                    ),
                  const SizedBox(height: 16),
                  GradientButton(
                    variant: GradientButtonVariant.premium,
                    label: _isProcessing ? 'Processing...' : 'Subscribe Now',
                    icon: _isProcessing ? null : Icons.payment_outlined,
                    loading: _isProcessing,
                    onPressed: _isProcessing
                        ? null
                        : () => _subscribe(context, plans),
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text('Unable to load plans: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionStatus(SubscriptionStatusModel? status) {
    if (status == null) return const SizedBox.shrink();
    final isActive = status.status == 'active';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        accentColor: isActive ? AppColors.green : AppColors.purple,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isActive ? Icons.workspace_premium : Icons.info_outline,
                  color: isActive ? AppColors.green : AppColors.purple,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isActive ? 'Premium Active' : 'Current plan',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Plan: ${status.plan}'),
            Text('Status: ${status.status}'),
            if (status.daysRemaining > 0)
              Text('Days remaining: ${status.daysRemaining}'),
            const SizedBox(height: 8),
            Row(
              children: [
                FilledButton.tonal(
                  onPressed: _isProcessing
                      ? null
                      : () => _manageSubscription(context),
                  child: const Text('Manage Subscription'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _isProcessing
                      ? null
                      : () => _cancelOrRestoreSubscription(context),
                  child: Text(isActive ? 'Cancel' : 'Restore'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _subscribe(
    BuildContext context,
    List<SubscriptionPlan> plans,
  ) async {
    final selected = plans
        .where((plan) => plan.planCode == _selectedPlan)
        .firstOrNull;
    if (selected == null) return;

    setState(() => _isProcessing = true);

    try {
      final repository = ref.read(subscriptionRepositoryProvider);
      final order = await repository.createOrder(selected.planCode);

      if (!mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Complete your upgrade'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Plan: ${selected.name}'),
                const SizedBox(height: 8),
                Text('Order ID: ${order.orderId}'),
                Text('Amount: ₹${(order.amount / 100).toInt()}'),
                const SizedBox(height: 8),
                const Text(
                  'This demo checkout completes the premium flow end to end with the backend verification step.',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Complete Checkout'),
              ),
            ],
          );
        },
      );

      if (confirmed != true) return;

      final paymentId = 'demo_payment_${DateTime.now().millisecondsSinceEpoch}';
      final signature = buildDemoPaymentSignature(order.orderId, paymentId);
      final verification = await repository.verifyPayment(
        orderId: order.orderId,
        paymentId: paymentId,
        signature: signature,
        planCode: selected.planCode,
      );

      if (!mounted) return;
      if (verification.success) {
        ref.invalidate(currentSubscriptionProvider);
        ref.invalidate(subscriptionPlansProvider);
        context.go('/subscription/success', extra: selected.name);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              verification.message ?? 'Unable to confirm your subscription.',
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Checkout failed: $error')));
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _manageSubscription(BuildContext context) async {
    setState(() => _isProcessing = true);
    try {
      final repository = ref.read(subscriptionRepositoryProvider);
      await repository.checkStatus();
      ref.invalidate(currentSubscriptionProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subscription status refreshed.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to refresh subscription: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _cancelOrRestoreSubscription(BuildContext context) async {
    setState(() => _isProcessing = true);
    try {
      final repository = ref.read(subscriptionRepositoryProvider);
      final status = await repository.checkStatus();
      final isActive = status.status == 'active';
      if (isActive) {
        await repository.cancelSubscription();
      } else {
        await repository.restoreSubscription();
      }
      ref.invalidate(currentSubscriptionProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isActive
                ? 'Subscription cancellation requested.'
                : 'Subscription restored.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Subscription update failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
