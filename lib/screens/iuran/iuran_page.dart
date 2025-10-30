import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class IuranPage extends StatefulWidget {
  final String userName;
  final String userId;

  const IuranPage({Key? key, required this.userName, required this.userId}) : super(key: key);

  @override
  _IuranPageState createState() => _IuranPageState();
}

class _IuranPageState extends State<IuranPage> {
  bool _isLoading = true;
  List _listIuran = [];

  @override
  void initState() {
    super.initState();
    _fetchIuran();
  }

  Future<void> _fetchIuran() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://172.168.47.145:3000/api/iuran'),
        headers: {
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _listIuran = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar("Gagal memuat iuran", Colors.red);
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
        title: Text('Iuran - ${widget.userName}'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchIuran,
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
                    'Tagihan Iuran',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                  SizedBox(height: 20),

                  // Daftar Iuran
                  _listIuran.isEmpty
                      ? Center(
                          child: Text(
                            'Tidak ada tagihan iuran',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _listIuran.length,
                          itemBuilder: (context, index) {
                            final iuran = _listIuran[index];
                            return Card(
                              margin: EdgeInsets.only(bottom: 12),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.all(16),
                                title: Text(
                                  iuran['nama'] ?? 'Nama tidak tersedia',
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
                                      'Jumlah: Rp ${iuran['jumlah']?.toString() ?? '0'}',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Status: ${iuran['status'] ?? 'Tidak diketahui'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Tanggal: ${iuran['tanggal'] ?? 'Tidak diketahui'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: iuran['status'] == 'Belum Dibayar'
                                    ? ElevatedButton(
                                        onPressed: () {
                                          // TODO: Implement payment
                                          _showSnackBar("Fitur pembayaran akan diimplementasikan", Colors.blue);
                                        },
                                        child: Text('Bayar'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                        ),
                                      )
                                    : null,
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
