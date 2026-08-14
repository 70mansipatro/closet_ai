import 'package:closet_ai/core/theme/app_colors.dart';
import 'package:closet_ai/core/theme/app_gradients.dart';
import 'package:closet_ai/features/ai/application/ai_studio_providers.dart';
import 'package:closet_ai/features/wardrobe/application/wardrobe_state.dart';
import 'package:closet_ai/features/wardrobe/domain/wardrobe_item.dart';
import 'package:closet_ai/widgets/gradient_button.dart';
import 'package:closet_ai/widgets/gradient_card.dart';
import 'package:closet_ai/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const List<String> _readinessCategories = ['top', 'bottom', 'footwear', 'outerwear', 'accessory'];
const List<String> _requiredCategories = ['top', 'bottom', 'footwear'];

String? _mapToReadinessCategory(String category) {
  switch (category.trim().toLowerCase()) {
    case 'top':
    case 'tops':
    case 'dress':
    case 'dresses':
      return 'top';
    case 'bottom':
    case 'bottoms':
      return 'bottom';
    case 'shoe':
    case 'shoes':
    case 'footwear':
      return 'footwear';
    case 'outerwear':
    case 'jacket':
    case 'coat':
      return 'outerwear';
    case 'accessory':
    case 'accessories':
    case 'activewear':
    case 'innerwear':
    case 'other':
      return 'accessory';
    default:
      return null;
  }
}

bool _isAvailable(WardrobeItem item) {
  final status = item.laundryStatus.toLowerCase();
  return status == 'clean' || status == 'ready';
}

String _wardrobeFormCategoryFor(String readinessKey) {
  switch (readinessKey) {
    case 'bottom':
      return 'bottom';
    case 'footwear':
      return 'shoes';
    case 'outerwear':
      return 'outerwear';
    case 'accessory':
      return 'accessory';
    case 'top':
    default:
      return 'top';
  }
}

String _readinessLabel(String key) {
  switch (key) {
    case 'top':
      return 'Top';
    case 'bottom':
      return 'Bottom';
    case 'footwear':
      return 'Footwear';
    case 'outerwear':
      return 'Outerwear';
    case 'accessory':
      return 'Accessories';
    default:
      return key;
  }
}

IconData _readinessIcon(String key) {
  switch (key) {
    case 'top':
      return Icons.checkroom_outlined;
    case 'bottom':
      return Icons.straighten_outlined;
    case 'footwear':
      return Icons.directions_walk_outlined;
    case 'outerwear':
      return Icons.ac_unit_outlined;
    case 'accessory':
      return Icons.watch_outlined;
    default:
      return Icons.checkroom_outlined;
  }
}

class _WardrobeSummary {
  const _WardrobeSummary({
    required this.total,
    required this.clean,
    required this.inLaundry,
    required this.favorites,
    required this.wornToday,
  });

  final int total;
  final int clean;
  final int inLaundry;
  final int favorites;
  final int wornToday;

  factory _WardrobeSummary.fromItems(List<WardrobeItem> items) {
    final now = DateTime.now();
    int clean = 0;
    int favorites = 0;
    int wornToday = 0;

    for (final item in items) {
      if (_isAvailable(item)) clean += 1;
      if (item.favorite) favorites += 1;

      final lastWorn = item.lastWorn;
      if (lastWorn != null && lastWorn.isNotEmpty) {
        final parsed = DateTime.tryParse(lastWorn);
        if (parsed != null && parsed.year == now.year && parsed.month == now.month && parsed.day == now.day) {
          wornToday += 1;
        }
      }
    }

    return _WardrobeSummary(
      total: items.length,
      clean: clean,
      inLaundry: items.length - clean,
      favorites: favorites,
      wornToday: wornToday,
    );
  }
}

class _CategoryReadiness {
  const _CategoryReadiness({required this.key, required this.availableCount, required this.isRequired});

  final String key;
  final int availableCount;
  final bool isRequired;

  bool get isReady => availableCount > 0;
}

class _ReadinessInfo {
  const _ReadinessInfo({required this.categories});

  final List<_CategoryReadiness> categories;

  bool get canGenerate => categories.where((c) => c.isRequired).every((c) => c.isReady);

  factory _ReadinessInfo.fromItems(List<WardrobeItem> items) {
    final counts = <String, int>{for (final key in _readinessCategories) key: 0};
    for (final item in items) {
      if (!_isAvailable(item)) continue;
      final key = _mapToReadinessCategory(item.category);
      if (key != null) counts[key] = (counts[key] ?? 0) + 1;
    }

    return _ReadinessInfo(
      categories: _readinessCategories
          .map(
            (key) => _CategoryReadiness(
              key: key,
              availableCount: counts[key] ?? 0,
              isRequired: _requiredCategories.contains(key),
            ),
          )
          .toList(),
    );
  }
}

class AiHomePage extends ConsumerStatefulWidget {
  const AiHomePage({super.key});

  @override
  ConsumerState<AiHomePage> createState() => _AiHomePageState();
}

class _AiHomePageState extends ConsumerState<AiHomePage> {
  final _scrollController = ScrollController();
  final _generatorKey = GlobalKey();
  final _readinessKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    Future.microtask(_reloadWardrobe);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _reloadWardrobe() {
    return ref.read(wardrobeControllerProvider.notifier).loadItems(refresh: true, force: true, limit: 100);
  }

  Future<void> _openAddCategory(String readinessKey) async {
    final category = _wardrobeFormCategoryFor(readinessKey);
    await context.push('/wardrobe/form', extra: {'category': category});
    if (!mounted) return;
    await _reloadWardrobe();
  }

  void _scrollTo(GlobalKey key) {
    final targetContext = key.currentContext;
    if (targetContext != null) {
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final wardrobeState = ref.watch(wardrobeControllerProvider);
    final aiState = ref.watch(aiStudioControllerProvider);
    final summary = _WardrobeSummary.fromItems(wardrobeState.items);
    final readiness = _ReadinessInfo.fromItems(wardrobeState.items);
    final hasClothes = wardrobeState.items.isNotEmpty;
    final showLoadingSkeleton = wardrobeState.isLoading && wardrobeState.items.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Outfit Studio'),
        actions: [
          IconButton(
            tooltip: 'Outfit History',
            icon: const Icon(Icons.history_rounded),
            onPressed: () => context.push('/ai/saved'),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _reloadWardrobe,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroSection(onCreatePressed: () => _scrollTo(_generatorKey)),
                const SizedBox(height: 12),
                const Align(alignment: Alignment.centerLeft, child: _PremiumUsageBanner()),
                const SizedBox(height: 18),
                if (showLoadingSkeleton)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (!hasClothes)
                  _EmptyWardrobeState(onAddFirstItem: () => _openAddCategory('top'))
                else ...[
                  _WardrobeSummaryCard(summary: summary),
                  const SizedBox(height: 18),
                  Container(
                    key: _readinessKey,
                    child: _ReadinessCard(readiness: readiness, onAddCategory: _openAddCategory),
                  ),
                  const SizedBox(height: 18),
                ],
                Container(
                  key: _generatorKey,
                  child: _GeneratorCard(
                    canGenerate: readiness.canGenerate,
                    onAddMissing: () => _scrollTo(_readinessKey),
                  ),
                ),
                const SizedBox(height: 14),
                const _AiStylistLink(),
                if (aiState.status == AiGenerationStatus.insufficient) ...[
                  const SizedBox(height: 18),
                  _InsufficientCard(
                    message: aiState.errorMessage,
                    onAddMissing: () => _scrollTo(_readinessKey),
                  ),
                ],
                if (aiState.status == AiGenerationStatus.error) ...[
                  const SizedBox(height: 18),
                  _ErrorCard(message: aiState.errorMessage, isPremiumRequired: aiState.isPremiumRequired),
                ],
                if (aiState.status == AiGenerationStatus.success && aiState.result != null) ...[
                  const SizedBox(height: 18),
                  _ResultCard(result: aiState.result!, onWardrobeChanged: _reloadWardrobe),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.onCreatePressed});

  final VoidCallback onCreatePressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GradientCard(
      gradient: AppGradients.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '✨ AI Outfit Studio',
                  style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your personal AI stylist',
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Create outfits from the clothes you already own.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
          ),
          const SizedBox(height: 18),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onCreatePressed,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: AppColors.purple, size: 18),
                    SizedBox(width: 8),
                    Text('Create My Outfit', style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Powered by your wardrobe',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
          ),
        ],
      ),
    );
  }
}

class _PremiumUsageBanner extends ConsumerWidget {
  const _PremiumUsageBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final usageAsync = ref.watch(aiOutfitUsageProvider);

    return usageAsync.when(
      data: (usage) {
        if (usage == null) return const SizedBox.shrink();
        final unlimited = usage.isPremium || usage.remaining == null;
        final text = unlimited
            ? 'Unlimited AI outfit generation'
            : '${usage.remaining} AI outfits remaining this month';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                unlimited ? Icons.workspace_premium_outlined : Icons.bolt_outlined,
                size: 16,
                color: theme.colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 6),
              Text(text, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _WardrobeSummaryCard extends StatelessWidget {
  const _WardrobeSummaryCard({required this.summary});

  final _WardrobeSummary summary;

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatTile(icon: Icons.checkroom_rounded, label: 'Total', value: '${summary.total}'),
      _StatTile(icon: Icons.auto_awesome_rounded, label: 'Ready to Wear', value: '${summary.clean}'),
      _StatTile(icon: Icons.local_laundry_service_rounded, label: 'In Laundry', value: '${summary.inLaundry}'),
      _StatTile(icon: Icons.favorite_rounded, label: 'Favorites', value: '${summary.favorites}'),
      _StatTile(icon: Icons.today_rounded, label: "Worn Today", value: '${summary.wornToday}'),
    ];

    return SectionCard(
      title: 'Your Wardrobe',
      icon: Icons.checkroom_outlined,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth > 600 ? 5 : (constraints.maxWidth > 420 ? 3 : 2);
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
            ),
            itemCount: stats.length,
            itemBuilder: (context, index) => stats[index],
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 20),
          const SizedBox(height: 8),
          Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          Text(label, style: theme.textTheme.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard({required this.readiness, required this.onAddCategory});

  final _ReadinessInfo readiness;
  final ValueChanged<String> onAddCategory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      title: 'Outfit Readiness',
      icon: Icons.fact_check_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Make sure you have enough essentials for complete outfits.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          ...readiness.categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ReadinessTile(category: category, onAdd: () => onAddCategory(category.key)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadinessTile extends StatelessWidget {
  const _ReadinessTile({required this.category, required this.onAdd});

  final _CategoryReadiness category;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ready = category.isReady;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(_readinessIcon(category.key), color: ready ? AppColors.success : theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _readinessLabel(category.key).toUpperCase(),
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      ready ? Icons.check_circle : Icons.warning_amber_rounded,
                      size: 16,
                      color: ready ? AppColors.success : AppColors.orange,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        ready ? '${category.availableCount} available' : 'No suitable items',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!ready)
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: Text('Add ${_readinessLabel(category.key)}'),
            ),
        ],
      ),
    );
  }
}

class _GeneratorCard extends ConsumerWidget {
  const _GeneratorCard({required this.canGenerate, required this.onAddMissing});

  final bool canGenerate;
  final VoidCallback onAddMissing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(aiStudioControllerProvider);
    final controller = ref.read(aiStudioControllerProvider.notifier);
    final options = state.options;
    final isLoading = state.status == AiGenerationStatus.loading;

    return SectionCard(
      title: '✨ Create Your Outfit',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Tell your AI stylist what you're looking for.",
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          _OptionDropdown(
            label: 'Occasion',
            value: options.occasion,
            options: occasionOptions,
            onChanged: (value) => controller.updateOptions((o) => o.copyWith(occasion: value)),
          ),
          const SizedBox(height: 12),
          _OptionDropdown(
            label: 'Weather',
            value: options.weather,
            options: weatherOptions,
            onChanged: (value) => controller.updateOptions((o) => o.copyWith(weather: value)),
          ),
          const SizedBox(height: 12),
          _OptionDropdown(
            label: 'Style',
            value: options.style,
            options: styleOptions,
            onChanged: (value) => controller.updateOptions((o) => o.copyWith(style: value)),
          ),
          const SizedBox(height: 12),
          _OptionDropdown(
            label: 'Color Preference',
            value: options.colorPreference,
            options: colorPreferenceOptions,
            onChanged: (value) => controller.updateOptions((o) => o.copyWith(colorPreference: value)),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Use Favorites only'),
            value: options.favoritesOnly,
            onChanged: (value) => controller.updateOptions((o) => o.copyWith(favoritesOnly: value)),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Avoid Recently Worn'),
            value: options.avoidRecentlyWorn,
            onChanged: (value) => controller.updateOptions((o) => o.copyWith(avoidRecentlyWorn: value)),
          ),
          const SizedBox(height: 8),
          if (!canGenerate)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add at least one top, bottom and footwear to generate a complete outfit.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: onAddMissing,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Missing Items'),
                    ),
                  ],
                ),
              ),
            ),
          GradientButton(
            label: isLoading ? aiLoadingMessages[state.loadingStep] : '✨ Generate Outfit',
            icon: Icons.auto_awesome,
            loading: isLoading,
            onPressed: (!canGenerate || isLoading) ? null : controller.generate,
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                '✨ Your AI stylist is creating an outfit...',
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

class _OptionDropdown extends StatelessWidget {
  const _OptionDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<AiOption> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: const InputDecoration(isDense: true),
          items: options.map((o) => DropdownMenuItem(value: o.value, child: Text(o.label))).toList(),
          onChanged: (newValue) {
            if (newValue != null) onChanged(newValue);
          },
        ),
      ],
    );
  }
}

class _InsufficientCard extends StatelessWidget {
  const _InsufficientCard({required this.message, required this.onAddMissing});

  final String? message;
  final VoidCallback onAddMissing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your wardrobe needs a few more items before we can create a complete outfit.',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message ?? 'Add at least one top, bottom and footwear to generate a complete outfit.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onAddMissing,
              icon: const Icon(Icons.add),
              label: const Text('Add Missing Items'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.isPremiumRequired});

  final String? message;
  final bool isPremiumRequired;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.colorScheme.errorContainer, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message ?? 'AI Stylist is temporarily unavailable. Please try again.',
            style: theme.textTheme.bodyMedium,
          ),
          if (isPremiumRequired) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => context.push('/subscription'),
              icon: const Icon(Icons.workspace_premium_outlined),
              label: const Text('Upgrade to Premium'),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyWardrobeState extends StatelessWidget {
  const _EmptyWardrobeState({required this.onAddFirstItem});

  final VoidCallback onAddFirstItem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_outlined, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text('✨ Build Your Wardrobe', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                'Add a few clothing items and your AI stylist will create outfits for you.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onAddFirstItem,
                icon: const Icon(Icons.add),
                label: const Text('Add Clothing'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiStylistLink extends StatelessWidget {
  const _AiStylistLink();

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => context.go('/ai/stylist'),
      icon: const Icon(Icons.chat_bubble_outline),
      label: const Text('Chat with AI Stylist'),
    );
  }
}

class _ResultCard extends ConsumerWidget {
  const _ResultCard({required this.result, required this.onWardrobeChanged});

  final AiOutfitResult result;
  final Future<void> Function() onWardrobeChanged;

  static const _coreLabels = ['Top', 'Bottom', 'Footwear'];
  static const _optionalLabels = ['Outerwear', 'Accessories', 'Bag', 'Watch'];

  AiOutfitItem? _findItem(String label) {
    final target = label.toLowerCase();
    for (final item in result.items) {
      if (item.category.toLowerCase() == target) return item;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = ref.read(aiStudioControllerProvider.notifier);
    final state = ref.watch(aiStudioControllerProvider);
    final optionalItems = _optionalLabels.map((label) => MapEntry(label, _findItem(label))).where((e) => e.value != null).toList();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 4, decoration: const BoxDecoration(gradient: AppGradients.primary)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('✨ Your AI Look', style: theme.textTheme.titleLarge)),
                    IconButton(
                      tooltip: 'Favorite',
                      onPressed: state.isTogglingFavorite ? null : () => controller.toggleFavorite(),
                      icon: Icon(
                        result.favorite ? Icons.favorite : Icons.favorite_border,
                        color: result.favorite ? AppColors.pink : null,
                      ),
                    ),
                  ],
                ),
                Text(result.outfitName, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text('${result.confidence}% confidence')),
                    Chip(label: Text('Occasion: ${result.occasion}')),
                    Chip(label: Text('Weather: ${result.weather}')),
                    if (result.style.isNotEmpty && result.style != 'ai') Chip(label: Text('Style: ${result.style}')),
                  ],
                ),
                const SizedBox(height: 16),
                for (final label in _coreLabels) ...[
                  _OutfitPieceTile(label: label, item: _findItem(label)),
                  if (label != _coreLabels.last)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Icon(Icons.arrow_downward_rounded, size: 16),
                    ),
                ],
                if (optionalItems.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Also with', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final entry in optionalItems) _OutfitPieceChip(label: entry.key, item: entry.value!),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Text('Why this works', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(result.reason.isEmpty ? '—' : result.reason, style: theme.textTheme.bodyMedium),
                if (result.suggestions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Styling tips', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  ...result.suggestions.map(
                    (tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [const Text('• '), Expanded(child: Text(tip))],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: state.isSaving ? null : () => _handleSave(context, controller),
                      icon: const Icon(Icons.favorite_border),
                      label: const Text('❤️ Save Outfit'),
                    ),
                    OutlinedButton.icon(
                      onPressed: state.isWearing ? null : () => _handleWear(context, controller),
                      icon: const Icon(Icons.checkroom),
                      label: const Text('👕 Wear This Outfit'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _handleAddToCalendar(context, controller),
                      icon: const Icon(Icons.event_available_outlined),
                      label: const Text('📅 Add to Calendar'),
                    ),
                    OutlinedButton.icon(
                      onPressed: state.status == AiGenerationStatus.loading ? null : controller.tryAnother,
                      icon: const Icon(Icons.refresh),
                      label: const Text('🔄 Try Another'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave(BuildContext context, AiStudioController controller) async {
    final messenger = ScaffoldMessenger.of(context);
    final id = await controller.save();
    messenger.showSnackBar(
      SnackBar(content: Text(id != null ? 'Outfit saved to your collection.' : 'Saving failed. Please try again.')),
    );
  }

  Future<void> _handleWear(BuildContext context, AiStudioController controller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Wear this outfit today?'),
        content: const Text('This marks the outfit and its items as worn today.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Wear it')),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final success = await controller.wear();
    if (success) {
      await onWardrobeChanged();
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(success ? 'Outfit marked as worn.' : 'Unable to mark outfit as worn. Please try again.'),
      ),
    );
  }

  Future<void> _handleAddToCalendar(BuildContext context, AiStudioController controller) async {
    final messenger = ScaffoldMessenger.of(context);
    final id = await controller.save();
    if (id == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please try saving the outfit again before scheduling it.')),
      );
      return;
    }
    if (!context.mounted) return;
    context.push('/calendar/schedule', extra: {'outfitId': id, 'occasion': result.occasion});
  }
}

class _OutfitPieceTile extends StatelessWidget {
  const _OutfitPieceTile({required this.label, required this.item});

  final String label;
  final AiOutfitItem? item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final piece = item;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: piece != null && piece.imageUrl.isNotEmpty
                ? Image.network(
                    piece.imageUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 56,
                      height: 56,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.checkroom),
                    ),
                  )
                : Container(
                    width: 56,
                    height: 56,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.checkroom),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(piece?.name ?? 'No $label selected', style: theme.textTheme.titleSmall),
                if (piece != null && piece.color.isNotEmpty) Text(piece.color, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OutfitPieceChip extends StatelessWidget {
  const _OutfitPieceChip({required this.label, required this.item});

  final String label;
  final AiOutfitItem item;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: item.imageUrl.isNotEmpty
          ? CircleAvatar(backgroundImage: NetworkImage(item.imageUrl))
          : const CircleAvatar(child: Icon(Icons.checkroom, size: 14)),
      label: Text('$label: ${item.name}'),
    );
  }
}
