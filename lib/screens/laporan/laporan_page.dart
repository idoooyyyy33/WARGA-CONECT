import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'laporan_create_page.dart';

class LaporanPage extends StatefulWidget {
  final String userName;
  final String userId;

  const LaporanPage({Key? key, required this.userName, required this.userId}) : super(key: key);

  @override
  _LaporanPageState createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  bool _isLoading = true;
  List _listLaporan = [];

  @override
  void initState() {
    super.initState();
    _fetchLaporan();
  }

  Future<void> _fetchLaporan() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://172.168.47.145:3000/api/laporan'),
        headers: {
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _listLaporan = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar("Gagal memuat laporan", Colors.red);
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
        title: Text('Laporan - ${widget.userName}'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchLaporan,
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
                    'Daftar Laporan',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                  SizedBox(height: 20),

                  // Button to create new report
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LaporanCreatePage(
                            userName: widget.userName,
                            userId: widget.userId,
                          ),
                        ),
                      ).then((_) => _fetchLaporan()); // Refresh after creating
                    },
                    icon: Icon(Icons.add),
                    label: Text('Buat Laporan Baru'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Daftar Laporan
                  _listLaporan.isEmpty
                      ? Center(
                          child: Text(
                            'Tidak ada laporan',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _listLaporan.length,
                          itemBuilder: (context, index) {
                            final laporan = _listLaporan[index];
                            return Card(
                              margin: EdgeInsets.only(bottom: 12),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.all(16),
                                title: Text(
                                  laporan['judul'] ?? 'Judul tidak tersedia',
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
                                      laporan['deskripsi'] ?? 'Deskripsi tidak tersedia',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Status: ${laporan['status'] ?? 'Tidak diketahui'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Oleh: ${laporan['pelapor_id']?['nama_lengkap'] ?? 'Pelapor tidak diketahui'}',
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
