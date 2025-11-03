import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // --- PERHATIAN: Pastikan IP ini benar dan HP/Emulator Anda terhubung ke WiFi yang sama ---
  static const String baseUrl = 'http://172.168.47.153:3000/api';

  // Helper untuk handle response
  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': data};
      } else {
        // --- PERBAIKAN: Memberi pesan error yang lebih jelas dari server ---
        String errorMessage = 'Terjadi kesalahan';
        if (data is Map && data.containsKey('message')) {
          errorMessage = data['message'];
        } else if (data is Map && data.containsKey('error')) {
          errorMessage = data['error'];
        } else if (data is String) {
          errorMessage = data;
        }
        return {
          'success': false,
          'message': errorMessage,
          'statusCode': response.statusCode // Tambahkan status code untuk debug
        };
      }
    } catch (e) {
      // Ini terjadi jika server mengirim HTML (seperti error 404 atau 500)
      if (e is FormatException && response.body.contains('<!DOCTYPE')) {
         return {'success': false, 'message': 'Error: Server mengirimkan HTML, bukan JSON. Cek URL API atau log server. (Status: ${response.statusCode})'};
      }
      return {'success': false, 'message': 'Gagal memproses data: $e'};
    }
  }

  // Get token from storage
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Save token to storage
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // Clear token
  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    // --- TAMBAHAN: Hapus juga user_data saat logout ---
    await prefs.remove('user_data'); 
  }

  // Headers with authorization
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // --- PERBAIKAN: Simpan token dan user_data ---
        if (data['token'] != null) {
          await _saveToken(data['token']);
        }
        if (data['user'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_data', jsonEncode(data['user']));
        }
        
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Login gagal'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Register
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );
      // Gunakan _handleResponse
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Logout
  Future<void> logout() async {
    await _clearToken();
  }

  // Get Announcements
  Future<Map<String, dynamic>> getAnnouncements() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/pengumuman'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final transformedData = data.map((item) => {
          'title': item['judul'] ?? 'Pengumuman',
          'description': item['isi'] ?? '',
          'date': item['tanggal_dibuat'] != null
              ? DateTime.parse(item['tanggal_dibuat']).toString().split(' ')[0]
              : '',
          'author': item['penulis_id']?['nama_lengkap'] ?? 'Admin',
        }).toList();
        return {'success': true, 'data': transformedData};
      } else {
        return _handleResponse(response);
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Get Reports
  Future<Map<String, dynamic>> getReports() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/laporan'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final transformedData = data.map((item) => {
          'id': item['_id'], // --- TAMBAHAN ID (jika perlu) ---
          'title': item['judul_laporan'] ?? 'Laporan',
          'description': item['isi_laporan'] ?? '',
          'category': item['kategori_laporan'] ?? 'Lainnya',
          'status': item['status_laporan'] ?? 'Menunggu',
          'date': item['tanggal_dibuat'] != null
              ? DateTime.parse(item['tanggal_dibuat']).toString().split(' ')[0]
              : '',
          'author': item['pelapor_id']?['nama_lengkap'] ?? 'Anonim',
        }).toList();
        return {'success': true, 'data': transformedData};
      } else {
        return _handleResponse(response);
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Create Report
  Future<Map<String, dynamic>> createReport(Map<String, dynamic> reportData) async {
    try {
      // PERBAIKAN: Dapatkan ID pelapor dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      if (userDataString == null) {
        return {'success': false, 'message': 'User tidak terautentikasi. Silakan login ulang.'};
      }
      final userData = jsonDecode(userDataString);
      final pelaporId = userData['_id']; // Asumsi ID user adalah _id

      // Tambahkan pelapor_id ke data laporan
      reportData['pelapor_id'] = pelaporId;
      // BATAS PERBAIKAN

      final response = await http.post(
        Uri.parse('$baseUrl/laporan'), // Endpoint sudah benar
        headers: await _getHeaders(),
        body: jsonEncode(reportData),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Get Payments
  Future<Map<String, dynamic>> getPayments() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/iuran'), // Ini akan mengambil semua iuran untuk user yg login (jika backend disetup)
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final transformedData = data.map((item) => {
          'id': item['_id'], // --- TAMBAHAN: Kita butuh ID untuk bayar ---
          'title': item['judul_iuran'] ?? 'Iuran',
          'description': item['judul_iuran'] ?? 'Pembayaran iuran',
          'amount': item['jumlah'] ?? 0,
          'status': item['status_pembayaran'] ?? 'Menunggu',
          'type': item['jenis_iuran'] ?? 'Iuran', // --- PERBAIKAN ---
          'date': item['jatuh_tempo'] != null
              ? DateTime.parse(item['jatuh_tempo']).toString().split(' ')[0]
              : '',
          'periode': item['periode'] != null
              ? '${item['periode']['bulan']}/${item['periode']['tahun']}'
              : '',
        }).toList();
        return {'success': true, 'data': transformedData};
      } else {
        return _handleResponse(response);
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Get Activities
  Future<Map<String, dynamic>> getActivities() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/kegiatan'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final transformedData = data.map((item) => {
          'title': item['nama_kegiatan'] ?? 'Kegiatan',
          'description': item['deskripsi'] ?? '',
          'date': item['tanggal_mulai'] != null
              ? DateTime.parse(item['tanggal_mulai']).toString().split(' ')[0]
              : '',
          'location': item['lokasi'] ?? 'Lokasi belum ditentukan',
          'fullDescription': item['deskripsi'] ?? '',
        }).toList();
        return {'success': true, 'data': transformedData};
      } else {
        return _handleResponse(response);
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Get UMKM
  Future<Map<String, dynamic>> getUMKM() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/umkm'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final transformedData = data.map((item) => {
          'name': item['nama_usaha'] ?? 'UMKM',
          'title': item['nama_usaha'] ?? 'UMKM',
          'category': item['kategori_usaha'] ?? 'Lainnya',
          'description': item['deskripsi_usaha'] ?? '',
          'owner': item['pemilik_id']?['nama_lengkap'] ?? 'Anonim',
          'phone': item['kontak']?['telepon'] ?? '',
          'address': item['lokasi'] ?? '',
        }).toList();
        return {'success': true, 'data': transformedData};
      } else {
        return _handleResponse(response);
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Admin Verification Methods
  Future<Map<String, dynamic>> sendAdminVerificationCode(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/send-verification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  Future<Map<String, dynamic>> verifyAdminCode(String email, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/verify-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Get Admin Stats
  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/stats'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Get Aktivitas Terbaru (Admin)
  Future<Map<String, dynamic>> getAktivitasTerbaru() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/aktivitas'), 
        headers: await _getHeaders(),
      );
      return _handleResponse(response); 
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Get Laporan (Admin)
  Future<Map<String, dynamic>> getLaporan() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/laporan'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final transformedData = data.map((item) => {
          'id': item['_id'],
          'judul': item['judul_laporan'] ?? 'Laporan',
          'deskripsi': item['isi_laporan'] ?? '',
          'kategori': item['kategori_laporan'] ?? 'Lainnya',
          'status': item['status_laporan'] ?? 'Menunggu',
          'tanggal': item['createdAt'] != null
              ? DateTime.parse(item['createdAt']).toString().split(' ')[0]
              : '',
          'nama_pelapor': item['pelapor_id']?['nama_lengkap'] ?? 'Anonim',
          'lokasi': item['lokasi'] ?? '',
          'tanggapan': item['tanggapan'] ?? '',
        }).toList();
        return {'success': true, 'data': transformedData};
      } else {
        return _handleResponse(response);
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Update Status Laporan
  Future<Map<String, dynamic>> updateStatusLaporan(String id, String status, String tanggapan) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/laporan/$id'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'status_laporan': status,
          'tanggapan': tanggapan,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Delete Laporan
  Future<Map<String, dynamic>> deleteLaporan(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/laporan/$id'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Get Iuran (Admin)
  Future<Map<String, dynamic>> getIuran(int bulan, int tahun) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/iuran?bulan=$bulan&tahun=$tahun'), // Ini endpoint admin
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final transformedData = data.map((item) => {
          'id': item['_id'], 
          'warga_id': item['warga_id']?['_id'],
          'nama_warga': item['warga_id']?['nama_lengkap'] ?? 'Anonim',
          'jenis_iuran': item['jenis_iuran'] ?? 'Iuran',
          'nominal': item['nominal'] ?? 0,
          'status': item['status'] ?? 'Belum Lunas',
          'tanggal_bayar': item['tanggal_bayar'],
          'metode_pembayaran': item['metode_pembayaran'] ?? '-',
        }).toList();
        return {'success': true, 'data': transformedData};
      } else {
        return _handleResponse(response);
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // --- PERBAIKAN: Mengganti URL /users/warga yang error 404 ---
  // Get Warga (dipakai di dropdown Iuran Admin)
  Future<Map<String, dynamic>> getWarga() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/warga'), // Menggunakan endpoint admin yang valid
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }
  // --- BATAS PERBAIKAN ---

  // Bayar Iuran (ini dipakai oleh Admin IuranPage)
  Future<Map<String, dynamic>> bayarIuran(
      String wargaId, 
      int nominal, 
      String bulan, 
      int tahun, 
      String metodePembayaran) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/iuran'), // Endpoint ini sepertinya untuk *membuat* tagihan baru
        headers: await _getHeaders(),
        body: jsonEncode({
          'warga_id': wargaId,
          'nominal': nominal,
          'bulan': bulan,
          'tahun': tahun,
          'metode_pembayaran': metodePembayaran,
          // Seharusnya ada 'pembuat_id' (admin) di sini, tapi kita ikuti logika IuranPage
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Delete Iuran
  Future<Map<String, dynamic>> deleteIuran(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/iuran/$id'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // --- TAMBAHAN BARU: Fungsi untuk upload bukti bayar ---
  Future<Map<String, dynamic>> uploadPaymentProof(String iuranId, Uint8List imageBytes, String fileName) async {
    try {
      final uri = Uri.parse('$baseUrl/iuran/$iuranId/upload-proof');
      final request = http.MultipartRequest('PUT', uri);
      
      // Tambahkan token header
      final token = await _getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      // Tambahkan file gambar dari bytes
      request.files.add(
        http.MultipartFile.fromBytes(
          'bukti_pembayaran', // Nama field (harus sama dengan di backend)
          imageBytes,
          filename: fileName // Nama file aslinya
        )
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final decodedData = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        return {'success': true, 'data': decodedData};
      } else {
        return {'success': false, 'message': decodedData['message'] ?? 'Gagal upload bukti'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }
  // --- BATAS FUNGSI BARU ---

// --- TAMBAHKAN FUNGSI INI ---
  // Untuk Admin memverifikasi/menolak pembayaran
  Future<Map<String, dynamic>> updateIuranStatus(String iuranId, String status) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/iuran/$iuranId'), // Menggunakan endpoint PUT iuran yang sudah ada
        headers: await _getHeaders(),
        body: jsonEncode({
          'status_pembayaran': status,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }
  // Get Kegiatan (Admin)
  Future<Map<String, dynamic>> getKegiatan() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/kegiatan'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final transformedData = data.map((item) => {
          'id': item['_id'],
          'nama_kegiatan': item['nama_kegiatan'] ?? 'Kegiatan',
          'deskripsi': item['deskripsi'] ?? '',
          'tanggal_mulai': item['tanggal_kegiatan'] != null
              ? DateTime.parse(item['tanggal_kegiatan']).toString().split(' ')[0]
              : '',
          'lokasi': item['lokasi'] ?? '',
          'penanggung_jawab': item['penanggung_jawab_id']?['nama_lengkap'] ?? 'Admin',
        }).toList();
        return {'success': true, 'data': transformedData};
      } else {
        return _handleResponse(response);
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Update Kegiatan
  Future<Map<String, dynamic>> updateKegiatan(String id, String nama, String deskripsi, String tanggal, String waktu, String lokasi, String kategori, String penyelenggara) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/kegiatan/$id'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'nama_kegiatan': nama,
          'deskripsi': deskripsi,
          'tanggal_kegiatan': tanggal,
          'waktu': waktu,
          'lokasi': lokasi,
          'kategori': kategori,
          'penyelenggara': penyelenggara,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Create Kegiatan
  Future<Map<String, dynamic>> createKegiatan(String nama, String deskripsi, String tanggal, String waktu, String lokasi, String kategori, String penyelenggara) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/kegiatan'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'nama_kegiatan': nama,
          'deskripsi': deskripsi,
          'tanggal_kegiatan': tanggal,
          'waktu': waktu,
          'lokasi': lokasi,
          'kategori': kategori,
          'penyelenggara': penyelenggara,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Delete Kegiatan
  Future<Map<String, dynamic>> deleteKegiatan(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/kegiatan/$id'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Get Pengumuman (Admin)
  Future<Map<String, dynamic>> getPengumuman() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/pengumuman'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final transformedData = data.map((item) => {
          'id': item['_id'],
          'judul': item['judul'] ?? 'Pengumuman',
          'isi': item['isi'] ?? '',
          'penjelasan': item['penjelasan'] ?? '',
          'prioritas': item['prioritas'] ?? 'normal',
          'tanggal': item['createdAt'] != null
              ? DateTime.parse(item['createdAt']).toString()
              : '',
          'penulis': item['penulis_id']?['nama_lengkap'] ?? 'Admin',
        }).toList();
        return {'success': true, 'data': transformedData};
      } else {
        return _handleResponse(response);
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Update Pengumuman
  Future<Map<String, dynamic>> updatePengumuman(String id, String judul, String isi, String prioritas, String penjelasan) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/pengumuman/$id'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'judul': judul,
          'isi': isi,
          'prioritas': prioritas,
          'penjelasan': penjelasan,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Create Pengumuman
  Future<Map<String, dynamic>> createPengumuman(String judul, String isi, String prioritas, String penjelasan) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      if (userDataString == null) {
        return {'success': false, 'message': 'User tidak terautentikasi'};
      }

      final userData = jsonDecode(userDataString);
      final penulisId = userData['_id'];

      final response = await http.post(
        Uri.parse('$baseUrl/pengumuman'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'penulis_id': penulisId,
          'judul': judul,
          'isi': isi,
          'prioritas': prioritas,
          'penjelasan': penjelasan,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Delete Pengumuman
  Future<Map<String, dynamic>> deletePengumuman(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/pengumuman/$id'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // === UMKM CRUD Methods ===

  // Get UMKM (Admin)
  Future<Map<String, dynamic>> getUMKMAdmin() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/umkm'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Create UMKM
  Future<Map<String, dynamic>> createUMKM(Map<String, dynamic> umkmData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/umkm'),
        headers: await _getHeaders(),
        body: jsonEncode(umkmData),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Update UMKM
  Future<Map<String, dynamic>> updateUMKM(String id, Map<String, dynamic> umkmData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/umkm/$id'),
        headers: await _getHeaders(),
        body: jsonEncode(umkmData),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Delete UMKM
  Future<Map<String, dynamic>> deleteUMKM(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/umkm/$id'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // === WARGA CRUD Methods ===

  // Get Warga (Admin)
  Future<Map<String, dynamic>> getWargaAdmin() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/warga'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Create Warga
  Future<Map<String, dynamic>> createWarga(Map<String, dynamic> wargaData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/warga'),
        headers: await _getHeaders(),
        body: jsonEncode(wargaData),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Update Warga
  Future<Map<String, dynamic>> updateWarga(String id, Map<String, dynamic> wargaData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/warga/$id'),
        headers: await _getHeaders(),
        body: jsonEncode(wargaData),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Delete Warga
  Future<Map<String, dynamic>> deleteWarga(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/warga/$id'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }
}