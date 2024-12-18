import 'product.dart';
import 'sweetness_level.dart';
import 'topping.dart';

class OrderItem {
  final Product product;
  final SweetnessLevel sweetnessLevel;
  final Map<Topping, int> toppings;
  final int quantity;
  final double totalPrice;

  OrderItem({
    required this.product,
    required this.sweetnessLevel,
    required this.toppings,
    required this.quantity,
    required this.totalPrice,
  });

  // คำนวณราคารวมของ item นี้
  static double calculateTotal(
    Product product,
    Map<Topping, int> toppings,
    int quantity,
  ) {
    final toppingsTotal = toppings.entries.fold<double>(
      0,
      (sum, entry) => sum + (entry.key.price * entry.value),
    );
    return (product.price + toppingsTotal) * quantity;
  }

  // สร้าง string สำหรับแสดงรายการท็อปปิ้ง
  String get toppingsText {
    if (toppings.isEmpty) return '';
    return toppings.entries
        .map((e) => '${e.key.name} x${e.value}')
        .join(', ');
  }
} 