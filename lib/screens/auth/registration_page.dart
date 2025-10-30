import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // GANTI INI DENGAN IP ANDA (dari ipconfig)
  final String _apiUrl = "http://172.168.47.145:3000/api/users/register";

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Siapkan controller untuk SEMUA field
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _noKkController = TextEditingController();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _rtController = TextEditingController();
  final TextEditingController _rwController = TextEditingController();
  final TextEditingController _noHpController = TextEditingController();


  Future<void> _register() async {
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
          // Ambil data dari semua controller
          'nik': _nikController.text,
          'no_kk': _noKkController.text,
          'nama_lengkap': _namaController.text,
          'email': _emailController.text,
          'password': _passwordController.text, // Backend akan hash ini
          'rt': _rtController.text,
          'rw': _rwController.text,
          'no_hp': _noHpController.text,
        }),
      );

      if (response.statusCode == 201) { // 201 = Created (Sukses)
        _showSnackBar("Registrasi berhasil! Silakan login.", Colors.green);
        // Kembali ke halaman login setelah berhasil
        Navigator.pop(context); 

      } else {
        // Gagal (Email/NIK sudah terdaftar, dll)
        final error = jsonDecode(response.body);
        _showSnackBar(error['message'] ?? "Terjadi kesalahan", Colors.red);
      }

    } catch (e) {
      _showSnackBar("Gagal terhubung ke server. Periksa koneksi atau IP.", Colors.red);
      print("Error koneksi: $e");
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
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      // AppBar agar ada tombol "Back" otomatis
      appBar: AppBar(
        title: Text("Daftar Akun Baru"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.blueGrey[800]), // Tombol back
        titleTextStyle: TextStyle(
          color: Colors.blueGrey[800],
          fontSize: 20,
          fontWeight: FontWeight.bold
        ),
      ),
      body: Center(
        child: SingleChildScrollView( // Wajib pakai ini karena form-nya panjang
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Panggil _buildTextField untuk setiap field
                _buildTextField(_nikController, "NIK", Icons.person_pin, keyboardType: TextInputType.number),
                SizedBox(height: 16),
                _buildTextField(_noKkController, "No. KK", Icons.group, keyboardType: TextInputType.number),
                SizedBox(height: 16),
                _buildTextField(_namaController, "Nama Lengkap", Icons.person),
                SizedBox(height: 16),
                _buildTextField(_emailController, "Email", Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                SizedBox(height: 16),
                _buildTextField(_passwordController, "Password", Icons.lock_outline, obscureText: true),
                SizedBox(height: 16),
                _buildTextField(_rtController, "RT", Icons.location_on_outlined, hint: "Contoh: 001"),
                SizedBox(height: 16),
                _buildTextField(_rwController, "RW", Icons.location_on_outlined, hint: "Contoh: 001"),
                SizedBox(height: 16),
                _buildTextField(_noHpController, "No. HP", Icons.phone_android, keyboardType: TextInputType.phone),
                SizedBox(height: 32),

                // Tombol Daftar
                _isLoading
                    ? CircularProgressIndicator(color: Colors.blueAccent)
                    : SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "DAFTAR",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget helper agar tidak berulang-ulang
  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool obscureText = false, TextInputType? keyboardType, String? hint}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blueAccent),
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
          return '$label tidak boleh kosong';
        }
        return null;
      },
    );
  }

  @override
  void dispose() {
    // Bersihkan semua controller
    _nikController.dispose();
    _noKkController.dispose();
    _namaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _rtController.dispose();
    _rwController.dispose();
    _noHpController.dispose();
    super.dispose();
  }
}