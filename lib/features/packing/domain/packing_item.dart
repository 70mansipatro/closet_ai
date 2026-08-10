class PackingItem {
  PackingItem({
    required this.id,
    required this.category,
    required this.name,
    required this.clothingId,
    required this.quantity,
    required this.packed,
    required this.required,
    required this.reason,
  });

  final String id;
  final String category;
  final String name;
  final String? clothingId;
  final int quantity;
  final bool packed;
  final bool required;
  final String reason;

  factory PackingItem.fromJson(Map<String, dynamic> json) {
    return PackingItem(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      category: json['category'] as String? ?? 'Other',
      name: json['name'] as String? ?? '',
      clothingId: json['clothingId'] as String?,
      quantity: json['quantity'] is int
          ? json['quantity'] as int
          : int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      packed: json['packed'] == true,
      required: json['required'] == true,
      reason: json['reason'] as String? ?? '',
    );
  }
}
