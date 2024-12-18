import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import 'blank_screen.dart';
import 'password_screen.dart';
import 'menu_category_screen.dart';
import 'topping_screen.dart';
import 'order_history_screen.dart';
import 'payment_screen.dart';
import 'sales_dashboard_screen.dart';
import '../services/supabase_service.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/sweetness_level.dart';
import '../models/topping.dart';
import '../models/order_item.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  Offset _catPosition = const Offset(20, 20);
  bool _showCatAnimation = false;

  final List<Widget> _screens = [
    // หน้าสั่งออเด้อ (หน้าเดิม)
    const _OrderScreen(),
    // หน้าบันทึกยอดขาย
    const SalesDashboardScreen(),
    // หน้าเมนู-หมวดหมู่
    const MenuCategoryScreen(),
    // หน้าตระวัติการสั่งซื้อ
    const OrderHistoryScreen(),
  ];

  void _handleLogout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const PasswordScreen()),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.settings, color: Color(0xFF323232)),
            ),
            const SizedBox(width: 8),
            const Text('ตั้งค่า'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('แสดงแมวน้อย'),
              trailing: Switch(
                value: _showCatAnimation,
                onChanged: (value) {
                  setState(() {
                    _showCatAnimation = value;
                  });
                  Navigator.pop(context);
                },
                activeColor: const Color(0xFF323232),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              // Sidebar
              Container(
                width: 250,
                color: const Color(0xFF323232),
                child: Column(
                  children: [
                    // Logo
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Image.asset(
                        'assets/images/logo_dash_m.png',
                        height: 35,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Menu items
                    Expanded(
                      child: Column(
                        children: [
                          _buildMenuItem(0, Icons.point_of_sale, 'สั่���ออเด้อ'),
                          _buildMenuItem(1, Icons.receipt_long, 'บันทึกยอดขาย'),
                          _buildMenuItem(2, Icons.restaurant_menu, 'เมนู-หมวดหมู่'),
                          _buildMenuItem(3, Icons.history, 'ประวัติการสั่งซื้อ'),
                          const Spacer(),
                          _buildMenuItem(5, Icons.settings, 'ตั้งค่า', onTap: _showSettingsDialog),
                        ],
                      ),
                    ),
                    // Logout button with white border
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: _buildMenuItem(4, Icons.logout, 'ออกจากระบบ'),
                    ),
                  ],
                ),
              ),
              // Main content
              Expanded(
                child: _screens[_selectedIndex],
              ),
            ],
          ),
          // Draggable Cat Animation
          if (_showCatAnimation)
            Positioned(
              left: _catPosition.dx,
              top: _catPosition.dy,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _catPosition = Offset(
                      _catPosition.dx + details.delta.dx,
                      _catPosition.dy + details.delta.dy,
                    );
                  });
                },
                child: Container(
                  width: 200,
                  height: 200,
                  child: Lottie.asset(
                    'assets/lottie/cat.json',
                    fit: BoxFit.contain,
                    repeat: true,
                    width: 180,
                    height: 180,
                    options: LottieOptions(enableMergePaths: true),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, IconData icon, String text, {VoidCallback? onTap}) {
    final bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: onTap ?? () {
        if (index == 4) {
          // ออกจากระบบ
          _handleLogout();
        } else {
          setState(() {
            _selectedIndex = index;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                fontFamily: 'NotoSansThai',
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ยกหน้าสั่งออเด้อออกมาเป็น Widget แยก
class _OrderScreen extends StatefulWidget {
  const _OrderScreen();

  @override
  State<_OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<_OrderScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Product> _products = [];
  List<Category> _categories = [];
  List<SweetnessLevel> _sweetnessLevels = [];
  List<Topping> _toppings = [];
  Category? _selectedCategory;
  int _currentPage = 0;
  
  // เพิ่มตัวแปรสำหรับเก็บรายการในตะกร้า
  List<OrderItem> _cartItems = [];
  double _cartTotal = 0;

  // เพิ่มตัวแปรสำหรับเก็บ subscription
  Stream<List<Map<String, dynamic>>>? _productsStream;
  Stream<List<Map<String, dynamic>>>? _categoriesStream;
  Stream<List<Map<String, dynamic>>>? _toppingsStream;

  // เพิ่มตัวแปรสำหรับควบคุมการย่อ/ขยาย
  bool _isOrderBoxCollapsed = false;

  // เพิ่มตัวแปรสำหรับเก็บเวลาปัจจุบัน
  DateTime _currentTime = DateTime.now();
  Timer? _timer;
  // เพิ่มตัวแปรสำหรับชื่อผู้ใช้
  final String _userName = "Captain";

  // เพิ่มฟังก์ชันสำหรับรีเฟรชข้อมูลทั้งหมด
  Future<void> _refreshApp() async {
    try {
      // รีเฟรชข้อมูลทั้งหมด
      await _loadData();
      // แสดงข้อความสำเร็จ
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('รีเฟร���ข้อมูลสำเร็จ'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupRealtimeSubscription();
    // เริ่ม timer สำหรับอัพเดทเวลา
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _supabaseService.supabase
      .channel('public:products')
      .unsubscribe();
    _supabaseService.supabase
      .channel('public:categories')
      .unsubscribe();
    _supabaseService.supabase
      .channel('public:toppings')
      .unsubscribe();
    super.dispose();
  }

  void _setupRealtimeSubscription() {
    // subscription สำหรับตาราง products
    _productsStream = _supabaseService.supabase
      .from('products')
      .stream(primaryKey: ['id'])
      ..listen((List<Map<String, dynamic>> data) {
        if (mounted) {
          setState(() {
            _products = data.map((item) => Product.fromJson(item)).toList();
          });
        }
      });

    // subscription สำหรับตาราง categories
    _categoriesStream = _supabaseService.supabase
      .from('categories')
      .stream(primaryKey: ['id'])
      ..listen((List<Map<String, dynamic>> data) {
        if (mounted) {
          setState(() {
            _categories = data.map((item) => Category.fromJson(item)).toList();
          });
        }
      });

    // subscription สำหรับตาราง toppings
    _toppingsStream = _supabaseService.supabase
      .from('toppings')
      .stream(primaryKey: ['id'])
      ..listen((List<Map<String, dynamic>> data) {
        if (mounted) {
          setState(() {
            _toppings = data.map((item) => Topping.fromJson(item)).toList();
          });
        }
      });
  }

  Future<void> _loadData() async {
    try {
      final categories = await _supabaseService.getCategories();
      final products = await _supabaseService.getProducts();
      final sweetnessLevels = await _supabaseService.getSweetnessLevels();
      final toppings = await _supabaseService.getToppings();
      if (mounted) {
        setState(() {
          _categories = categories;
          _products = products;
          _sweetnessLevels = sweetnessLevels;
          _toppings = toppings;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: ${e.toString()}')),
        );
      }
    }
  }

  void _addToCart(OrderItem item) {
    setState(() {
      _cartItems.add(item);
      _updateCartTotal();
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      _cartItems.removeAt(index);
      _updateCartTotal();
    });
  }

  void _updateCartItem(int index, OrderItem newItem) {
    setState(() {
      _cartItems[index] = newItem;
      _updateCartTotal();
    });
  }

  void _updateCartTotal() {
    _cartTotal = _cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  }

  void _showOrderOptionsDialog(Product product, {OrderItem? editingItem, int? editingIndex}) {
    // ถ้าเป็นการแก้ไข ใช้ค่าเดิมจาก OrderItem
    SweetnessLevel? selectedSweetness = editingItem?.sweetnessLevel ?? _sweetnessLevels.first;
    Map<Topping, int> selectedToppings = editingItem?.toppings ?? {};
    int quantity = editingItem?.quantity ?? 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          child: Container(
            width: 600,
            height: 700,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ส่วนหัว
                Row(
                  children: [
                    Text(
                      editingItem != null ? 'แก้ไข ${product.name}' : product.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // เนื้อหา
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // รูสสินค้าด้านซ้าย
                      if (product.imageUrl != null)
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: NetworkImage(product.imageUrl!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      const SizedBox(width: 16),
                      // ตัวเลือกด้า���ขวา
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ระดับความหวาน
                            const Text(
                              'ระดับความหวาน',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<SweetnessLevel>(
                              value: selectedSweetness,
                              items: _sweetnessLevels.map((sweetness) {
                                return DropdownMenuItem(
                                  value: sweetness,
                                  child: Text(sweetness.name),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedSweetness = value;
                                });
                              },
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Divider(height: 1, thickness: 1),
                            const SizedBox(height: 16),
                            // เลือกท็อปปิ้ง
                            const Text(
                              'เลือกท็อปปิ้ง',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: _toppings.map((topping) {
                                      final toppingCount = selectedToppings[topping] ?? 0;
                                      return ListTile(
                                        dense: true,
                                        title: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    topping.name,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    '฿${topping.price.toStringAsFixed(2)}',
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (toppingCount > 0) ...[
                                              IconButton(
                                                icon: const Icon(Icons.remove),
                                                onPressed: () {
                                                  setState(() {
                                                    if (toppingCount > 1) {
                                                      selectedToppings[topping] = toppingCount - 1;
                                                    } else {
                                                      selectedToppings.remove(topping);
                                                    }
                                                  });
                                                },
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                                child: Text(
                                                  toppingCount.toString(),
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.add),
                                                onPressed: () {
                                                  setState(() {
                                                    selectedToppings[topping] = toppingCount + 1;
                                                  });
                                                },
                                              ),
                                            ] else
                                              ElevatedButton(
                                                onPressed: () {
                                                  setState(() {
                                                    selectedToppings[topping] = 1;
                                                  });
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF323232),
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                                ),
                                                child: const Text('เพิ่ม'),
                                              ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // แสงราคารวม
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'จำนวน',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      // เลือกจำนวน
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.white,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                if (quantity > 1) {
                                  setState(() => quantity--);
                                }
                              },
                              iconSize: 20,
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                quantity.toString(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                setState(() => quantity++);
                              },
                              iconSize: 20,
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // ปุ่มด้านล่าง
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () {
                      final orderItem = OrderItem(
                        product: product,
                        sweetnessLevel: selectedSweetness!,
                        toppings: selectedToppings,
                        quantity: quantity,
                        totalPrice: OrderItem.calculateTotal(
                          product,
                          selectedToppings,
                          quantity,
                        ),
                      );
                      if (editingIndex != null) {
                        _updateCartItem(editingIndex, orderItem);
                      } else {
                        _addToCart(orderItem);
                      }
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF323232),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          editingItem != null ? 'บัน��ึกการแก้ไข' : 'เพิ่มลงตะกร้า',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '฿${((product.price + selectedToppings.entries.fold<double>(0, (sum, entry) => sum + (entry.key.price * entry.value))) * quantity).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item, int index) {
    return InkWell(
      onTap: () => _showOrderOptionsDialog(
        item.product,
        editingItem: item,
        editingIndex: index,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF323232)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ชื่อสินค้าละปุ่ลบ
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF323232),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _removeFromCart(index),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // ระดับความหวาน
            Text(
              'ความหวาน: ${item.sweetnessLevel.name}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            // ท็อปปิ้ง (ถ้ามี)
            if (item.toppings.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'ท็อปปิ้ง: ${item.toppingsText}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 8),
            // จำนวนและราคา
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'x${item.quantity}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF323232),
                  ),
                ),
                Text(
                  '฿${item.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF323232),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _selectedCategory != null
        ? _products.where((p) => p.categoryId == _selectedCategory!.id).toList()
        : _products;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // แถวบนสุดที่มีปุ่มหมวดหมู่และเวลา
          Row(
            children: [
              // ปุ่มหมวดหมู่ด้านซ้าย
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTopButton('ทั้งหมด', _selectedCategory == null, () {
                        setState(() => _selectedCategory = null);
                      }),
                      const SizedBox(width: 8),
                      ..._categories.map((category) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildTopButton(
                            category.name,
                            _selectedCategory?.id == category.id,
                            () {
                              setState(() => _selectedCategory = category);
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              // แสดงวื่อผู้ใช้และปุ่มรีเฟรช
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // ปุ่มรีเฟรช
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF323232),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                        onPressed: _refreshApp,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        tooltip: 'รีเฟรชข้อมูล',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // แสดงวันที่และเวลาด้านขวา
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF323232),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 20, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      '${_currentTime.day}/${_currentTime.month}/${_currentTime.year} ${_currentTime.hour.toString().padLeft(2, '0')}:${_currentTime.minute.toString().padLeft(2, '0')}:${_currentTime.second.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Grid of menu items
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side - Grid of menu items
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      Expanded(
                        child: PageView.builder(
                          onPageChanged: (index) {
                            setState(() {
                              _currentPage = index;
                            });
                          },
                          itemCount: (filteredProducts.length / 12).ceil(),
                          itemBuilder: (context, pageIndex) {
                            final startIndex = pageIndex * 12;
                            final endIndex = (startIndex + 12) > filteredProducts.length
                                ? filteredProducts.length
                                : startIndex + 12;
                            final pageProducts = filteredProducts.sublist(startIndex, endIndex);
                            
                            return GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                childAspectRatio: 0.793,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: pageProducts.length,
                              itemBuilder: (context, index) {
                                final product = pageProducts[index];
                                return _buildMenuCard(product);
                              },
                            );
                          },
                        ),
                      ),
                      if ((filteredProducts.length / 12).ceil() > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              (filteredProducts.length / 12).ceil(),
                              (index) => Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: index == _currentPage ? const Color(0xFF323232) : Colors.grey[300],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Right side - Order summary
                Container(
                  width: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF323232)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF323232),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(7),
                          ),
                        ),
                        child: const Text(
                          'รายการสั่งซื้อ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _cartItems.isEmpty
                            ? Center(
                                child: Text(
                                  'ยังไม่มรายการ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _cartItems.length,
                                itemBuilder: (context, index) {
                                  return _buildOrderItem(_cartItems[index], index);
                                },
                              ),
                      ),
                      if (_cartItems.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'ยอดร���ม',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '฿${_cartTotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {},
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        side: const BorderSide(color: Color(0xFF323232)),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      child: const Text(
                                        'โปรโมชั่น',
                                        style: TextStyle(
                                          color: Color(0xFF323232),
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        final result = await Navigator.push(
                                          context,
                                          PageRouteBuilder(
                                            pageBuilder: (context, animation, secondaryAnimation) => PaymentScreen(
                                              cartItems: _cartItems,
                                              totalAmount: _cartTotal,
                                            ),
                                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                              const begin = Offset(1.0, 0.0);
                                              const end = Offset.zero;
                                              const curve = Curves.easeInOut;
                                              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                              var offsetAnimation = animation.drive(tween);
                                              return SlideTransition(position: offsetAnimation, child: child);
                                            },
                                          ),
                                        );
                                        if (result == true) {
                                          setState(() {
                                            _cartItems.clear();
                                            _updateCartTotal();
                                          });
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF323232),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      child: const Text(
                                        'ชำระเงิน',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopButton(String text, bool isSelected, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFF323232) : Colors.white,
        side: const BorderSide(color: Color(0xFF323232)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF323232),
        ),
      ),
    );
  }

  Widget _buildMenuCard(Product product) {
    return InkWell(
      onTap: () => _showOrderOptionsDialog(product),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF323232)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // รูปภาพสินค้า
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                child: product.imageUrl != null
                    ? Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.image_not_supported, size: 40),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported, size: 40),
                      ),
              ),
            ),
            // ข้อมูลสินค้า
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '฿${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 