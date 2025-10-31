import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UmkmPage extends StatefulWidget {
  final String userName;
  final String userId;

  const UmkmPage({Key? key, required this.userName, required this.userId}) : super(key: key);

  @override
  _UmkmPageState createState() => _UmkmPageState();
}

class _UmkmPageState extends State<UmkmPage> {
  bool _isLoading = true;
  List _listUmkm = [];

  @override
  void initState() {
    super.initState();
    _fetchUmkm();
  }

  Future<void> _fetchUmkm() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://172.168.47.145:3000/api/umkm'),
        headers: {
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _listUmkm = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar("Gagal memuat UMKM", Colors.red);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar("Gagal terhubung ke server", Colors.red);
      print("Error: $e");
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
        title: Text('UMKM - ${widget.userName}'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchUmkm,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Daftar UMKM',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                  SizedBox(height: 20),

                  // Daftar UMKM
                  _listUmkm.isEmpty
                      ? Center(
                          child: Text(
                            'Tidak ada UMKM',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _listUmkm.length,
                          itemBuilder: (context, index) {
                            final umkm = _listUmkm[index];
                            return Card(
                              margin: EdgeInsets.only(bottom: 12),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.all(16),
                                title: Text(
                                  umkm['nama'] ?? 'Nama tidak tersedia',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 8),
                                    Text(
                                      umkm['deskripsi'] ?? 'Deskripsi tidak tersedia',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Jenis: ${umkm['jenis'] ?? 'Tidak diketahui'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Pemilik: ${umkm['pemilik_id']?['nama_lengkap'] ?? 'Tidak diketahui'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }
}
