import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AnnouncementProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<dynamic> _announcements = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<dynamic> get announcements => _announcements;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Fetch semua pengumuman dari backend (tanpa limit) agar sesuai dengan admin
  Future<void> fetchAnnouncements({int limit = 0}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Kirim limit = 0 untuk ambil semua pengumuman dari backend
      final result = await _apiService.getAnnouncements(limit: limit);

      if (result['success']) {
        _announcements = result['data'] is List ? result['data'] : [];
        _errorMessage = null;
      } else {
        _errorMessage = result['message'] ?? 'Gagal mengambil data pengumuman';
        _announcements = [];
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      _announcements = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Return semua announcements yang sudah di-fetch (sudah diurutkan dari backend)
  // Tidak ada batasan - kembalikan sesuai jumlah dari database
  List<dynamic> getLatestAnnouncements({int limit = 0}) {
    if (limit <= 0) {
      return _announcements; // Return semua
    }
    if (_announcements.length <= limit) {
      return _announcements;
    }
    return _announcements.take(limit).toList();
  }
}
