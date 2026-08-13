class WearHistoryEntry {
  const WearHistoryEntry({
    required this.id,
    required this.date,
    required this.occasion,
    required this.weather,
    required this.rating,
    required this.notes,
  });

  final String id;
  final DateTime? date;
  final String occasion;
  final String weather;
  final int? rating;
  final String notes;

  factory WearHistoryEntry.fromJson(Map<String, dynamic> json) {
    return WearHistoryEntry(
      id: json['_id']?.toString() ?? '',
      date: DateTime.tryParse(json['date']?.toString() ?? ''),
      occasion: json['occasion']?.toString() ?? '',
      weather: json['weather']?.toString() ?? '',
      rating: json['rating'] == null
          ? null
          : int.tryParse(json['rating'].toString()),
      notes: json['notes']?.toString() ?? '',
    );
  }
}
