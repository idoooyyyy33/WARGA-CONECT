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

  Future<void> fetchAnnouncements() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.getAnnouncements();

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

  List<dynamic> getLatestAnnouncements({int limit = 5}) {
    if (_announcements.length <= limit) {
      return _announcements;
    }
    return _announcements.take(limit).toList();
  }
}
