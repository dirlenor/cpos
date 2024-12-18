import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/order_item.dart';
import '../services/supabase_service.dart';

class PaymentScreen extends StatefulWidget {
  final List<OrderItem> cartItems;
  final double totalAmount;

  const PaymentScreen({
    super.key,
    required this.cartItems,
    required this.totalAmount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _cashReceivedController = TextEditingController();
  String? _selectedPaymentMethod;
  double? _change;

  @override
  void dispose() {
    _cashReceivedController.dispose();
    super.dispose();
  }

  void _showCashPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.payments, color: Colors.green[900]),
              ),
              const SizedBox(width: 8),
              const Text('ชำระเงินสด'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // แสดงยอดที่ต้องชำระ
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ยอดที่ต้องชำระ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '฿${widget.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // ช่องใส่จำนวนเงิน
              TextField(
                controller: _cashReceivedController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'รับเงินมา',
                  prefixText: '฿',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                style: const TextStyle(fontSize: 24),
                autofocus: true,
                onChanged: (value) {
                  setState(() {
                    if (value.isNotEmpty) {
                      _change = double.parse(value) - widget.totalAmount;
                    } else {
                      _change = null;
                    }
                  });
                },
              ),
              if (_change != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _change! >= 0 ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _change! >= 0 ? Colors.green : Colors.red,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'เงินทอน',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '฿${_change!.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _change! >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _cashReceivedController.clear();
                _change = null;
                Navigator.pop(context);
              },
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: _change != null && _change! >= 0
                  ? () async {
                      Navigator.pop(context);
                      await _processPayment('cash');
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF323232),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                minimumSize: const Size(150, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('ยืนยันการชำระเงิน'),
            ),
          ],
          actionsPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Future<void> _processPayment(String method) async {
    try {
      // แปลงข้อมูลสินค้าให้อยู่ในรูปแบบที่จะบันทึก
      final items = widget.cartItems.map((item) => {
        'product_id': item.product.id,
        'product_name': item.product.name,
        'quantity': item.quantity,
        'price': item.product.price,
        'sweetness_level': item.sweetnessLevel.name,
        'toppings': Map.fromEntries(
          item.toppings.entries.map(
            (entry) => MapEntry(entry.key.name, entry.value)
          ),
        ),
        'total_price': item.totalPrice,
      }).toList();

      // บร้าง payload สำหรับบันทึกข้อมูล
      final payload = {
        'total_amount': widget.totalAmount,
        'items': items,
        'payment_method': method,
        'status': 'completed',
      };

      // เพิ่มข้อมูลเงินที่รับมาและเงินทอนสำหรับการชำระเงินสด
      if (method == 'cash') {
        final cashReceived = double.parse(_cashReceivedController.text);
        payload['cash_received'] = cashReceived;
        payload['change_amount'] = cashReceived - widget.totalAmount;
      }

      // บันทึกข้อมูลลง Supabase
      final response = await _supabaseService.supabase
          .from('orders')
          .insert(payload)
          .select()
          .single();

      // อัพเดทข้อมูลยอดขาย
      await _supabaseService.updateSalesAfterPayment(
        widget.totalAmount,
        method,
      );

      if (mounted) {
        // แสดง SnackBar แจ้งสำเร็จ
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกรายการสำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
        // ปิดหน้าชำระเงินและส่งค่ากลับ
        Navigator.pop(context, true);
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // พื้นที่ด้านซ้ายโปร่งใส
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                color: Colors.black54,
              ),
            ),
          ),
          // หน้าชำระเงินด้านขวา
          Container(
            width: 400,
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ส่วนหัว
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF323232),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.payment, color: Colors.white),
                      const SizedBox(width: 8),
                      const Text(
                        'ชำระเงิน',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // รายการสินค้า
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                        'รายการสินค้า',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...widget.cartItems.map((item) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey[200]!),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          title: Row(
                            children: [
                              Text(
                                item.product.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'x${item.quantity}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'ความหวาน: ${item.sweetnessLevel.name}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              if (item.toppings.isNotEmpty)
                                Text(
                                  'ท็อปปิ้ง: ${item.toppingsText}',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                            ],
                          ),
                          trailing: Text(
                            '฿${item.totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      )),
                      const SizedBox(height: 24),
                      // ยอดรวม
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'ยอดรวมทั้งสิ้น',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '฿${widget.totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // เลือกวิธีชำระเงิน
                      const Text(
                        'เลือกวิธีชำระเงิน',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // ปุ่มชำระเงินสด
                      ElevatedButton(
                        onPressed: () => _showCashPaymentDialog(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedPaymentMethod == 'cash'
                              ? const Color(0xFF323232)
                              : Colors.white,
                          foregroundColor: _selectedPaymentMethod == 'cash'
                              ? Colors.white
                              : const Color(0xFF323232),
                          padding: const EdgeInsets.all(20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Color(0xFF323232)),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.payments),
                            SizedBox(width: 8),
                            Text(
                              'ชำระด้วยเงินสด',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // ปุ่มโอนเงิน
                      ElevatedButton(
                        onPressed: () => _processPayment('transfer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedPaymentMethod == 'transfer'
                              ? const Color(0xFF323232)
                              : Colors.white,
                          foregroundColor: _selectedPaymentMethod == 'transfer'
                              ? Colors.white
                              : const Color(0xFF323232),
                          padding: const EdgeInsets.all(20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Color(0xFF323232)),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.account_balance),
                            SizedBox(width: 8),
                            Text(
                              'ชำระด้วยการโอนเงิน',
                              style: TextStyle(fontSize: 16),
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
} 