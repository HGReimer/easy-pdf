import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
      locale: const Locale('de', 'DE'),
      supportedLocales: const [Locale('de', 'DE')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: HomeScreen(initialFilePath: initialFilePath),
    );
  }
}
