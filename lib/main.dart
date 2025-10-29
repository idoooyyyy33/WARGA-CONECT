import 'package:flutter/material.dart';
import 'screens/auth/login_page.dart'; // Impor file login_page.dart Anda

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
        // Menentukan skema warna utama dari warna dasar
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        // Menggunakan Material 3
        useMaterial3: true,
      ),
      // Sembunyikan banner "DEBUG" di pojok kanan atas
      debugShowCheckedModeBanner: false, 
      
      // Menjadikan LoginPage sebagai halaman utama
      home: const LoginPage(), 
    );
  }
}