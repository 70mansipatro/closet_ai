import 'package:flutter/material.dart';

import '../../../../widgets/gradient_button.dart';

/// A pulsing rounded placeholder block shown while a section's provider is
/// loading, in place of a bare [CircularProgressIndicator]. Purely decorative
/// — callers control size via [height]/[width].
class AnalyticsSectionSkeleton extends StatefulWidget {
  const AnalyticsSectionSkeleton({
    super.key,
    this.height = 120,
    this.width,
    this.borderRadius = 20,
  });

  final double height;
  final double? width;
  final double borderRadius;

  @override
  State<AnalyticsSectionSkeleton> createState() =>
      _AnalyticsSectionSkeletonState();
}

class _AnalyticsSectionSkeletonState extends State<AnalyticsSectionSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.outline;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final alpha = 0.08 + (_controller.value * 0.10);
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: base.withValues(alpha: alpha),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

/// Compact, non-technical error surface for a single analytics section.
/// [onRetry] should invalidate only that section's provider, not the whole
/// page.
class AnalyticsErrorCard extends StatelessWidget {
  const AnalyticsErrorCard({
    super.key,
    required this.onRetry,
    this.message = "We couldn't load this analytics section.",
  });

  final VoidCallback onRetry;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wifi_off_outlined, color: colorScheme.primary, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Something went wrong',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(message, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-page placeholder shown instead of the analytics dashboard when the
/// user's wardrobe has zero clothing items — every other section would just
/// render fake-looking zeroes, so we replace them with a single CTA instead.
class AnalyticsEmptyWardrobe extends StatelessWidget {
  const AnalyticsEmptyWardrobe({super.key, required this.onAddClothing});

  final VoidCallback onAddClothing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: Column(
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 40,
            color: colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Your wardrobe is waiting ✨',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first clothing item to unlock wardrobe insights.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.65),
                ),
          ),
          const SizedBox(height: 24),
          GradientButton(
            label: 'Add Clothing',
            icon: Icons.add,
            expand: false,
            onPressed: onAddClothing,
          ),
        ],
      ),
    );
  }
}

/// Friendly "nothing tracked yet" placeholder for a section whose data
/// loaded successfully but is empty.
class AnalyticsEmptyState extends StatelessWidget {
  const AnalyticsEmptyState({
    super.key,
    this.icon = Icons.auto_awesome_outlined,
    this.title = 'No Data Yet',
    this.message =
        'Start wearing and tracking your outfits to unlock wardrobe insights.',
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        child: Column(
          children: [
            Icon(icon, size: 32, color: colorScheme.onSurface.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
