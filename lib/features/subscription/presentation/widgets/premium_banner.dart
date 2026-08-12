import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../widgets/gradient_card.dart';

class PremiumBanner extends StatelessWidget {
  const PremiumBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GradientCard(
        gradient: AppGradients.violetPink,
        borderRadius: 16,
        onTap: () => context.go('/subscription'),
        child: Row(
          children: [
            const Icon(
              Icons.workspace_premium_outlined,
              color: AppColors.textOnDark,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unlock your full wardrobe potential',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textOnDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Unlimited AI recommendations, advanced analytics, and premium insights.',
                    style: TextStyle(color: AppColors.textOnDarkMuted),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.go('/subscription'),
              style: TextButton.styleFrom(foregroundColor: AppColors.textOnDark),
              child: const Text('Go Premium'),
            ),
          ],
        ),
      ),
    );
  }
}
