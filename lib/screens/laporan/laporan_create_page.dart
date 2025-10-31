import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LaporanCreatePage extends StatefulWidget {
  final String userName;
  final String userId;

  const LaporanCreatePage({Key? key, required this.userName, required this.userId}) : super(key: key);

  @override
  _LaporanCreatePageState createState() => _LaporanCreatePageState();
}

class _LaporanCreatePageState extends State<LaporanCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitLaporan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://172.168.47.145:3000/api/laporan'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'judul': _judulController.text,
          'deskripsi': _deskripsiController.text,
          'pelapor_id': widget.userId,
        }),
      );

      if (response.statusCode == 201) {
        _showSnackBar("Laporan berhasil dibuat", Colors.green);
        Navigator.pop(context); // Go back to laporan list
      } else {
        _showSnackBar("Gagal membuat laporan", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Gagal terhubung ke server", Colors.red);
      print("Error: $e");
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
      appBar: AppBar(
        title: Text('Buat Laporan Baru'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Formulir Laporan',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _judulController,
                decoration: InputDecoration(
                  labelText: 'Judul Laporan',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Judul tidak boleh kosong';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _deskripsiController,
                decoration: InputDecoration(
                  labelText: 'Deskripsi Laporan',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Deskripsi tidak boleh kosong';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              _isLoading
                  ? Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                  : ElevatedButton(
                      onPressed: _submitLaporan,
                      child: Text('Kirim Laporan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        minimumSize: Size(double.infinity, 50),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }
}
