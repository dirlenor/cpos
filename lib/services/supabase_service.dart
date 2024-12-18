import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/sweetness_level.dart';
import '../models/topping.dart';
import 'dart:typed_data';

class SupabaseService {
  final SupabaseClient _supabase;

  SupabaseService() : _supabase = Supabase.instance.client;

  // เพิ่ม getter สำหรับเข้าถึง supabase client
  SupabaseClient get supabase => _supabase;

  // แปลง URL Google Drive เป็น URL ที่สามารถเข้าถึงรูปภาพได้โดยตรง
  String? convertGoogleDriveUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    // ตรวจสอบว่าเป็น URL Google Drive หรือไม่
    if (url.contains('drive.google.com')) {
      // ถ้าเป็น URL แชร์
      if (url.contains('/file/d/')) {
        final fileId = url.split('/file/d/')[1].split('/')[0];
        return 'https://lh3.googleusercontent.com/d/$fileId';
      }
      // ถ้าเป็น URL เปิดโดยตรง
      else if (url.contains('id=')) {
        final fileId = url.split('id=')[1].split('&')[0];
        return 'https://lh3.googleusercontent.com/d/$fileId';
      }
    }
    return url;  // ถ้าไม่ใช่ URL Google Drive ให้ใช้ URL เดิม
  }

  // Categories
  Future<List<Category>> getCategories() async {
    final response = await _supabase
        .from(SupabaseConstants.CATEGORIES_TABLE)
        .select()
        .order('name');
    
    return (response as List).map((item) => Category.fromJson(item)).toList();
  }

  Future<Category> createCategory(String name) async {
    final response = await _supabase
        .from(SupabaseConstants.CATEGORIES_TABLE)
        .insert({'name': name})
        .select()
        .single();
    
    return Category.fromJson(response);
  }

  Future<Category> updateCategory(int id, String name) async {
    final response = await _supabase
        .from(SupabaseConstants.CATEGORIES_TABLE)
        .update({'name': name})
        .eq('id', id)
        .select()
        .single();
    
    return Category.fromJson(response);
  }

  Future<void> deleteCategory(int id) async {
    // ลบสินค้าที่อยู่ในหมวดหมู่นี้ก่อน
    await _supabase
        .from(SupabaseConstants.PRODUCTS_TABLE)
        .delete()
        .eq('category_id', id);
    
    // จากนั้นลบหมวดหมู่
    await _supabase
        .from(SupabaseConstants.CATEGORIES_TABLE)
        .delete()
        .eq('id', id);
  }

  // Products
  Future<List<Product>> getProducts({int? categoryId}) async {
    var query = _supabase
        .from(SupabaseConstants.PRODUCTS_TABLE)
        .select();
    
    if (categoryId != null) {
      query = query.match({'category_id': categoryId});
    }
    
    final response = await query.order('name');
    final products = (response as List).map((item) => Product.fromJson(item)).toList();

    // แปลง URL สำหรับทุกสินค้า
    for (var product in products) {
      if (product.imageUrl != null) {
        product = Product(
          id: product.id,
          name: product.name,
          price: product.price,
          categoryId: product.categoryId,
          imageUrl: convertGoogleDriveUrl(product.imageUrl),
          createdAt: product.createdAt,
        );
      }
    }
    
    return products;
  }

  Future<Product> createProduct(Product product) async {
    // แปลง URL ก่อนบันทึก
    final convertedUrl = convertGoogleDriveUrl(product.imageUrl);
    final productToCreate = Product(
      id: product.id,
      name: product.name,
      price: product.price,
      categoryId: product.categoryId,
      imageUrl: convertedUrl,
      createdAt: product.createdAt,
    );

    final response = await _supabase
        .from(SupabaseConstants.PRODUCTS_TABLE)
        .insert(productToCreate.toJson())
        .select()
        .single();
    
    return Product.fromJson(response);
  }

  Future<Product> updateProduct(Product product) async {
    // แปลง URL ก่อนบันทึก
    final convertedUrl = convertGoogleDriveUrl(product.imageUrl);
    final productToUpdate = Product(
      id: product.id,
      name: product.name,
      price: product.price,
      categoryId: product.categoryId,
      imageUrl: convertedUrl,
      createdAt: product.createdAt,
    );

    final response = await _supabase
        .from(SupabaseConstants.PRODUCTS_TABLE)
        .update(productToUpdate.toJson())
        .eq('id', product.id)
        .select()
        .single();
    
    return Product.fromJson(response);
  }

  Future<void> deleteProduct(int id) async {
    await _supabase
        .from(SupabaseConstants.PRODUCTS_TABLE)
        .delete()
        .eq('id', id);
  }

  Future<String> uploadProductImage(Uint8List bytes, String fileName) async {
    try {
      final String path = 'products/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      await _supabase.storage.from('product-images').uploadBinary(path, bytes);
      final String imageUrl = _supabase.storage.from('product-images').getPublicUrl(path);
      return imageUrl;
    } catch (e) {
      throw Exception('ไม่สามารถอัพโหลดรูปภาพได้: $e');
    }
  }

  // Sweetness Levels
  Future<List<SweetnessLevel>> getSweetnessLevels() async {
    final response = await _supabase
        .from('sweetness_levels')
        .select()
        .order('percentage', ascending: false);
    
    return (response as List).map((item) => SweetnessLevel.fromJson(item)).toList();
  }

  // Toppings
  Future<List<Topping>> getToppings() async {
    final response = await _supabase
        .from('toppings')
        .select()
        .order('name');
    
    return (response as List).map((item) => Topping.fromJson(item)).toList();
  }

  Future<Topping> createTopping(String name, double price) async {
    final response = await _supabase
        .from('toppings')
        .insert({
          'name': name,
          'price': price,
        })
        .select()
        .single();
    
    return Topping.fromJson(response);
  }

  Future<Topping> updateTopping(int id, String name, double price) async {
    final response = await _supabase
        .from('toppings')
        .update({
          'name': name,
          'price': price,
        })
        .eq('id', id)
        .select()
        .single();
    
    return Topping.fromJson(response);
  }

  Future<void> deleteTopping(int id) async {
    await _supabase
        .from('toppings')
        .delete()
        .eq('id', id);
  }

  // Sales Summary Methods
  Future<Map<String, dynamic>> getTodaySales() async {
    final today = DateTime.now();
    final dateStr = today.toIso8601String().substring(0, 10);
    
    final response = await _supabase
        .from('sales_summary')
        .select()
        .eq('date', dateStr)
        .maybeSingle();
    
    if (response == null) {
      // ถ้าไม่มีข้อมูล ให้สร้างข้อมูลเริ่มต้น
      final initialData = {
        'date': dateStr,
        'total_sales': 0,
        'cash_sales': 0,
        'transfer_sales': 0,
        'total_orders': 0,
      };

      await _supabase
          .from('sales_summary')
          .insert(initialData);
      
      return initialData;
    }
    
    return response;
  }

  Future<List<Map<String, dynamic>>> getMonthSales(DateTime month) async {
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0);

    final response = await _supabase
        .from('sales_summary')
        .select()
        .gte('date', startDate.toIso8601String().substring(0, 10))
        .lte('date', endDate.toIso8601String().substring(0, 10))
        .order('date');
    
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateOrCreateSalesSummary(DateTime date, double totalSales, double cashSales, double transferSales, int totalOrders) async {
    final dateStr = date.toIso8601String().substring(0, 10);
    
    // ตรวจสอบว่ามีข้อมูลของวันนี้แล้วหรือไม่
    final existing = await _supabase
        .from('sales_summary')
        .select()
        .eq('date', dateStr)
        .maybeSingle();

    if (existing != null) {
      // ถ้ามีข้อมูลแล้ว ให้อัพเดท
      await _supabase
          .from('sales_summary')
          .update({
            'total_sales': totalSales,
            'cash_sales': cashSales,
            'transfer_sales': transferSales,
            'total_orders': totalOrders,
          })
          .eq('date', dateStr);
    } else {
      // ถ้ายังไม่มีข้อมูล ให้สร้างใหม่
      await _supabase
          .from('sales_summary')
          .insert({
            'date': dateStr,
            'total_sales': totalSales,
            'cash_sales': cashSales,
            'transfer_sales': transferSales,
            'total_orders': totalOrders,
          });
    }
  }

  // เมธอดสำหรับอัพเดทยอดขายเมื่อมีการชำระเงิน
  Future<void> updateSalesAfterPayment(double amount, String paymentMethod) async {
    final today = DateTime.now();
    final dateStr = today.toIso8601String().substring(0, 10);
    
    final existing = await _supabase
        .from('sales_summary')
        .select()
        .eq('date', dateStr)
        .maybeSingle();

    if (existing != null) {
      final Map<String, dynamic> data = Map.from(existing);
      data['total_sales'] = (data['total_sales'] ?? 0) + amount;
      data['total_orders'] = (data['total_orders'] ?? 0) + 1;
      
      if (paymentMethod == 'cash') {
        data['cash_sales'] = (data['cash_sales'] ?? 0) + amount;
      } else {
        data['transfer_sales'] = (data['transfer_sales'] ?? 0) + amount;
      }

      await _supabase
          .from('sales_summary')
          .update(data)
          .eq('date', dateStr);
    } else {
      final Map<String, dynamic> data = {
        'date': dateStr,
        'total_sales': amount,
        'cash_sales': paymentMethod == 'cash' ? amount : 0,
        'transfer_sales': paymentMethod == 'transfer' ? amount : 0,
        'total_orders': 1,
      };

      await _supabase
          .from('sales_summary')
          .insert(data);
    }
  }

  // เมธอดสำหรับย้ายข้อมูลการขายเก่าไปยังตาราง sales_summary
  Future<void> migrateHistoricalSales() async {
    try {
      // ดึงข้อมูลการขายทั้งหมดจากตาราง orders ที่สถานะเป็น completed
      final orders = await _supabase
          .from('orders')
          .select()
          .eq('status', 'completed')
          .order('created_at');

      // จัดกลุ่มข้อมูลตามวันที่
      final Map<String, Map<String, dynamic>> dailySales = {};

      for (final order in orders) {
        // แปลง timestamp เป็นวันที่
        final date = DateTime.parse(order['created_at']).toIso8601String().substring(0, 10);
        
        // สร้างหรืออัพเดทข้อมูลรายวัน
        if (!dailySales.containsKey(date)) {
          dailySales[date] = {
            'date': date,
            'total_sales': 0.0,
            'cash_sales': 0.0,
            'transfer_sales': 0.0,
            'total_orders': 0,
          };
        }

        final amount = (order['total_amount'] as num).toDouble();
        final paymentMethod = order['payment_method'] as String;

        dailySales[date]!['total_sales'] += amount;
        dailySales[date]!['total_orders'] += 1;

        if (paymentMethod == 'cash') {
          dailySales[date]!['cash_sales'] += amount;
        } else {
          dailySales[date]!['transfer_sales'] += amount;
        }
      }

      // บันทึกข้อมูลลงในตาราง sales_summary
      for (final data in dailySales.values) {
        await updateOrCreateSalesSummary(
          DateTime.parse(data['date']),
          data['total_sales'],
          data['cash_sales'],
          data['transfer_sales'],
          data['total_orders'],
        );
      }
    } catch (e) {
      print('Error migrating historical sales: $e');
      rethrow;
    }
  }
} 