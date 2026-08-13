class WardrobeItem {
  const WardrobeItem({
    required this.id,
    required this.imageUrl,
    required this.name,
    required this.category,
    required this.subCategory,
    required this.color,
    required this.season,
    required this.favorite,
    required this.laundryStatus,
    required this.wearCount,
    required this.lastWorn,
    required this.brand,
    required this.size,
    required this.occasion,
    required this.purchasePrice,
    required this.notes,
    this.pattern = '',
    this.material = '',
    this.style = '',
    this.fit = '',
    this.secondaryColors = const [],
    this.occasions = const [],
    this.weatherSuitability = const [],
    this.purchaseDate,
    this.aiAnalyzed = false,
    this.aiConfidence = const {},
  });

  final String id;
  final String imageUrl;
  final String name;
  final String category;
  final String subCategory;
  final String color;
  final String season;
  final bool favorite;
  final String laundryStatus;
  final int wearCount;
  final String? lastWorn;
  final String brand;
  final String size;
  final String occasion;
  final double purchasePrice;
  final String notes;

  final String pattern;
  final String material;
  final String style;
  final String fit;
  final List<String> secondaryColors;
  final List<String> occasions;
  final List<String> weatherSuitability;
  final String? purchaseDate;
  final bool aiAnalyzed;
  final Map<String, num?> aiConfidence;

  /// Best available display label: an explicit name, else a composed
  /// "Brand Color Category" fallback, else just the category.
  String get displayName {
    if (name.isNotEmpty) return name;
    final composed = [
      brand,
      color,
      subCategory.isNotEmpty ? subCategory : category,
    ].where((part) => part.trim().isNotEmpty).join(' ');
    return composed.isEmpty ? category : composed;
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).where((item) => item.isNotEmpty).toList();
    }
    if (value is String && value.isNotEmpty) {
      return [value];
    }
    return const [];
  }

  static Map<String, num?> _confidenceMap(dynamic value) {
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), num.tryParse(val?.toString() ?? '')));
    }
    return const {};
  }

  factory WardrobeItem.fromJson(Map<String, dynamic> json) {
    final aiAnalysis = json['aiAnalysis'] as Map<String, dynamic>?;
    return WardrobeItem(
      id: json['_id']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'other',
      color: json['color']?.toString() ?? '',
      season: json['season']?.toString() ?? 'all-season',
      favorite: json['favorite'] == true,
      laundryStatus: json['laundryStatus']?.toString() ?? 'clean',
      wearCount: int.tryParse(json['wearCount']?.toString() ?? '0') ?? 0,
      lastWorn: json['lastWorn']?.toString(),
      brand: json['brand']?.toString() ?? '',
      size: json['size']?.toString() ?? '',
      occasion: json['occasion']?.toString() ?? 'casual',
      purchasePrice:
          double.tryParse(json['purchasePrice']?.toString() ?? '0') ?? 0.0,
      subCategory: json['subCategory']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      pattern: json['pattern']?.toString() ?? '',
      material: json['material']?.toString() ?? '',
      style: json['style']?.toString() ?? '',
      fit: json['fit']?.toString() ?? '',
      secondaryColors: _stringList(json['secondaryColors']),
      occasions: _stringList(json['occasions']),
      weatherSuitability: _stringList(json['weatherSuitability']),
      purchaseDate: json['purchaseDate']?.toString(),
      aiAnalyzed: aiAnalysis?['analyzed'] == true,
      aiConfidence: _confidenceMap(aiAnalysis?['confidence']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'imageUrl': imageUrl,
      'name': name,
      'category': category,
      'color': color,
      'season': season,
      'favorite': favorite,
      'laundryStatus': laundryStatus,
      'wearCount': wearCount,
      'lastWorn': lastWorn,
      'brand': brand,
      'size': size,
      'occasion': occasion,
      'subCategory': subCategory,
      'purchasePrice': purchasePrice,
      'notes': notes,
      'pattern': pattern,
      'material': material,
      'style': style,
      'fit': fit,
      'secondaryColors': secondaryColors,
      'occasions': occasions,
      'weatherSuitability': weatherSuitability,
      'purchaseDate': purchaseDate,
    };
  }
}
