import 'package:flutter/material.dart';
import 'package:closet_ai/core/theme/app_colors.dart';
import 'package:closet_ai/core/theme/app_gradients.dart';
import 'package:closet_ai/features/subscription/data/models/subscription_plan.dart';

class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.plan,
    required this.selected,
    required this.onTap,
    this.isHighlighted = false,
  });

  final SubscriptionPlan plan;
  final bool selected;
  final VoidCallback onTap;

  /// Optional override to force the premium-gradient treatment. Defaults to
  /// false; when false, the card still auto-highlights the yearly plan
  /// (matching the pre-existing "Best Value" badge logic) so no caller is
  /// required to pass this.
  final bool isHighlighted;

  bool get _isBestValue => isHighlighted || plan.planCode == 'premium_yearly';

  @override
  Widget build(BuildContext context) {
    final isPremium = plan.planCode != 'free';
    final highlighted = isPremium && _isBestValue;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                plan.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: highlighted ? AppColors.textOnDark : null,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (highlighted)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Best Value',
                  style: TextStyle(
                    color: AppColors.textOnDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          plan.description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: highlighted
                ? AppColors.textOnDark.withValues(alpha: 0.85)
                : null,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _priceLabel,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: highlighted ? AppColors.textOnDark : null,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          plan.billingPeriod == 'none'
              ? 'Free forever'
              : 'Billed ${plan.billingPeriod}',
          style: highlighted
              ? const TextStyle(color: AppColors.textOnDarkMuted)
              : null,
        ),
        const SizedBox(height: 12),
        ...plan.features.map(
          (feature) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: highlighted ? AppColors.textOnDark : AppColors.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    feature,
                    style: highlighted
                        ? const TextStyle(color: AppColors.textOnDark)
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (highlighted) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: AppGradients.premium,
          borderRadius: BorderRadius.circular(20),
          border: selected
              ? Border.all(color: AppColors.textOnDark, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: AppColors.purple.withValues(alpha: 0.3),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(padding: const EdgeInsets.all(16), child: content),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: selected ? 3 : 1,
      color: selected ? Theme.of(context).colorScheme.primaryContainer : null,
      shape: selected
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: AppColors.brightBlue, width: 2),
            )
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(16), child: content),
      ),
    );
  }

  String get _priceLabel {
    if (plan.price == 0) return '₹0';
    return '₹${plan.price.toInt()}';
  }
}
