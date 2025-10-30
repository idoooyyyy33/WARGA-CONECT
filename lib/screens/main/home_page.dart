import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // Bonus untuk format tanggal

class HomePage extends StatefulWidget {
  final String userName;

  const HomePage({Key? key, required this.userName}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Ganti ke IP lokal untuk testing sementara
  final String _apiUrl = "http://172.168.47.145:3000/api/pengumuman";
  
  List _listPengumuman = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Panggil API setelah frame pertama selesai di-build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPengumuman();
    });
  }

  Future<void> _fetchPengumuman() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // SOLUSI AKHIR: Header User-Agent untuk mensimulasikan browser normal
      final response = await http.get(
        Uri.parse(_apiUrl),
        headers: {
          'ngrok-skip-browser-warning': 'true',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15)); // Timeout 15 detik

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        // PERBAIKAN 2: 'data' adalah List, bukan Map
        final data = jsonDecode(response.body);
        setState(() {
          _listPengumuman = data; // <-- LANGSUNG AMBIL 'data'
          _isLoading = false;
        });
        print("Data berhasil dimuat: ${_listPengumuman.length} pengumuman");
      } else {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar("Gagal memuat pengumuman (Status: ${response.statusCode})", Colors.red);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar("Gagal terhubung ke server: ${e.toString()}", Colors.red);
      print("Error _fetchPengumuman: $e");
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return; // Cek jika widget masih ada di tree
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Fungsi helper untuk format tanggal
  String _formatTanggal(String dateStr) {
    try {
      final dateTime = DateTime.parse(dateStr).toLocal();
      return DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(dateTime);
    } catch (e) {
      return dateStr;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50], // Latar belakang abu-abu lembut
      appBar: AppBar(
        title: Text('Dashboard Warga'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchPengumuman,
          ),
        ],
      ),
      // PERBAIKAN 3: Ubah struktur body agar ListView bisa di-scroll
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Bagian Header Selamat Datang ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Selamat Datang,",
                  style: TextStyle(fontSize: 18, color: Colors.blueGrey[700]),
                ),
                Text(
                  widget.userName,
                  style: TextStyle(
                    fontSize: 26, 
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          
          // --- Judul "Pengumuman Terbaru" ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 8.0),
            child: Text(
              "Pengumuman Terbaru",
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800]
              ),
            ),
          ),

          // --- Bagian List Pengumuman ---
          Expanded( // Gunakan Expanded agar ListView mengisi sisa ruang
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                : _listPengumuman.isEmpty
                    ? Center(
                        child: Text(
                          'Tidak ada pengumuman',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchPengumuman,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _listPengumuman.length,
                          itemBuilder: (context, index) {
                            final pengumuman = _listPengumuman[index];
                            return Card(
                              margin: EdgeInsets.only(bottom: 12),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pengumuman['judul'] ?? 'Judul tidak tersedia',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      pengumuman['isi'] ?? 'Isi tidak tersedia',
                                      style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
                                    ),
                                    SizedBox(height: 12),
                                    Divider(),
                                    SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Oleh: ${pengumuman['penulis_id']?['nama_lengkap'] ?? 'Admin'}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                        Text(
                                          _formatTanggal(pengumuman['createdAt'] ?? ''),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}