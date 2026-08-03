import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const EasyPdfApp());
}

class EasyPdfApp extends StatelessWidget {
  const EasyPdfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Easy PDF',
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}