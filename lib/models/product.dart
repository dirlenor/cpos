class Product {
  final int id;
  final String name;
  final double price;
  final int categoryId;
  final String? imageUrl;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryId,
    this.imageUrl,
    required this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      price: double.parse(json['price'].toString()),
      categoryId: json['category_id'],
      imageUrl: json['image_url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'category_id': categoryId,
      'image_url': imageUrl,
    };
  }
} 