import 'package:flutter/material.dart';

class BlankScreen extends StatelessWidget {
  final String title;

  const BlankScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            color: Color(0xFF323232),
          ),
        ),
      ),
    );
  }
} 