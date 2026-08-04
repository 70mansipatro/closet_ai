class WardrobeItem {
  const WardrobeItem({
    required this.id,
    required this.imageUrl,
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
  });

  final String id;
  final String imageUrl;
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

  factory WardrobeItem.fromJson(Map<String, dynamic> json) {
    return WardrobeItem(
      id: json['_id']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'imageUrl': imageUrl,
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
    };
  }
}
