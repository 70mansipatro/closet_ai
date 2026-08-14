/// Typed models for the AI Stylist chat feature, replacing raw
/// `Map<String, dynamic>` access so a malformed/missing backend field is
/// caught by a default value instead of silently rendering as empty text.
library;

class ChatConversationSummary {
  const ChatConversationSummary({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.lastMessageAt,
  });

  final String id;
  final String title;
  final String lastMessage;
  final DateTime? lastMessageAt;

  factory ChatConversationSummary.fromJson(Map<String, dynamic> json) {
    return ChatConversationSummary(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Conversation',
      lastMessage: json['lastMessage']?.toString() ?? '',
      lastMessageAt: DateTime.tryParse(
        json['lastMessageAt']?.toString() ?? '',
      ),
    );
  }
}

class StylistActions {
  const StylistActions({
    this.canSave = false,
    this.canSchedule = false,
    this.canWear = false,
  });

  final bool canSave;
  final bool canSchedule;
  final bool canWear;

  factory StylistActions.fromJson(dynamic json) {
    if (json is! Map) return const StylistActions();
    return StylistActions(
      canSave: json['canSave'] == true,
      canSchedule: json['canSchedule'] == true,
      canWear: json['canWear'] == true,
    );
  }
}

/// A single outfit suggestion from the stylist. [clothingIds] are the only
/// source of truth for which wardrobe items belong to this outfit — the UI
/// must resolve them against the user's real wardrobe and never invent items.
class StylistRecommendation {
  const StylistRecommendation({
    required this.title,
    required this.clothingIds,
    required this.occasion,
    required this.style,
    required this.weather,
    required this.temperature,
    required this.reason,
    required this.rating,
  });

  final String title;
  final List<String> clothingIds;
  final String occasion;
  final String style;
  final String weather;
  final num? temperature;
  final String reason;
  final num rating;

  factory StylistRecommendation.fromJson(Map<String, dynamic> json) {
    final rawIds = json['clothingIds'];
    return StylistRecommendation(
      title: json['title']?.toString() ?? 'Outfit idea',
      clothingIds: rawIds is List
          ? rawIds.map((id) => id.toString()).toList()
          : const [],
      occasion: json['occasion']?.toString() ?? '',
      style: json['style']?.toString() ?? '',
      weather: json['weather']?.toString() ?? '',
      temperature: json['temperature'] as num?,
      reason: json['reason']?.toString() ?? '',
      rating: (json['rating'] as num?) ?? 0,
    );
  }
}

class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.recommendations = const [],
    this.alternatives = const [],
    this.missingItems = const [],
    this.actions = const StylistActions(),
    this.isFallback = false,
  });

  final String id;
  final String role;
  final String content;
  final DateTime? createdAt;
  final List<StylistRecommendation> recommendations;
  final List<StylistRecommendation> alternatives;
  final List<String> missingItems;
  final StylistActions actions;
  final bool isFallback;

  bool get isUser => role == 'user';

  static List<StylistRecommendation> _parseRecommendations(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map(
          (item) =>
              StylistRecommendation.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'] is Map
        ? Map<String, dynamic>.from(json['metadata'] as Map)
        : const <String, dynamic>{};
    final rawMissingItems = metadata['missingItems'];
    return ChatMessageModel(
      id: json['_id']?.toString() ?? '',
      role: json['role']?.toString() ?? 'assistant',
      content: json['content']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      recommendations: _parseRecommendations(metadata['recommendations']),
      alternatives: _parseRecommendations(metadata['alternatives']),
      missingItems: rawMissingItems is List
          ? rawMissingItems.map((item) => item.toString()).toList()
          : const [],
      actions: StylistActions.fromJson(metadata['actions']),
      isFallback: metadata['isFallback'] == true,
    );
  }
}
