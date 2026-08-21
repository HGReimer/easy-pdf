import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main(List<String> args) {
  final initialFilePath = args.isNotEmpty ? args.first : null;

  runApp(EasyPdfApp(initialFilePath: initialFilePath));
}

class EasyPdfApp extends StatelessWidget {
  const EasyPdfApp({super.key, this.initialFilePath});

  final String? initialFilePath;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Easy PDF',
      debugShowCheckedModeBanner: false,
      home: HomeScreen(initialFilePath: initialFilePath),
    );
  }
}
