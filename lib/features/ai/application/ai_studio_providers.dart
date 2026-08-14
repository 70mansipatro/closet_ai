import 'dart:async';

import 'package:closet_ai/core/services/api_client.dart';
import 'package:closet_ai/features/ai/data/outfit_repository.dart';
import 'package:closet_ai/features/dashboard/application/dashboard_providers.dart';
import 'package:closet_ai/features/subscription/providers/subscription_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A dropdown/chip option pairing a user-facing [label] with the lowercase
/// [value] the backend expects.
class AiOption {
  const AiOption(this.label, this.value);

  final String label;
  final String value;
}

const List<AiOption> occasionOptions = [
  AiOption('Casual', 'casual'),
  AiOption('Office', 'office'),
  AiOption('Party', 'party'),
  AiOption('Date', 'date'),
  AiOption('Travel', 'travel'),
  AiOption('Wedding', 'wedding'),
  AiOption('Workout', 'workout'),
  AiOption('Formal', 'formal'),
  AiOption('Daily Wear', 'daily wear'),
];

const List<AiOption> weatherOptions = [
  AiOption('Auto Detect', 'auto'),
  AiOption('Hot', 'hot'),
  AiOption('Warm', 'warm'),
  AiOption('Mild', 'mild'),
  AiOption('Cool', 'cool'),
  AiOption('Cold', 'cold'),
  AiOption('Rainy', 'rainy'),
];

const List<AiOption> styleOptions = [
  AiOption('AI Pick', 'ai'),
  AiOption('Casual', 'casual'),
  AiOption('Elegant', 'elegant'),
  AiOption('Minimal', 'minimal'),
  AiOption('Streetwear', 'streetwear'),
  AiOption('Sporty', 'sporty'),
  AiOption('Formal', 'formal'),
  AiOption('Traditional', 'traditional'),
];

const List<AiOption> colorPreferenceOptions = [
  AiOption('AI Pick', 'ai'),
  AiOption('Neutral', 'neutral'),
  AiOption('Bright', 'bright'),
  AiOption('Dark', 'dark'),
  AiOption('Pastel', 'pastel'),
  AiOption('Any', 'any'),
];

const List<String> aiLoadingMessages = [
  'Checking your wardrobe...',
  'Matching colors...',
  'Considering the occasion...',
  'Creating your look...',
];

enum AiGenerationStatus { idle, loading, success, insufficient, error }

class AiGeneratorOptions {
  const AiGeneratorOptions({
    this.occasion = 'casual',
    this.weather = 'auto',
    this.style = 'ai',
    this.colorPreference = 'any',
    this.favoritesOnly = false,
    this.avoidRecentlyWorn = false,
  });

  final String occasion;
  final String weather;
  final String style;
  final String colorPreference;
  final bool favoritesOnly;
  final bool avoidRecentlyWorn;

  AiGeneratorOptions copyWith({
    String? occasion,
    String? weather,
    String? style,
    String? colorPreference,
    bool? favoritesOnly,
    bool? avoidRecentlyWorn,
  }) {
    return AiGeneratorOptions(
      occasion: occasion ?? this.occasion,
      weather: weather ?? this.weather,
      style: style ?? this.style,
      colorPreference: colorPreference ?? this.colorPreference,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      avoidRecentlyWorn: avoidRecentlyWorn ?? this.avoidRecentlyWorn,
    );
  }
}

class AiOutfitItem {
  const AiOutfitItem({
    required this.id,
    required this.name,
    required this.category,
    this.color = '',
    this.favorite = false,
    this.lastWorn,
    this.imageUrl = '',
  });

  final String id;
  final String name;
  final String category;
  final String color;
  final bool favorite;
  final String? lastWorn;
  final String imageUrl;

  factory AiOutfitItem.fromJson(Map<String, dynamic> json) {
    return AiOutfitItem(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      color: json['color']?.toString() ?? '',
      favorite: json['favorite'] == true,
      lastWorn: json['lastWorn']?.toString(),
      imageUrl: json['imageUrl']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toRecommendedItemJson() => {
    '_id': id,
    'name': name,
    'category': category,
  };
}

/// A generated (and possibly since-saved/favorited) outfit recommendation.
class AiOutfitResult {
  const AiOutfitResult({
    required this.outfitName,
    required this.occasion,
    required this.weather,
    required this.style,
    required this.colorPreference,
    required this.top,
    required this.bottom,
    required this.footwear,
    required this.outerwear,
    required this.accessories,
    required this.bag,
    required this.watch,
    required this.confidence,
    required this.reason,
    required this.items,
    required this.suggestions,
    this.outfitId,
    this.favorite = false,
  });

  final String outfitName;
  final String occasion;
  final String weather;
  final String style;
  final String colorPreference;
  final String? top;
  final String? bottom;
  final String? footwear;
  final String? outerwear;
  final String? accessories;
  final String? bag;
  final String? watch;
  final num confidence;
  final String reason;
  final List<AiOutfitItem> items;
  final List<String> suggestions;
  final String? outfitId;
  final bool favorite;

  static String? _str(dynamic value) {
    final text = value?.toString();
    return (text == null || text.isEmpty) ? null : text;
  }

  factory AiOutfitResult.fromJson(Map<String, dynamic> json) {
    final rawItems = json['recommendedItems'];
    return AiOutfitResult(
      outfitName: json['outfitName']?.toString() ?? 'Your AI Look',
      occasion: json['occasion']?.toString() ?? 'casual',
      weather: json['weather']?.toString() ?? 'auto',
      style: json['style']?.toString() ?? '',
      colorPreference: json['colorPreference']?.toString() ?? 'any',
      top: _str(json['top']),
      bottom: _str(json['bottom']),
      footwear: _str(json['footwear']),
      outerwear: _str(json['outerwear']),
      accessories: _str(json['accessories']),
      bag: _str(json['bag']),
      watch: _str(json['watch']),
      confidence: (json['confidence'] as num?) ?? 0,
      reason: json['reason']?.toString() ?? '',
      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map((item) => AiOutfitItem.fromJson(Map<String, dynamic>.from(item)))
                .toList()
          : const [],
      suggestions: json['suggestions'] is List
          ? (json['suggestions'] as List).map((s) => s.toString()).toList()
          : const [],
    );
  }

  AiOutfitResult copyWith({String? outfitId, bool? favorite}) {
    return AiOutfitResult(
      outfitName: outfitName,
      occasion: occasion,
      weather: weather,
      style: style,
      colorPreference: colorPreference,
      top: top,
      bottom: bottom,
      footwear: footwear,
      outerwear: outerwear,
      accessories: accessories,
      bag: bag,
      watch: watch,
      confidence: confidence,
      reason: reason,
      items: items,
      suggestions: suggestions,
      outfitId: outfitId ?? this.outfitId,
      favorite: favorite ?? this.favorite,
    );
  }

  Map<String, dynamic> toSavePayload() => {
    'occasion': occasion,
    'weather': weather,
    'style': style,
    'colorPreference': colorPreference,
    'top': top ?? '',
    'bottom': bottom ?? '',
    'footwear': footwear ?? '',
    'outerwear': outerwear ?? '',
    'accessories': accessories ?? '',
    'bag': bag ?? '',
    'watch': watch ?? '',
    'confidenceScore': confidence,
    'reason': reason,
    'outfitName': outfitName,
    'suggestions': suggestions,
    'aiGenerated': true,
    'recommendedItems': items.map((item) => item.toRecommendedItemJson()).toList(),
  };
}

class AiStudioState {
  const AiStudioState({
    this.options = const AiGeneratorOptions(),
    this.status = AiGenerationStatus.idle,
    this.loadingStep = 0,
    this.result,
    this.errorMessage,
    this.isPremiumRequired = false,
    this.isSaving = false,
    this.isWearing = false,
    this.isTogglingFavorite = false,
  });

  final AiGeneratorOptions options;
  final AiGenerationStatus status;
  final int loadingStep;
  final AiOutfitResult? result;
  final String? errorMessage;
  final bool isPremiumRequired;
  final bool isSaving;
  final bool isWearing;
  final bool isTogglingFavorite;

  AiStudioState copyWith({
    AiGeneratorOptions? options,
    AiGenerationStatus? status,
    int? loadingStep,
    AiOutfitResult? result,
    bool clearResult = false,
    String? errorMessage,
    bool clearError = false,
    bool? isPremiumRequired,
    bool? isSaving,
    bool? isWearing,
    bool? isTogglingFavorite,
  }) {
    return AiStudioState(
      options: options ?? this.options,
      status: status ?? this.status,
      loadingStep: loadingStep ?? this.loadingStep,
      result: clearResult ? null : (result ?? this.result),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isPremiumRequired: isPremiumRequired ?? this.isPremiumRequired,
      isSaving: isSaving ?? this.isSaving,
      isWearing: isWearing ?? this.isWearing,
      isTogglingFavorite: isTogglingFavorite ?? this.isTogglingFavorite,
    );
  }
}

bool _isPremiumRequiredError(DioException error) {
  final data = error.response?.data;
  if (data is Map) {
    final details = data['details'];
    if (details is Map && details['code'] == 'PREMIUM_REQUIRED') return true;
  }
  return error.response?.statusCode == 403;
}

class AiStudioController extends StateNotifier<AiStudioState> {
  AiStudioController(this._repository) : super(const AiStudioState());

  final OutfitRepository _repository;
  Timer? _loadingTimer;

  void updateOptions(AiGeneratorOptions Function(AiGeneratorOptions current) update) {
    state = state.copyWith(options: update(state.options));
  }

  Future<void> generate() async {
    if (state.status == AiGenerationStatus.loading) return;

    _loadingTimer?.cancel();
    state = state.copyWith(
      status: AiGenerationStatus.loading,
      loadingStep: 0,
      clearResult: true,
      clearError: true,
      isPremiumRequired: false,
    );
    _loadingTimer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      state = state.copyWith(loadingStep: (state.loadingStep + 1) % aiLoadingMessages.length);
    });

    try {
      final response = await _repository.generateOutfit(
        occasion: state.options.occasion,
        weather: state.options.weather,
        style: state.options.style,
        colorPreference: state.options.colorPreference,
        favoritesOnly: state.options.favoritesOnly,
        avoidRecentlyWorn: state.options.avoidRecentlyWorn,
      );

      if (response['success'] == false) {
        state = state.copyWith(
          status: AiGenerationStatus.insufficient,
          errorMessage:
              response['reason']?.toString() ??
              'Add at least one top, bottom and footwear to generate a complete outfit.',
        );
        return;
      }

      final data = response['data'];
      if (data is Map) {
        final result = AiOutfitResult.fromJson(Map<String, dynamic>.from(data));
        state = state.copyWith(status: AiGenerationStatus.success, result: result);
      } else {
        state = state.copyWith(
          status: AiGenerationStatus.error,
          errorMessage: 'AI Stylist is temporarily unavailable. Please try again.',
        );
      }
    } on DioException catch (error) {
      final premiumRequired = _isPremiumRequiredError(error);
      state = state.copyWith(
        status: AiGenerationStatus.error,
        isPremiumRequired: premiumRequired,
        errorMessage: premiumRequired
            ? 'You have used all your free AI outfits this month. Upgrade to Premium for unlimited generations.'
            : ApiClient.extractErrorMessage(error),
      );
    } catch (_) {
      state = state.copyWith(
        status: AiGenerationStatus.error,
        errorMessage: 'AI Stylist is temporarily unavailable. Please try again.',
      );
    } finally {
      _loadingTimer?.cancel();
    }
  }

  void tryAnother() => generate();

  void reset() {
    _loadingTimer?.cancel();
    state = AiStudioState(options: state.options);
  }

  Future<String?> save() async {
    final result = state.result;
    if (result == null) return null;
    if (result.outfitId != null) return result.outfitId;

    state = state.copyWith(isSaving: true);
    try {
      final response = await _repository.saveOutfit(result.toSavePayload());
      final data = response['data'];
      final id = (data is Map ? data['_id'] : null)?.toString();
      if (id != null) {
        state = state.copyWith(result: result.copyWith(outfitId: id));
      }
      return id;
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }

  Future<bool> wear() async {
    final outfitId = await save();
    if (outfitId == null) return false;

    state = state.copyWith(isWearing: true);
    try {
      await _repository.wearOutfit(outfitId);
      return true;
    } finally {
      state = state.copyWith(isWearing: false);
    }
  }

  Future<bool> toggleFavorite() async {
    final result = state.result;
    if (result == null) return false;
    final outfitId = await save();
    if (outfitId == null) return false;

    state = state.copyWith(isTogglingFavorite: true);
    try {
      final nextFavorite = !result.favorite;
      await _repository.toggleFavorite(outfitId, favorite: nextFavorite);
      state = state.copyWith(result: state.result?.copyWith(favorite: nextFavorite));
      return true;
    } finally {
      state = state.copyWith(isTogglingFavorite: false);
    }
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }
}

final aiStudioControllerProvider = StateNotifierProvider<AiStudioController, AiStudioState>((ref) {
  return AiStudioController(ref.read(outfitRepositoryProvider));
});

class AiOutfitUsage {
  const AiOutfitUsage({
    required this.count,
    required this.limit,
    required this.remaining,
    required this.isPremium,
  });

  final int count;
  final int? limit;
  final int? remaining;
  final bool isPremium;

  factory AiOutfitUsage.fromJson(Map<String, dynamic> json) {
    return AiOutfitUsage(
      count: (json['count'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt(),
      remaining: (json['remaining'] as num?)?.toInt(),
      isPremium: json['isPremium'] == true,
    );
  }
}

/// Fetches the user's real AI-outfit usage this billing period so the studio
/// can show "X remaining this month" / "Unlimited" using actual data.
final aiOutfitUsageProvider = FutureProvider.autoDispose<AiOutfitUsage?>((ref) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get('/subscriptions/me');
  final data = response['data'];
  if (data is Map && data['aiOutfitUsage'] is Map) {
    return AiOutfitUsage.fromJson(Map<String, dynamic>.from(data['aiOutfitUsage'] as Map));
  }
  return null;
});
