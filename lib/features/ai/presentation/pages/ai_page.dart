import 'package:closet_ai/core/services/api_client.dart';
import 'package:closet_ai/core/theme/app_gradients.dart';
import 'package:closet_ai/features/ai/data/outfit_repository.dart';
import 'package:closet_ai/widgets/gradient_button.dart';
import 'package:flutter/material.dart';

class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  final _repository = OutfitRepository(ApiClient());
  String _occasion = 'casual';
  String _weather = 'sunny';
  String _season = 'summer';
  int _temperature = 24;
  bool _isLoading = false;
  bool _hasGenerated = false;
  Map<String, dynamic>? _recommendation;
  String? _error;
  String? _savedOutfitId;

  final List<String> _occasions = [
    'Office',
    'College',
    'Party',
    'Wedding',
    'Travel',
    'Gym',
    'Casual',
  ];
  final List<String> _weatherOptions = [
    'Sunny',
    'Cloudy',
    'Rainy',
    'Cold',
    'Hot',
  ];
  final List<String> _seasons = [
    'Spring',
    'Summer',
    'Autumn',
    'Winter',
    'All-season',
  ];

  Future<void> _generateOutfit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _repository.generateOutfit(
        occasion: _occasion.toLowerCase(),
        weather: _weather.toLowerCase(),
        temperature: _temperature,
        season: _season.toLowerCase(),
      );

      final data = response['data'];
      if (data is Map<String, dynamic>) {
        setState(() {
          _recommendation = data;
          _hasGenerated = true;
        });
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      setState(() {
        _error = 'We could not generate an outfit right now. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveOutfit() async {
    if (_recommendation == null) return;
    try {
      final response = await _repository.saveOutfit({
        'occasion': _occasion.toLowerCase(),
        'weather': _weather.toLowerCase(),
        'temperature': _temperature,
        'season': _season.toLowerCase(),
        'top': _recommendation!['top'],
        'bottom': _recommendation!['bottom'],
        'footwear': _recommendation!['footwear'],
        'outerwear': _recommendation!['outerwear'],
        'accessories': _recommendation!['accessories'],
        'bag': _recommendation!['bag'],
        'watch': _recommendation!['watch'],
        'confidenceScore': _recommendation!['confidence'],
        'reason': _recommendation!['reason'],
        'recommendedItems': _recommendation!['recommendedItems'],
      });

      final data = response['data'];
      if (data is Map && data['_id'] != null) {
        _savedOutfitId = data['_id'].toString();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Outfit saved to your collection.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saving failed. Please try again.')),
      );
    }
  }

  Future<void> _wearToday() async {
    if (_savedOutfitId == null) {
      await _saveOutfit();
    }
    if (_savedOutfitId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please save the outfit before marking it as worn.'),
        ),
      );
      return;
    }

    try {
      await _repository.wearOutfit(_savedOutfitId!);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Outfit marked as worn.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to mark outfit as worn. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('AI Outfit Studio')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Design an outfit from your wardrobe',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Pick the moment, weather, and season to receive a tailored recommendation.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionCard(
                title: 'Occasion',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _occasions.map((option) {
                    final selected =
                        _occasion.toLowerCase() == option.toLowerCase();
                    return ChoiceChip(
                      label: Text(option),
                      selected: selected,
                      onSelected: (_) => setState(() => _occasion = option),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              _buildSectionCard(
                title: 'Weather',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _weatherOptions.map((option) {
                    final selected =
                        _weather.toLowerCase() == option.toLowerCase();
                    return ChoiceChip(
                      label: Text(option),
                      selected: selected,
                      onSelected: (_) => setState(() => _weather = option),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              _buildSectionCard(
                title: 'Season',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _seasons.map((option) {
                    final selected =
                        _season.toLowerCase() == option.toLowerCase();
                    return ChoiceChip(
                      label: Text(option),
                      selected: selected,
                      onSelected: (_) => setState(() => _season = option),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              _buildSectionCard(
                title: 'Temperature',
                child: Slider(
                  min: 0,
                  max: 40,
                  divisions: 40,
                  label: '$_temperature°C',
                  value: _temperature.toDouble(),
                  onChanged: (value) =>
                      setState(() => _temperature = value.round()),
                ),
              ),
              const SizedBox(height: 16),
              GradientButton(
                label: _isLoading ? 'Generating...' : 'Generate Outfit',
                icon: Icons.auto_awesome,
                loading: _isLoading,
                onPressed: _isLoading ? null : _generateOutfit,
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(_error!, style: theme.textTheme.bodyMedium),
                ),
              if (_hasGenerated && _recommendation != null) ...[
                const SizedBox(height: 8),
                _buildResultCard(theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(ThemeData theme) {
    final recommendation = _recommendation!;
    final recommendedItems = (recommendation['recommendedItems'] is List)
        ? (recommendation['recommendedItems'] as List)
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : <Map<String, dynamic>>[];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thin gradient accent strip signals this is an AI-generated pick,
          // while keeping the card content itself clean and readable.
          Container(height: 4, decoration: const BoxDecoration(
            gradient: AppGradients.primary,
          )),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Recommended Outfit',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    const _AiPickBadge(),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(
                        '${recommendation['confidence'] ?? 0}% confidence',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  Icons.checkroom_outlined,
                  'Top',
                  recommendation['top'] ?? '—',
                ),
                _buildDetailRow(
                  Icons.trending_up_outlined,
                  'Bottom',
                  recommendation['bottom'] ?? '—',
                ),
                _buildDetailRow(
                  Icons.directions_walk_outlined,
                  'Footwear',
                  recommendation['footwear'] ?? '—',
                ),
                _buildDetailRow(
                  Icons.style_outlined,
                  'Outerwear',
                  recommendation['outerwear'] ?? '—',
                ),
                _buildDetailRow(
                  Icons.accessibility_new_outlined,
                  'Accessories',
                  recommendation['accessories'] ?? '—',
                ),
                _buildDetailRow(
                  Icons.shopping_bag_outlined,
                  'Bag',
                  recommendation['bag'] ?? '—',
                ),
                _buildDetailRow(
                  Icons.watch_outlined,
                  'Watch',
                  recommendation['watch'] ?? '—',
                ),
                const SizedBox(height: 12),
                Text('Why it fits', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  recommendation['reason'] ?? '—',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Text('Recommended Items', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                if (recommendedItems.isEmpty)
                  const Text('No recommended wardrobe items available.')
                else
                  ...recommendedItems.map(
                    (item) => _buildRecommendedItemTile(item, theme),
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _generateOutfit,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Generate Again'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _saveOutfit,
                      icon: const Icon(Icons.favorite_border),
                      label: const Text('Save Outfit'),
                    ),
                    FilledButton.icon(
                      onPressed: _wearToday,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Wear This Outfit'),
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

  Widget _buildRecommendedItemTile(Map<String, dynamic> item, ThemeData theme) {
    final imageUrl = item['imageUrl'];
    final color = item['color'] ?? 'Unknown';
    final lastWorn = item['lastWorn'];
    final favorite = item['favorite'] == true;
    final name = item['name'] ?? 'Unnamed item';
    final category = item['category'] ?? 'Accessory';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl != null && imageUrl.toString().isNotEmpty
                  ? Image.network(
                      imageUrl.toString(),
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 64,
                        height: 64,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.checkroom),
                      ),
                    )
                  : Container(
                      width: 64,
                      height: 64,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.checkroom),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(name, style: theme.textTheme.titleSmall),
                      ),
                      if (favorite)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Favorite',
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Color: $color', style: theme.textTheme.bodyMedium),
                  Text(
                    'Category: $category',
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (lastWorn != null && lastWorn.toString().isNotEmpty)
                    Text(
                      'Last worn: ${DateTime.tryParse(lastWorn.toString())?.toLocal().toString().split(' ').first ?? lastWorn}',
                      style: theme.textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

/// Small gradient badge marking a recommendation as an AI pick, used
/// alongside the confidence chip on the (otherwise clean/readable) result
/// card.
class _AiPickBadge extends StatelessWidget {
  const _AiPickBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: AppGradients.blueViolet,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 12, color: Colors.white),
          SizedBox(width: 4),
          Text(
            'AI Pick',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
