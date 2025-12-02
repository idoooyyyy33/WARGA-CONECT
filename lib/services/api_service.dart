import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // --- PERHATIAN: Menggunakan IP untuk akses otomatis ---
  // Untuk emulator Android gunakan 192.168.1.26, untuk iOS simulator gunakan localhost
  static const String baseUrl = 'http://192.168.1.26:3000/api';

  // Helper untuk handle response
  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': data};
      } else {
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
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      if (e is FormatException && response.body.contains('<!DOCTYPE')) {
        return {
          'success': false,
          'message':
              'Error: Server mengirimkan HTML, bukan JSON. Cek URL API atau log server. (Status: ${response.statusCode})',
        };
      }
      return {'success': false, 'message': 'Gagal memproses data: $e'};
    }
  }

  // Get token from storage
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
// DEBUG METHOD - Tambahkan di class ApiService
Future<String?> getTokenDebug() async {
  final token = await _getToken();
  debugPrint('🔍 Debug Token: $token');
  return token;
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

 // Login - PERBAIKAN
Future<Map<String, dynamic>> login(String email, String password) async {
  try {
    debugPrint('📤 Login Request: $email');
    
    final response = await http.post(
      Uri.parse('$baseUrl/users/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    debugPrint('📥 Login Response Status: ${response.statusCode}');
    debugPrint('   Body: ${response.body}');

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      debugPrint('✅ Login Success');
      
      // Simpan user data ke SharedPreferences
      if (data['user'] != null) {
        final prefs = await SharedPreferences.getInstance();
        final userDataString = jsonEncode(data['user']);
        await prefs.setString('user_data', userDataString);
        debugPrint('💾 User data saved: ${data['user']['email']}');
        debugPrint('   Role: ${data['user']['role']}');
      }

      // Simpan token sebagai user ID
      if (data['user'] != null && data['user']['_id'] != null) {
        final userId = data['user']['_id'];
        await _saveToken(userId);
        debugPrint('🔑 Token saved: $userId');
        
        // VERIFY token tersimpan
        final savedToken = await _getToken();
        debugPrint('✅ Verified saved token: $savedToken');
      } else {
        debugPrint('⚠️ WARNING: User ID not found in response!');
      }

      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'message': data['message'] ?? 'Login gagal'};
    }
  } catch (e, stack) {
    debugPrint('❌ Login Error: $e');
    debugPrint('Stack: $stack');
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
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Logout
  Future<void> logout() async {
    await _clearToken();
  }

  // Get User Profile
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/profile'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Get User Data from storage
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      if (userDataString != null) {
        return jsonDecode(userDataString);
      }
      return null;
    } catch (e) {
      return null;
    }
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
        final transformedData = data
            .map(
              (item) => {
                'title': item['judul'] ?? 'Pengumuman',
                'description': item['isi'] ?? '',
                'date': item['tanggal_dibuat'] != null
                    ? DateTime.parse(
                        item['tanggal_dibuat'],
                      ).toString().split(' ')[0]
                    : '',
                'author': item['penulis_id']?['nama_lengkap'] ?? 'Admin',
              },
            )
            .toList();
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

        // Debug: Print raw API response
        debugPrint('DEBUG API: Raw response data: $data');

        final transformedData = data
            .map(
              (item) => {
                'id': item['_id'],
                'title': item['judul_laporan'] ?? item['judul'] ?? 'Laporan',
                'description': item['isi_laporan'] ?? item['deskripsi'] ?? '',
                'category':
                    item['kategori_laporan'] ?? item['kategori'] ?? 'Lainnya',
                'status':
                    item['status_laporan'] ?? item['status'] ?? 'Diterima',
                'date': item['createdAt'] != null
                    ? DateTime.parse(item['createdAt']).toString().split('T')[0]
                    : '',
                'author': item['pelapor_id']?['nama_lengkap'] ?? 'Anonim',
              },
            )
            .toList();

        // Debug: Print transformed data
        debugPrint('DEBUG API: Transformed ${transformedData.length} reports');
        if (transformedData.isNotEmpty) {
          debugPrint(
            'DEBUG API: First report - Title: ${transformedData[0]['title']}, Status: ${transformedData[0]['status']}, Author: ${transformedData[0]['author']}',
          );
        }

        return {'success': true, 'data': transformedData};
      } else {
        return _handleResponse(response);
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Create Report
  Future<Map<String, dynamic>> createReport(
    Map<String, dynamic> reportData,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      if (userDataString == null) {
        return {
          'success': false,
          'message': 'User tidak terautentikasi. Silakan login ulang.',
        };
      }
      final userData = jsonDecode(userDataString);
      final pelaporId = userData['_id'];

      reportData['pelapor_id'] = pelaporId;

      final response = await http.post(
        Uri.parse('$baseUrl/laporan'),
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
        Uri.parse('$baseUrl/iuran'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final transformedData = data
            .map(
              (item) => {
                'id': item['_id'],
                'title': item['judul'] ?? 'Iuran',
                'description': item['judul'] ?? 'Pembayaran iuran',
                'amount': item['jumlah'] ?? 0,
                'status': item['status_pembayaran'] ?? 'Menunggu',
                'type': item['kategori'] ?? 'Iuran',
                'date': item['tanggal_tenggat'] != null
                    ? DateTime.parse(
                        item['tanggal_tenggat'],
                      ).toString().split(' ')[0]
                    : '',
                'periode': item['periode'] != null
                    ? '${item['periode']['bulan']}/${item['periode']['tahun']}'
                    : '',
              },
            )
            .toList();
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
        final transformedData = data
            .map(
              (item) => {
                'title': item['nama_kegiatan'] ?? 'Kegiatan',
                'description': item['deskripsi'] ?? '',
                'date': item['tanggal_mulai'] != null
                    ? DateTime.parse(
                        item['tanggal_mulai'],
                      ).toString().split(' ')[0]
                    : '',
                'location': item['lokasi'] ?? 'Lokasi belum ditentukan',
                'fullDescription': item['deskripsi'] ?? '',
              },
            )
            .toList();
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
        final transformedData = data
            .map(
              (item) => {
                'name': item['nama_usaha'] ?? 'UMKM',
                'title': item['nama_usaha'] ?? 'UMKM',
                'category': item['kategori_usaha'] ?? 'Lainnya',
                'description': item['deskripsi_usaha'] ?? '',
                'owner': item['pemilik_id']?['nama_lengkap'] ?? 'Anonim',
                'phone': item['kontak']?['telepon'] ?? '',
                'address': item['lokasi'] ?? '',
              },
            )
            .toList();
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

  Future<Map<String, dynamic>> verifyAdminCode(
    String email,
    String code,
  ) async {
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

      debugPrint('📊 Admin Stats Response Status: ${response.statusCode}');
      debugPrint('📊 Admin Stats Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Backend returns flat object: {totalWarga, totalLaporan, totalLaporanPending, ...}
        // Tidak ada wrapper success/data
        debugPrint('📊 Stats data: $data');
        debugPrint('📊 totalLaporanPending: ${data['totalLaporanPending']}');

        return {'success': true, 'data': data};
      } else {
        return _handleResponse(response);
      }
    } catch (e) {
      debugPrint('❌ Error in getAdminStats: $e');
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
        Uri.parse('$baseUrl/laporan'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final transformedData = data
            .map(
              (item) => {
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
              },
            )
            .toList();
        return {'success': true, 'data': transformedData};
      } else {
        return _handleResponse(response);
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Update Status Laporan
  Future<Map<String, dynamic>> updateStatusLaporan(
    String id,
    String status,
    String tanggapan,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/laporan/$id'),
        headers: await _getHeaders(),
        body: jsonEncode({'status_laporan': status, 'tanggapan': tanggapan}),
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
        Uri.parse('$baseUrl/laporan/$id'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // ==================== IURAN METHODS (FIXED) ====================

  // Get Iuran (Admin) - FIXED
  Future<Map<String, dynamic>> getIuran({int? bulan, int? tahun}) async {
    try {
      final Map<String, String> queryParams = {};
      if (bulan != null) {
        queryParams['bulan'] = bulan.toString();
      }
      if (tahun != null) {
        queryParams['tahun'] = tahun.toString();
      }

      final uri = Uri.parse(
        '$baseUrl/admin/iuran',
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      debugPrint('🔍 Fetching iuran from: $uri');

      final response = await http.get(uri, headers: await _getHeaders());

      debugPrint('📡 Response Status: ${response.statusCode}');
      debugPrint('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final rawData = jsonDecode(response.body);

        if (rawData is! List) {
          debugPrint('❌ ERROR: Response bukan List');
          return {
            'success': false,
            'message': 'Format data tidak valid dari server',
            'data': [],
          };
        }

        final List<Map<String, dynamic>> transformedData = [];

        for (var item in rawData) {
          try {
            debugPrint('📄 Processing: ${item['_id']}');
            debugPrint('   Warga: ${item['warga_id']?['nama_lengkap']}');
            debugPrint('   Status: ${item['status_pembayaran']}');
            debugPrint('   Jumlah: ${item['jumlah']}');
            debugPrint('   Bukti: ${item['bukti_pembayaran']}');

            transformedData.add({
              'id': item['_id']?.toString() ?? '',
              'warga_id': item['warga_id']?['_id']?.toString() ?? '',
              'nama_warga':
                  item['warga_id']?['nama_lengkap']?.toString() ??
                  'Tidak Diketahui',
              'jenis_iuran': item['jenis_iuran']?.toString() ?? 'Iuran RT',
              'nominal': (item['jumlah'] is int)
                  ? item['jumlah']
                  : int.tryParse(item['jumlah']?.toString() ?? '0') ?? 0,
              'status': item['status_pembayaran']?.toString() ?? 'Belum Lunas',
              'tanggal_bayar': item['tanggal_bayar']?.toString(),
              'metode_pembayaran': item['metode_pembayaran']?.toString() ?? '-',
              'bukti_pembayaran': item['bukti_pembayaran']?.toString(),
              'periode_bulan':
                  item['periode']?['bulan']?.toString() ??
                  item['periode_bulan']?.toString() ??
                  '',
              'periode_tahun':
                  item['periode']?['tahun'] ?? item['periode_tahun'] ?? 0,
            });
          } catch (e) {
            debugPrint('⚠️ Error processing item: $e');
            continue;
          }
        }

        debugPrint('✅ Transformed ${transformedData.length} items');
        return {'success': true, 'data': transformedData};
      } else {
        debugPrint('❌ Error Response: ${response.body}');
        return _handleResponse(response);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Exception in getIuran: $e');
      debugPrint('Stack: $stackTrace');
      return {'success': false, 'message': 'Terjadi kesalahan: $e', 'data': []};
    }
  }

  // Get Warga - FIXED
  Future<Map<String, dynamic>> getWarga() async {
    try {
      debugPrint('🔍 Fetching warga list...');

      final response = await http.get(
        Uri.parse('$baseUrl/admin/warga'),
        headers: await _getHeaders(),
      );

      debugPrint('📡 Warga Response Status: ${response.statusCode}');
      debugPrint('📦 Warga Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is! List) {
          return {
            'success': false,
            'message': 'Format data warga tidak valid',
            'data': [],
          };
        }

        debugPrint('✅ Warga count: ${data.length}');
        return {'success': true, 'data': data};
      } else {
        return _handleResponse(response);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error in getWarga: $e');
      debugPrint('Stack: $stackTrace');
      return {'success': false, 'message': 'Terjadi kesalahan: $e', 'data': []};
    }
  }

  // Bayar Iuran - FIXED
  Future<Map<String, dynamic>> bayarIuran(
    String wargaId,
    int nominal,
    String bulan,
    int tahun,
    String metodePembayaran,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');

      if (userDataString == null) {
        return {
          'success': false,
          'message': 'Admin tidak terautentikasi. Silakan login ulang.',
        };
      }

      final userData = jsonDecode(userDataString);
      final pembuatId = userData['_id'];

      final requestBody = {
        'warga_id': wargaId,
        'pembuat_id': pembuatId,
        'jenis_iuran': 'Iuran RT',
        'jumlah': nominal,
        'periode_bulan': bulan,
        'periode_tahun': tahun,
        'metode_pembayaran': metodePembayaran,
        'status_pembayaran': 'Lunas',
        'tanggal_bayar': DateTime.now().toIso8601String(),
      };

      debugPrint('📤 Bayar Iuran Request: $requestBody');

      final response = await http.post(
        Uri.parse('$baseUrl/admin/iuran'),
        headers: await _getHeaders(),
        body: jsonEncode(requestBody),
      );

      debugPrint(
        '📥 Bayar Iuran Response (${response.statusCode}): ${response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return _handleResponse(response);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error bayar iuran: $e');
      debugPrint('Stack: $stackTrace');
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Delete Iuran - FIXED
  Future<Map<String, dynamic>> deleteIuran(String id) async {
    try {
      debugPrint('🗑️ Deleting iuran: $id');

      final response = await http.delete(
        Uri.parse('$baseUrl/admin/iuran/$id'),
        headers: await _getHeaders(),
      );

      debugPrint(
        '📥 Delete Response (${response.statusCode}): ${response.body}',
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Data berhasil dihapus'};
      } else {
        return _handleResponse(response);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error delete iuran: $e');
      debugPrint('Stack: $stackTrace');
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Upload Payment Proof - FIXED
  Future<Map<String, dynamic>> uploadPaymentProof(
    String iuranId,
    Uint8List imageBytes,
    String fileName,
  ) async {
    try {
      debugPrint('📤 Uploading payment proof for iuran: $iuranId');

      final uri = Uri.parse('$baseUrl/iuran/$iuranId/upload-proof');
      final request = http.MultipartRequest('PUT', uri);

      final token = await _getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'bukti_pembayaran',
          imageBytes,
          filename: fileName,
        ),
      );

      debugPrint('📤 Uploading file: $fileName (${imageBytes.length} bytes)');

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      debugPrint('📥 Upload Response (${response.statusCode}): $responseBody');

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(responseBody);
        return {'success': true, 'data': decodedData};
      } else {
        final decodedData = jsonDecode(responseBody);
        return {
          'success': false,
          'message': decodedData['message'] ?? 'Gagal upload bukti',
        };
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error upload payment proof: $e');
      debugPrint('Stack: $stackTrace');
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Update Iuran Status - FIXED
  Future<Map<String, dynamic>> updateIuranStatus(
    String iuranId,
    String status,
  ) async {
    try {
      debugPrint('🔄 Updating iuran $iuranId to status: $status');

      final requestBody = {'status_pembayaran': status};

      if (status == 'Lunas') {
        requestBody['tanggal_bayar'] = DateTime.now().toIso8601String();
      }

      debugPrint('📤 Update Status Request: $requestBody');

      final response = await http.put(
        Uri.parse('$baseUrl/admin/iuran/$iuranId'),
        headers: await _getHeaders(),
        body: jsonEncode(requestBody),
      );

      debugPrint(
        '📥 Update Status Response (${response.statusCode}): ${response.body}',
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return _handleResponse(response);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error update status: $e');
      debugPrint('Stack: $stackTrace');
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Update Iuran Info - FIXED
  Future<Map<String, dynamic>> updateIuranInfo(
    String iuranId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      debugPrint('✏️ Updating iuran info: $iuranId');
      debugPrint('📤 Update Data: $updateData');

      final requestBody = {
        if (updateData.containsKey('jenis_iuran'))
          'jenis_iuran': updateData['jenis_iuran'],
        if (updateData.containsKey('jumlah')) 'jumlah': updateData['jumlah'],
        if (updateData.containsKey('periode_bulan'))
          'periode_bulan': updateData['periode_bulan'],
        if (updateData.containsKey('periode_tahun'))
          'periode_tahun': updateData['periode_tahun'],
      };

      final response = await http.put(
        Uri.parse('$baseUrl/admin/iuran/$iuranId'),
        headers: await _getHeaders(),
        body: jsonEncode(requestBody),
      );

      debugPrint(
        '📥 Update Info Response (${response.statusCode}): ${response.body}',
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return _handleResponse(response);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error update iuran info: $e');
      debugPrint('Stack: $stackTrace');
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // ==================== END IURAN METHODS ====================

  // Get Kegiatan (Admin)
  Future<Map<String, dynamic>> getKegiatan() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/kegiatan'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final transformedData = data
            .map(
              (item) => {
                'id': item['_id'],
                'nama_kegiatan': item['nama_kegiatan'] ?? 'Kegiatan',
                'deskripsi': item['deskripsi'] ?? '',
                'tanggal_mulai': item['tanggal_kegiatan'] != null
                    ? DateTime.parse(
                        item['tanggal_kegiatan'],
                      ).toString().split(' ')[0]
                    : '',
                'lokasi': item['lokasi'] ?? '',
                'penanggung_jawab':
                    item['penanggung_jawab_id']?['nama_lengkap'] ?? 'Admin',
              },
            )
            .toList();
        return {'success': true, 'data': transformedData};
      } else {
        return _handleResponse(response);
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Update Kegiatan
  Future<Map<String, dynamic>> updateKegiatan(
    String id,
    String nama,
    String deskripsi,
    String tanggal,
    String waktu,
    String lokasi,
    String kategori,
    String penyelenggara,
  ) async {
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
  Future<Map<String, dynamic>> createKegiatan(
    String nama,
    String deskripsi,
    String tanggal,
    String waktu,
    String lokasi,
    String kategori,
    String penyelenggara,
  ) async {
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
        final transformedData = data
            .map(
              (item) => {
                'id': item['_id'],
                'judul': item['judul'] ?? 'Pengumuman',
                'isi': item['isi'] ?? '',
                'penjelasan': item['penjelasan'] ?? '',
                'prioritas': item['prioritas'] ?? 'normal',
                'tanggal': item['createdAt'] != null
                    ? DateTime.parse(item['createdAt']).toString()
                    : '',
                'penulis': item['penulis_id']?['nama_lengkap'] ?? 'Admin',
              },
            )
            .toList();
        return {'success': true, 'data': transformedData};
      } else {
        return _handleResponse(response);
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Update Pengumuman
  Future<Map<String, dynamic>> updatePengumuman(
    String id,
    String judul,
    String isi,
    String prioritas,
    String penjelasan,
  ) async {
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
  Future<Map<String, dynamic>> createPengumuman(
    String judul,
    String isi,
    String prioritas,
    String penjelasan,
  ) async {
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
  Future<Map<String, dynamic>> updateUMKM(
    String id,
    Map<String, dynamic> umkmData,
  ) async {
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
  Future<Map<String, dynamic>> createWarga(
    Map<String, dynamic> wargaData,
  ) async {
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
  Future<Map<String, dynamic>> updateWarga(
    String id,
    Map<String, dynamic> wargaData,
  ) async {
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

  // Create Mass Iuran - FIXED
  Future<Map<String, dynamic>> createMassIuran(
    Map<String, dynamic> iuranData,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');

      if (userDataString == null) {
        return {'success': false, 'message': 'Admin tidak terautentikasi'};
      }

      final userData = jsonDecode(userDataString);

      final requestBody = {
        'pembuat_id': userData['_id'],
        'judul_iuran': iuranData['judul_iuran'],
        'jenis_iuran': iuranData['jenis_iuran'],
        'jumlah': iuranData['jumlah'],
        'periode': {
          'bulan': iuranData['periode_bulan'],
          'tahun': iuranData['periode_tahun'],
        },
        'jatuh_tempo': iuranData['jatuh_tempo'],
      };

      debugPrint('📤 Create Mass Iuran Request: $requestBody');

      final response = await http.post(
        Uri.parse('$baseUrl/admin/iuran/massal'),
        headers: await _getHeaders(),
        body: jsonEncode(requestBody),
      );

      debugPrint(
        '📥 Create Mass Iuran Response (${response.statusCode}): ${response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return _handleResponse(response);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error create mass iuran: $e');
      debugPrint('Stack: $stackTrace');
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Get Mass Iuran Info (templates/information)
  Future<Map<String, dynamic>> getMassIuranInfo() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/iuran/massal'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Update Mass Iuran Info
  Future<Map<String, dynamic>> updateMassIuranInfo(
    String id,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/iuran/massal/$id'),
        headers: await _getHeaders(),
        body: jsonEncode(updateData),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Delete Mass Iuran Info
  Future<Map<String, dynamic>> deleteMassIuranInfo(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/iuran/massal/$id'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

 // ==================== SURAT PENGANTAR METHODS ====================

  // 1. Get Surat Pengantar (User - melihat pengajuannya sendiri)
  Future<Map<String, dynamic>> getSuratPengantar() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/surat-pengantar'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Pastikan data adalah List
        List<dynamic> listData = [];
        if (data is List) {
          listData = data;
        } else if (data is Map && data['data'] is List) {
          listData = data['data'];
        }

        final transformedData = listData.map((item) {
          return {
            'id': item['_id'], // Mapping _id ke id
            'jenis_surat': item['jenis_surat'] ?? 'Tidak diketahui',
            'keperluan': item['keperluan'] ?? '',
            'keterangan': item['keterangan'] ?? '',
            'status_pengajuan': item['status_pengajuan'] ?? 'Diajukan',
            'tanggapan_admin': item['tanggapan_admin'] ?? '',
            'file_surat': item['file_surat'] ?? '',
            'tanggal_pengajuan': item['createdAt'] != null
                ? DateTime.parse(item['createdAt']).toString().split(' ')[0]
                : '',
            // Safe access untuk user side
            'nama_pengaju': (item['pengaju_id'] is Map) 
                ? (item['pengaju_id']['nama_lengkap'] ?? 'Saya') 
                : 'Saya',
          };
        }).toList();

        return {'success': true, 'data': transformedData};
      } else {
        return _handleResponse(response);
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // 2. Create Surat Pengantar (User)
  Future<Map<String, dynamic>> createSuratPengantar(
    Map<String, dynamic> suratData, {
    List<http.MultipartFile>? files,
  }) async {
    try {
      final token = await _getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/surat-pengantar'),
      );

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add text fields
      suratData.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      // Add files if provided
      if (files != null) {
        request.files.addAll(files);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      debugPrint('❌ Error in createSuratPengantar: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // 3. Get Surat Pengantar Admin (Admin - melihat semua pengajuan)
  // PERBAIKAN UTAMA ADA DI SINI AGAR TIDAK CRASH
  Future<Map<String, dynamic>> getSuratPengantarAdmin() async {
    try {
      debugPrint('🔍 Fetching Surat Pengantar Admin...');
      final headers = await _getHeaders();
      
      final response = await http.get(
        Uri.parse('$baseUrl/surat-pengantar/admin'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);

        // 1. Ambil List data dengan aman
        final List<dynamic> rawList = responseBody is Map
            ? (responseBody['data'] is List ? responseBody['data'] : [])
            : (responseBody is List ? responseBody : []);

        // 2. Transformasi Data (Mapping)
        final transformedData = rawList.map((item) {
          
          // --- LOGIKA ANTI CRASH UNTUK NAMA PENGAJU ---
          String namaPengaju = 'Anonim';
          String emailPengaju = '-';

          // Cek apakah pengaju_id itu Object (Map) atau cuma String ID atau Null
          if (item['pengaju_id'] != null && item['pengaju_id'] is Map) {
            namaPengaju = item['pengaju_id']['nama_lengkap'] ?? 'Anonim';
            emailPengaju = item['pengaju_id']['email'] ?? '-';
          } 
          // --------------------------------------------

          return {
            'id': item['_id'], // PENTING: Ubah _id jadi id
            'jenis_surat': item['jenis_surat'] ?? 'Tidak diketahui',
            'keperluan': item['keperluan'] ?? '-',
            'keterangan': item['keterangan'] ?? '-',
            'status_pengajuan': item['status_pengajuan'] ?? 'Diajukan',
            'tanggapan_admin': item['tanggapan_admin'] ?? '',
            'file_surat': item['file_surat'] ?? '',
            'tanggal_pengajuan': item['createdAt'] != null
                ? DateTime.parse(item['createdAt']).toString().split(' ')[0]
                : '-',
            'nama_pengaju': namaPengaju, // Pakai variabel yang sudah diamankan
            'email_pengaju': emailPengaju,
          };
        }).toList();

        return {'success': true, 'data': transformedData};
      } else {
        return _handleResponse(response);
      }
    } catch (e) {
      debugPrint('❌ Exception in getSuratPengantarAdmin: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // 4. Update Status Surat Pengantar (Admin)
  Future<Map<String, dynamic>> updateStatusSuratPengantar(
    String id,
    String status,
    String tanggapan,
    String? fileUrl,
  ) async {
    try {
      final requestBody = {
        'status_pengajuan': status,
        'tanggapan_admin': tanggapan,
      };

      if (fileUrl != null && fileUrl.isNotEmpty) {
        requestBody['file_surat'] = fileUrl;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/surat-pengantar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode(requestBody),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // 5. Delete Surat Pengantar
  Future<Map<String, dynamic>> deleteSuratPengantar(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/surat-pengantar/$id'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }
}