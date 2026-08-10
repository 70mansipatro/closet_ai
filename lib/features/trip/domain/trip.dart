class Trip {
  Trip({
    required this.id,
    required this.tripName,
    required this.destination,
    required this.country,
    required this.city,
    required this.startDate,
    required this.endDate,
    required this.activities,
    required this.notes,
  });

  final String id;
  final String tripName;
  final String destination;
  final String country;
  final String city;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> activities;
  final String notes;

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      tripName: json['tripName'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      country: json['country'] as String? ?? '',
      city: json['city'] as String? ?? '',
      startDate:
          DateTime.tryParse(json['startDate'] as String? ?? '') ??
          DateTime.now(),
      endDate:
          DateTime.tryParse(json['endDate'] as String? ?? '') ?? DateTime.now(),
      activities:
          (json['activities'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          [],
      notes: json['notes'] as String? ?? '',
    );
  }
}
