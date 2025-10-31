import 'package:flutter/material.dart';

import '../services/api_service.dart';

class ActivityProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<dynamic> _activities = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<dynamic> get activities => _activities;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchActivities() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.getActivities();

      if (result['success']) {
        _activities = result['data'] is List ? result['data'] : [];
        _errorMessage = null;
      } else {
        _errorMessage = result['message'] ?? 'Gagal mengambil data kegiatan';
        _activities = [];
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      _activities = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  List<dynamic> getLatestActivities({int limit = 5}) {
    if (_activities.length <= limit) {
      return _activities;
    }
    return _activities.take(limit).toList();
  }
}
