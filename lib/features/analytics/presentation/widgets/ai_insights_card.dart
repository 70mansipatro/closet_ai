import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';

/// "AI Style Insights" section. `analyticsInsightsProvider` returns
/// `{summary, insights: [{type, title, description, priority}], recommendations: [{type, clothingId}]}`.
/// The previous implementation only rendered `summary` and a raw
/// `'• type: clothingId'` list, discarding the richer `insights` array —
/// this widget surfaces that real backend/Gemini content as presentable
/// cards instead. Nothing here is invented in Flutter: every title,
/// description, and recommendation type comes straight from the response.
class AIInsightsCard extends StatelessWidget {
  const AIInsightsCard({super.key, required this.insight});

  final Map<String, dynamic> insight;

  @override
  Widget build(BuildContext context) {
    final summary = insight['summary']?.toString() ?? '';
    final insights = insight['insights'] as List<dynamic>? ?? const [];
    final recommendations = insight['recommendations'] as List<dynamic>? ?? const [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    gradient: AppGradients.premium,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Style Insights',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Personalized insights from your wardrobe',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (summary.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(summary, style: Theme.of(context).textTheme.bodyMedium),
            ],
            if (insights.isNotEmpty) ...[
              const SizedBox(height: 16),
              for (final raw in insights) ...[
                _InsightTile(insight: raw as Map),
                const SizedBox(height: 10),
              ],
            ],
            if (recommendations.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Smart Recommendations',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              for (final raw in recommendations) _RecommendationRow(recommendation: raw as Map),
            ],
            if (summary.isEmpty && insights.isEmpty && recommendations.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Keep logging wears and outfits — your AI insights will appear here once there is enough activity.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InsightMeta {
  const _InsightMeta(this.icon, this.color);
  final IconData icon;
  final Color color;
}

const Map<String, _InsightMeta> _insightMetaByType = {
  'WARDROBE': _InsightMeta(Icons.checkroom_outlined, AppColors.brightBlue),
  'COST': _InsightMeta(Icons.payments_outlined, AppColors.gold),
  'SUSTAINABILITY': _InsightMeta(Icons.eco_outlined, AppColors.green),
};

String _humanizeType(String type) {
  if (type.isEmpty) return 'Insight';
  return type
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
      .join(' ');
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({required this.insight});

  final Map insight;

  @override
  Widget build(BuildContext context) {
    final type = insight['type']?.toString() ?? '';
    final title = insight['title']?.toString() ?? _humanizeType(type);
    final description = insight['description']?.toString() ?? '';
    final meta = _insightMetaByType[type] ?? const _InsightMeta(Icons.lightbulb_outline, AppColors.purple);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: meta.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: meta.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(meta.icon, size: 20, color: meta.color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w700, color: meta.color),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(description, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationRow extends StatelessWidget {
  const _RecommendationRow({required this.recommendation});

  final Map recommendation;

  @override
  Widget build(BuildContext context) {
    final type = recommendation['type']?.toString() ?? '';
    final label = _humanizeType(type);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.arrow_right, size: 18, color: AppColors.purple),
          const SizedBox(width: 4),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
