class SweetnessLevel {
  final int id;
  final String name;
  final int percentage;
  final DateTime createdAt;

  SweetnessLevel({
    required this.id,
    required this.name,
    required this.percentage,
    required this.createdAt,
  });

  factory SweetnessLevel.fromJson(Map<String, dynamic> json) {
    return SweetnessLevel(
      id: json['id'],
      name: json['name'],
      percentage: json['percentage'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'percentage': percentage,
      'created_at': createdAt.toIso8601String(),
    };
  }
} 