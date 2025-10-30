import 'package:flutter/material.dart';
import 'screens/auth/login_page.dart'; // Impor file login_page.dart Anda
// --- TAMBAHAN 1: Impor untuk lokalisasi ---
import 'package:flutter_localizations/flutter_localizations.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WargaConnect UI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false, 
      
      // --- TAMBAHAN 2: 8 baris untuk support format tanggal Bahasa Indonesia ---
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('id', 'ID'), // Support Bahasa Indonesia
      ],
      // -----------------------------------------------------------------
      
      home: const LoginPage(), 
    );
  }
}
