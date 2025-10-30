import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'registration_page.dart';
import '../main/main_navigation.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // GANTI INI DENGAN IP ANDA (dari ipconfig)
  final String _apiUrl = "http://192.168.1.30:3000/api/users/login";

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>(); // Key untuk validasi form

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return; // Hentikan jika validasi gagal
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userName = data['user']['nama_lengkap'];
        final userId = data['user']['_id'];

        _showSnackBar("Selamat datang, $userName!", Colors.green);

        // Navigasi ke MainNavigation dengan mengirim userName dan userId
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainNavigation(userName: userName, userId: userId),
          ),
        );

      } else {
        final error = jsonDecode(response.body);
        _showSnackBar(error['message'] ?? "Terjadi kesalahan", Colors.red);
      }

    } catch (e) {
      _showSnackBar("Gagal terhubung ke server. Periksa koneksi atau IP.", Colors.red);
      print("Error koneksi: $e"); // Cetak error lengkap ke konsol
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Media Query untuk mendapatkan ukuran layar, agar responsif
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.blueGrey[50], // Latar belakang yang lebih lembut
      body: Center(
        child: SingleChildScrollView( // Agar bisa di-scroll jika keyboard muncul
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- Logo atau Ilustrasi ---
                // Anda bisa ganti dengan Image.asset('assets/logo.png')
                // Jangan lupa tambahkan logo di folder assets dan update pubspec.yaml
                Icon(
                  Icons.people_alt,
                  size: screenHeight * 0.15, // Ukuran ikon responsif
                  color: Colors.blueAccent,
                ),
                SizedBox(height: screenHeight * 0.03),
                Text(
                  "WargaConnect",
                  style: TextStyle(
                    fontSize: screenHeight * 0.04, // Ukuran teks responsif
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
                Text(
                  "Aplikasi Komunitas Warga",
                  style: TextStyle(
                    fontSize: screenHeight * 0.02,
                    color: Colors.blueGrey[600],
                  ),
                ),
                SizedBox(height: screenHeight * 0.05),

                // --- Input Email ---
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Email",
                    hintText: "masukkan email Anda",
                    prefixIcon: Icon(Icons.email_outlined, color: Colors.blueAccent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none, // Hilangkan border default
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email tidak boleh kosong';
                    }
                    if (!value.contains('@')) {
                      return 'Masukkan email yang valid';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // --- Input Password ---
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
                    hintText: "masukkan password Anda",
                    prefixIcon: Icon(Icons.lock_outline, color: Colors.blueAccent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password tidak boleh kosong';
                    }
                    if (value.length < 6) {
                      return 'Password minimal 6 karakter';
                    }
                    return null;
                  },
                ),
                SizedBox(height: screenHeight * 0.04),

                // --- Tombol Login ---
                _isLoading
                    ? CircularProgressIndicator(color: Colors.blueAccent)
                    : SizedBox(
                        width: double.infinity, // Lebar penuh
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent, // Warna tombol
                            foregroundColor: Colors.white, // Warna teks tombol
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5, // Efek shadow
                          ),
                          child: Text(
                            "LOGIN",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                SizedBox(height: screenHeight * 0.02),

                // --- Teks untuk Registrasi ---
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterPage()),
                    );
                  },
                  child: Text(
                    "Belum punya akun? Daftar di sini",
                    style: TextStyle(color: Colors.blueAccent.shade700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}