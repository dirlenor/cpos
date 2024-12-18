class Topping {
  final int id;
  final String name;
  final double price;
  final DateTime createdAt;

  Topping({
    required this.id,
    required this.name,
    required this.price,
    required this.createdAt,
  });

  factory Topping.fromJson(Map<String, dynamic> json) {
    return Topping(
      id: json['id'],
      name: json['name'],
      price: json['price'].toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'created_at': createdAt.toIso8601String(),
    };
  }
} 