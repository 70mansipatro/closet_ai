class PaginatedResult<T> {
  const PaginatedResult({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory PaginatedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) {
    final rawItems = json['items'] as List? ?? const <dynamic>[];
    return PaginatedResult<T>(
      items: rawItems
          .map((item) => itemFromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      total: (json['total'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }

  static PaginatedResult<T> empty<T>() => PaginatedResult<T>(
    items: const [],
    page: 1,
    limit: 20,
    total: 0,
    totalPages: 1,
  );

  final List<T> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasNextPage => page < totalPages;
  bool get hasPreviousPage => page > 1;
}
