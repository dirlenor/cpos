import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';
import 'screens/password_screen.dart';
import 'constants/supabase_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: SupabaseConstants.PROJECT_URL,
    anonKey: SupabaseConstants.ANON_KEY,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CPOS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF323232)),
        useMaterial3: true,
        fontFamily: 'NotoSansThai',
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'NotoSansThai'),
          displayMedium: TextStyle(fontFamily: 'NotoSansThai'),
          displaySmall: TextStyle(fontFamily: 'NotoSansThai'),
          headlineLarge: TextStyle(fontFamily: 'NotoSansThai'),
          headlineMedium: TextStyle(fontFamily: 'NotoSansThai'),
          headlineSmall: TextStyle(fontFamily: 'NotoSansThai'),
          titleLarge: TextStyle(fontFamily: 'NotoSansThai'),
          titleMedium: TextStyle(fontFamily: 'NotoSansThai'),
          titleSmall: TextStyle(fontFamily: 'NotoSansThai'),
          bodyLarge: TextStyle(fontFamily: 'NotoSansThai'),
          bodyMedium: TextStyle(fontFamily: 'NotoSansThai'),
          bodySmall: TextStyle(fontFamily: 'NotoSansThai'),
          labelLarge: TextStyle(fontFamily: 'NotoSansThai'),
          labelMedium: TextStyle(fontFamily: 'NotoSansThai'),
          labelSmall: TextStyle(fontFamily: 'NotoSansThai'),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// เพิ่ม Timer ใน SplashScreen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PasswordScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image(
          image: AssetImage('assets/images/logo_splash.png'),
        ),
      ),
    );
  }
}
