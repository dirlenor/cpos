import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';
import 'dashboard_screen.dart';

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  String _errorMessage = '';

  void _checkPassword() {
    if (_passwordController.text == AppConstants.ADMIN_CODE) {
      setState(() {
        _errorMessage = '';
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } else {
      setState(() {
        _errorMessage = 'ใส่รหัสไม่ถูกต้อง';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // โลโก้
            const Image(
              image: AssetImage('assets/images/logo_splash.png'),
            ),
            const SizedBox(height: 30),
            // ข้อความ
            const Text(
              'ใส่รหัส 4 หลัก',
              style: TextStyle(
                fontSize: 20,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            // ช่องใส่รหัส
            SizedBox(
              width: 200,
              child: TextField(
                controller: _passwordController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24),
                decoration: const InputDecoration(
                  counterText: '',
                  border: UnderlineInputBorder(),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (value) {
                  // ล้างข้อความแสดงข้อผิดพลาดเมื่อมีการพิมพ์หรือลบ
                  if (_errorMessage.isNotEmpty) {
                    setState(() {
                      _errorMessage = '';
                    });
                  }
                  // ตรวจสอบรหัสเมื่อครบ 4 หลัก
                  if (value.length == 4) {
                    _checkPassword();
                  }
                },
              ),
            ),
            const SizedBox(height: 10),
            // ข้อความแสดงข้อผิดพลาด
            Text(
              _errorMessage,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
} 