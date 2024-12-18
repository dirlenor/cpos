import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;

class SalesDashboardScreen extends StatefulWidget {
  const SalesDashboardScreen({super.key});

  @override
  State<SalesDashboardScreen> createState() => _SalesDashboardScreenState();
}

class _SalesDashboardScreenState extends State<SalesDashboardScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  DateTime _selectedMonth = DateTime.now();
  double _todaySales = 0;
  double _monthSales = 0;
  double _cashSales = 0;
  double _transferSales = 0;
  List<Map<String, dynamic>> _dailySales = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await initializeDateFormatting('th');
    await _loadSalesData();
  }

  Future<void> _loadSalesData() async {
    try {
      // โหลดข้อมูลยอดขายวันนี้
      final todayData = await _supabaseService.getTodaySales();
      if (todayData != null) {
        setState(() {
          _todaySales = (todayData['total_sales'] ?? 0).toDouble();
          _cashSales = (todayData['cash_sales'] ?? 0).toDouble();
          _transferSales = (todayData['transfer_sales'] ?? 0).toDouble();
        });
      }

      // โหลดข้อมูลยอดขายทั้งเดือน
      final monthData = await _supabaseService.getMonthSales(_selectedMonth);
      if (monthData.isNotEmpty) {
        setState(() {
          _monthSales = monthData.fold(0, (sum, item) => sum + (item['total_sales'] ?? 0));
          _dailySales = monthData;
        });
      } else {
        setState(() {
          _monthSales = 0;
          _dailySales = [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _todaySales = 0;
        _monthSales = 0;
        _cashSales = 0;
        _transferSales = 0;
        _dailySales = [];
      });
    }
  }

  Future<void> _exportToPDF() async {
    final pdf = pw.Document();
    
    // ใช้ font ที่มีอยู่แล้วในระบบ
    final ttf = await rootBundle.load('assets/fonts/NotoSansThai-Regular.ttf');
    final ttfBold = await rootBundle.load('assets/fonts/NotoSansThai-Medium.ttf');
    final font = pw.Font.ttf(ttf);
    final boldFont = pw.Font.ttf(ttfBold);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // หัวรายงาน
              pw.Text(
                'รายงานยอดขายประจำเดือน ${DateFormat('MMMM yyyy', 'th').format(_selectedMonth)}',
                style: pw.TextStyle(font: boldFont, fontSize: 18),
              ),
              pw.SizedBox(height: 20),
              // สรุปยอดรวม
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('ยอดขายรวม: ฿${NumberFormat('#,##0.00').format(_monthSales)}',
                    style: pw.TextStyle(font: boldFont, fontSize: 14)),
                  pw.Text('จำนวนวันที่มียอดขาย: ${_dailySales.length} วัน',
                    style: pw.TextStyle(font: font, fontSize: 14)),
                ],
              ),
              pw.SizedBox(height: 20),
              // หัวตาราง
              pw.Container(
                color: PdfColors.grey300,
                padding: const pw.EdgeInsets.all(8),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text('วันที่',
                        style: pw.TextStyle(font: boldFont)),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text('ยอดขายรวม',
                        style: pw.TextStyle(font: boldFont),
                        textAlign: pw.TextAlign.right),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text('เงินสด',
                        style: pw.TextStyle(font: boldFont),
                        textAlign: pw.TextAlign.right),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text('เงินโอน',
                        style: pw.TextStyle(font: boldFont),
                        textAlign: pw.TextAlign.right),
                    ),
                  ],
                ),
              ),
              // รายการยอดขาย
              pw.ListView.builder(
                itemCount: _dailySales.length,
                itemBuilder: (context, index) {
                  final sale = _dailySales[index];
                  return pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(color: PdfColors.grey300),
                      ),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            DateFormat('d MMM yyyy', 'th').format(DateTime.parse(sale['date'])),
                            style: pw.TextStyle(font: font),
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            '฿${NumberFormat('#,##0.00').format(sale['total_sales'] ?? 0)}',
                            style: pw.TextStyle(font: font),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            '฿${NumberFormat('#,##0.00').format(sale['cash_sales'] ?? 0)}',
                            style: pw.TextStyle(font: font),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            '฿${NumberFormat('#,##0.00').format(sale['transfer_sales'] ?? 0)}',
                            style: pw.TextStyle(font: font),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'sales_report_${DateFormat('yyyy_MM').format(_selectedMonth)}.pdf');
  }

  Widget _buildInfoBox(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF323232),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,##0.00', 'th');
    
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ภาพรวมยอดขาย',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF323232),
                ),
              ),
              Row(
                children: [
                  // ปุ่ม Export PDF
                  ElevatedButton.icon(
                    onPressed: _exportToPDF,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Export PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // ปุ่มร้ายข้อมูลการขายเก่า
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await _supabaseService.migrateHistoricalSales();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('ย้ายข้อมูลการขายเก่าสำเร็จ'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _loadSalesData();
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
                    },
                    icon: const Icon(Icons.history),
                    label: const Text('ย้ายข้อมูลการขายเก่า'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF323232),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // ปุ่มรีเฟรช
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadSalesData,
                    tooltip: 'รีเฟรชข้อมูล',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildInfoBox(
                  'ยอดขายวันนี้',
                  '฿${numberFormat.format(_todaySales)}',
                  Icons.today,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildInfoBox(
                  'ยอดขายเดือนนี้',
                  '฿${numberFormat.format(_monthSales)}',
                  Icons.calendar_month,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildInfoBox(
                  'เงินสด / เงินโอน',
                  '฿${numberFormat.format(_cashSales)} / ฿${numberFormat.format(_transferSales)}',
                  Icons.payments,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // ส่วนแสดงรายการยอดขายรายวัน
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // หัวตาราง
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          flex: 2,
                          child: Text(
                            'วันที่',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Expanded(
                          flex: 2,
                          child: Text(
                            'ยอดขายรวม',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        const Expanded(
                          flex: 2,
                          child: Text(
                            'เงินสด',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        const Expanded(
                          flex: 2,
                          child: Text(
                            'เงินโอน',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // รายการยอดขาย
                  Expanded(
                    child: _dailySales.isEmpty
                        ? const Center(
                            child: Text(
                              'ไม่มีข้อมูลยอดขายในเดือนนี้',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _dailySales.length,
                            itemBuilder: (context, index) {
                              final sale = _dailySales[index];
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: Colors.grey[200]!),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        DateFormat('d MMM yyyy', 'th').format(DateTime.parse(sale['date'])),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '฿${numberFormat.format(sale['total_sales'] ?? 0)}',
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '฿${numberFormat.format(sale['cash_sales'] ?? 0)}',
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '฿${numberFormat.format(sale['transfer_sales'] ?? 0)}',
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 