import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/topping.dart';

class ToppingScreen extends StatefulWidget {
  const ToppingScreen({super.key});

  @override
  State<ToppingScreen> createState() => _ToppingScreenState();
}

class _ToppingScreenState extends State<ToppingScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Topping> _toppings = [];
  Stream<List<Map<String, dynamic>>>? _toppingsStream;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _supabaseService.supabase
      .channel('public:toppings')
      .unsubscribe();
    super.dispose();
  }

  void _setupRealtimeSubscription() {
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
      final toppings = await _supabaseService.getToppings();
      if (mounted) {
        setState(() {
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

  void _showAddToppingDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เพิ่มท็อปปิ้ง'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'ชื่อท็อปปิ้ง',
              ),
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: 'ราคา',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  priceController.text.isNotEmpty) {
                try {
                  await _supabaseService.createTopping(
                    nameController.text,
                    double.parse(priceController.text),
                  );
                  _loadData();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('เพิ่มท็อปปิ้งสำเร็จ')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('เกิดข้อผิดพลาด: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  void _showEditToppingDialog(Topping topping) {
    final TextEditingController nameController = TextEditingController(text: topping.name);
    final TextEditingController priceController = TextEditingController(text: topping.price.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('แก้ไขท็อปปิ้ง'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'ชื่อท็อปปิ้ง',
              ),
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: 'ราคา',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  priceController.text.isNotEmpty) {
                try {
                  await _supabaseService.updateTopping(
                    topping.id,
                    nameController.text,
                    double.parse(priceController.text),
                  );
                  _loadData();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('แก้ไขท็อปปิ้งสำเร็จ')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('เกิดข้อผิดพลาด: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  void _showDeleteToppingDialog(Topping topping) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('คุณต้องการลบท็อปปิ้ง "${topping.name}" หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _supabaseService.deleteTopping(topping.id);
                _loadData();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ลบท็อปปิ้งสำเร็จ')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('เกิดข้อผิดพลาด: ${e.toString()}')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _showAddToppingDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('เพิ่มท็อปปิ้ง'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF323232),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: ListView.builder(
                  itemCount: _toppings.length,
                  itemBuilder: (context, index) {
                    final topping = _toppings[index];
                    return ListTile(
                      title: Text(topping.name),
                      subtitle: Text('฿${topping.price.toStringAsFixed(2)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showEditToppingDialog(topping),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _showDeleteToppingDialog(topping),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 