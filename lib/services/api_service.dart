import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Use localhost for web, and 10.0.2.2 for Android emulator. Adjust for physical device if needed.
  static final String baseUrl = kIsWeb
      ? 'http://localhost:3000/api'
      : 'http://10.0.2.2:3000/api';

  // Helper untuk handle response
  // (helper _handleResponse dihapus karena tidak terpakai)

  // Get token from storage
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Save token to storage
  // (simpan token dilakukan di provider, helper ini dihapus karena tidak terpakai)

  // Clear token
  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
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
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Save user data to shared preferences for auth provider
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(data['user']));

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

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registrasi gagal',
        };
      }
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
        // Transform data to match expected format
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
        return {'success': false, 'message': 'Gagal mengambil data'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Get raw announcements (including IDs) - useful for admin management
  Future<Map<String, dynamic>> getAnnouncementsRaw() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/pengumuman'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': 'Gagal mengambil data'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Create Announcement (admin)
  Future<Map<String, dynamic>> createAnnouncement(
    Map<String, dynamic> announcement,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/pengumuman'),
        headers: await _getHeaders(),
        body: jsonEncode(announcement),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      }
      final data = jsonDecode(response.body);
      return {
        'success': false,
        'message': data['message'] ?? 'Gagal membuat pengumuman',
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Delete Announcement (admin)
  Future<Map<String, dynamic>> deleteAnnouncement(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/pengumuman/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Dihapus'};
      }
      final data = jsonDecode(response.body);
      return {
        'success': false,
        'message': data['message'] ?? 'Gagal menghapus',
      };
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
        // Transform data to match expected format
        final transformedData = data
            .map(
              (item) => {
                'title': item['judul_laporan'] ?? 'Laporan',
                'description': item['isi_laporan'] ?? '',
                'category': item['kategori_laporan'] ?? 'Lainnya',
                'status': item['status_laporan'] ?? 'Menunggu',
                'date': item['tanggal_dibuat'] != null
                    ? DateTime.parse(
                        item['tanggal_dibuat'],
                      ).toString().split(' ')[0]
                    : '',
                'author': item['pelapor_id']?['nama_lengkap'] ?? 'Anonim',
              },
            )
            .toList();
        return {'success': true, 'data': transformedData};
      } else {
        return {'success': false, 'message': 'Gagal mengambil data'};
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
      // Map friendly keys to backend keys
      final mapped = Map<String, dynamic>.from(reportData);
      final body = <String, dynamic>{};
      if (mapped.containsKey('title')) body['judul_laporan'] = mapped['title'];
      if (mapped.containsKey('description'))
        body['isi_laporan'] = mapped['description'];
      if (mapped.containsKey('category'))
        body['kategori_laporan'] = mapped['category'];

      // Try to attach pelapor_id from local storage if available
      try {
        final prefs = await SharedPreferences.getInstance();
        String? userJson =
            prefs.getString('userData') ?? prefs.getString('user_data');
        if (userJson != null) {
          final user = jsonDecode(userJson);
          if (user is Map) {
            body['pelapor_id'] = user['_id'] ?? user['id'] ?? user['userId'];
          }
        }
      } catch (e) {
        // ignore, not critical
      }

      final response = await http.post(
        Uri.parse('$baseUrl/laporan'),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': 'Gagal membuat laporan'};
      }
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
        // Transform data to match expected format
        final transformedData = data
            .map(
              (item) => {
                'title': item['judul_iuran'] ?? 'Iuran',
                'description': item['judul_iuran'] ?? 'Pembayaran iuran',
                'amount': item['jumlah'] ?? 0,
                'status': item['status_pembayaran'] ?? 'Menunggu',
                'type': item['judul_iuran'] ?? 'Iuran',
                'date': item['jatuh_tempo'] != null
                    ? DateTime.parse(
                        item['jatuh_tempo'],
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
        return {'success': false, 'message': 'Gagal mengambil data'};
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
        // Transform data to match expected format
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
        return {'success': false, 'message': 'Gagal mengambil data'};
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
        // Transform data to match expected format
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
        return {'success': false, 'message': 'Gagal mengambil data'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Get Users (raw)
  Future<Map<String, dynamic>> getUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': 'Gagal mengambil data pengguna'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Get raw reports (include IDs and original fields) - for admin
  Future<Map<String, dynamic>> getReportsRaw() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/laporan'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': 'Gagal mengambil data laporan'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Update report status (admin)
  Future<Map<String, dynamic>> updateReportStatus(
    String id,
    String status,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/laporan/$id'),
        headers: await _getHeaders(),
        body: jsonEncode({'status_laporan': status}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      }
      final data = jsonDecode(response.body);
      return {
        'success': false,
        'message': data['message'] ?? 'Gagal memperbarui laporan',
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }
}
