import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _userData;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get userData => _userData;

  // --- HELPER UNTUK USER DATA ---

  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    print('💾 SAVING USER DATA: $userData'); // DEBUG
    final prefs = await SharedPreferences.getInstance();
    String userString = jsonEncode(userData);
    await prefs.setString('userData', userString);
    print('✅ USER DATA SAVED TO SHARED PREFERENCES'); // DEBUG
  }

  Future<Map<String, dynamic>?> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    String? userString = prefs.getString('userData');
    if (userString != null) {
      final data = jsonDecode(userString) as Map<String, dynamic>;
      print('📂 LOADED USER DATA FROM STORAGE: $data'); // DEBUG
      return data;
    }
    print('⚠️ NO USER DATA IN STORAGE'); // DEBUG
    return null;
  }

  Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userData');
    print('🗑️ USER DATA CLEARED'); // DEBUG
  }

  // --- HELPER UNTUK TOKEN ---

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // --- FUNGSI UTAMA ---

  Future<bool> checkAuthStatus() async {
    print('🔐 CHECKING AUTH STATUS...'); // DEBUG
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token != null) {
        print('✅ TOKEN FOUND'); // DEBUG
        _isAuthenticated = true;
        _userData = await _loadUserData();
        print('👤 USER DATA IN PROVIDER: $_userData'); // DEBUG
      } else {
        print('❌ NO TOKEN FOUND'); // DEBUG
        _isAuthenticated = false;
        _userData = null;
      }
    } catch (e) {
      print('❌ ERROR IN checkAuthStatus: $e'); // DEBUG
      _isAuthenticated = false;
      _userData = null;
      _errorMessage = 'Error checking auth status: $e';
    }

    _isLoading = false;
    notifyListeners();
    return _isAuthenticated;
  }

  Future<bool> login(String email, String password) async {
    print('🔑 ATTEMPTING LOGIN...'); // DEBUG
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Selalu lakukan login via API (hapus bypass admin lokal)
      final apiService = ApiService();
      final result = await apiService.login(email, password);

      // Login response

      if (result['success'] == true) {
        _isAuthenticated = true;

        // PENTING: result['data'] sudah berisi response dari backend
        // yang strukturnya: {user: {...}, token: ...}
        // Ambil user data dari result['data']['user']
        if (result['data'] != null && result['data']['user'] != null) {
          _userData = result['data']['user'] as Map<String, dynamic>;
          // USER DATA ditemukan
        } else {
          // Tidak ada user data di response
          _userData = null;
        }

        _errorMessage = null;

        // Simpan token dari result['data']['token']
        if (result['data'] != null && result['data']['token'] != null) {
          await _saveToken(result['data']['token']);
          // Token (jika ada) disimpan
        } else {
          print('⚠️ NO TOKEN IN RESPONSE'); // DEBUG
        }

        // Simpan user data ke SharedPreferences
        if (_userData != null) {
          await _saveUserData(_userData!);
        } else {
          print('⚠️ NO USER DATA TO SAVE'); // DEBUG
        }
      } else {
        print('❌ LOGIN FAILED: ${result['message']}'); // DEBUG
        _isAuthenticated = false;
        _errorMessage = result['message'] ?? 'Login gagal';
      }
    } catch (e) {
      print('❌ LOGIN ERROR: $e'); // DEBUG
      print('❌ ERROR STACK: ${StackTrace.current}'); // DEBUG
      _isAuthenticated = false;
      _errorMessage = 'Terjadi kesalahan: $e';
    }

    _isLoading = false;
    notifyListeners();
    return _isAuthenticated;
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final apiService = ApiService();
      final result = await apiService.register(userData);

      if (result['success']) {
        _errorMessage = null;
      } else {
        _errorMessage = result['message'] ?? 'Registrasi gagal';
      }

      _isLoading = false;
      notifyListeners();
      return result['success'];
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Terjadi kesalahan: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _clearToken();
    await _clearUserData();
    _isAuthenticated = false;
    _userData = null;
    _errorMessage = null;
    notifyListeners();
  }
}
