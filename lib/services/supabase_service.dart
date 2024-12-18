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
} 