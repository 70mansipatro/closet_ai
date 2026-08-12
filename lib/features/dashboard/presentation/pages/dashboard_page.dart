import 'package:closet_ai/core/theme/app_colors.dart';
import 'package:closet_ai/core/theme/app_gradients.dart';
import 'package:closet_ai/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:closet_ai/features/subscription/presentation/widgets/premium_banner.dart';
import 'package:closet_ai/widgets/gradient_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: const [NotificationBell()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const PremiumBanner(),
          const SizedBox(height: 4),
          // Flagship AI feature — gradient hero card to draw attention.
          const _AiHeroCard(
            title: 'Today’s outfit',
            subtitle: 'Smart recommendation ready',
          ),
          const SizedBox(height: 12),
          _GlassStatCard(
            icon: Icons.insights_outlined,
            accentColor: AppColors.cyan,
            title: 'Analytics',
            subtitle: 'View wardrobe usage and trends',
            onTap: () => context.go('/analytics'),
          ),
          const SizedBox(height: 12),
          _FeatureCard(
            title: 'Laundry reminder',
            subtitle: '3 items need attention',
            onTap: () => context.go('/laundry'),
          ),
          const _FeatureCard(
            title: 'Packing list',
            subtitle: 'Weekend trip prepared',
          ),
        ],
      ),
    );
  }
}

/// Flagship "AI recommendation" teaser — uses the primary brand gradient
/// (cyan -> blue -> purple -> pink) to stand out as the app's hero AI
/// feature, per the dashboard's KPI/highlight styling.
class _AiHeroCard extends StatelessWidget {
  const _AiHeroCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      gradient: AppGradients.primary,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white),
        ],
      ),
    );
  }
}

/// Secondary KPI-style highlight — a subtle translucent glass card with a
/// colored accent, used for stats/analytics rather than the loud full
/// gradient treatment reserved for the AI hero card.
class _GlassStatCard extends StatelessWidget {
  const _GlassStatCard({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return GlassCard(
      accentColor: accentColor,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: textColor.withValues(alpha: 0.6)),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.title, required this.subtitle, this.onTap});

  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: ListTile(
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}
