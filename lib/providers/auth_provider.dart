import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'dart:convert';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _userData;

  // Admin verification states
  bool _isAdminVerification = false;
  String? _adminEmail;
  bool _isVerificationLoading = false;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get userData => _userData;

  // Admin verification getters
  bool get isAdminVerification => _isAdminVerification;
  bool get isVerificationLoading => _isVerificationLoading;

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
        print('✅ TOKEN FOUND, VERIFYING WITH SERVER...'); // DEBUG
        // Verify token with server by calling getUserProfile
        final apiService = ApiService();
        final result = await apiService.getUserProfile();
        if (result['success'] == true) {
          print('✅ TOKEN VALID'); // DEBUG
          _isAuthenticated = true;
          _userData = await _loadUserData();
          print('👤 USER DATA IN PROVIDER: $_userData'); // DEBUG
        } else {
          print('❌ TOKEN INVALID, CLEARING...'); // DEBUG
          await _clearToken();
          await _clearUserData();
          _isAuthenticated = false;
          _userData = null;
        }
      } else {
        print('❌ NO TOKEN FOUND'); // DEBUG
        _isAuthenticated = false;
        _userData = null;
      }
    } catch (e) {
      print('❌ ERROR IN checkAuthStatus: $e'); // DEBUG
      // On error (e.g., network issues), treat as not authenticated
      await _clearToken();
      await _clearUserData();
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
      final apiService = ApiService();
      final result = await apiService.login(email, password);

      print('📥 LOGIN RESPONSE: $result'); // DEBUG
      print('📥 RESPONSE KEYS: ${result.keys.toList()}'); // DEBUG

      if (result['success'] == true) {
        _isAuthenticated = true;

        // PENTING: result['data'] sudah berisi response dari backend
        // yang strukturnya: {user: {...}, token: ...}
        print('🔍 result[data]: ${result['data']}'); // DEBUG
        print('🔍 result[data] keys: ${result['data']?.keys.toList()}'); // DEBUG

        // Ambil user data dari result['data']['user']
        if (result['data'] != null && result['data']['user'] != null) {
          _userData = result['data']['user'] as Map<String, dynamic>;
          print('✅ USER DATA FOUND: $_userData'); // DEBUG
          print('🔑 USER DATA KEYS: ${_userData?.keys.toList()}'); // DEBUG

          // Cek field nama_lengkap
          print('👤 NAMA LENGKAP: ${_userData?['nama_lengkap']}'); // DEBUG

          // Cek jika user adalah ketua RT (role = 'ketua_rt')
          if (_userData?['role'] == 'ketua_rt') {
            print('👑 KETUA RT DETECTED - TRIGGERING VERIFICATION'); // DEBUG
            // Trigger admin verification
            await sendAdminVerificationCode(email);
            return true; // Return true tapi tetap authenticated untuk verifikasi
          }
        } else {
          print('❌ NO USER DATA IN RESPONSE'); // DEBUG
          _userData = null;
        }

        _errorMessage = null;

        // Simpan token dari result['data']['token']
        if (result['data'] != null && result['data']['token'] != null) {
          await _saveToken(result['data']['token']);
          print('✅ TOKEN SAVED: ${result['data']['token']}'); // DEBUG
        } else {
          print('⚠️ NO TOKEN IN RESPONSE'); // DEBUG
        }

        // Simpan user data ke SharedPreferences
        if (_userData != null) {
          await _saveUserData(_userData!);
          print('✅ USER DATA SAVED TO STORAGE'); // DEBUG
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
    _isAdminVerification = false;
    _adminEmail = null;
    _isVerificationLoading = false;
    notifyListeners();
  }

  // --- ADMIN VERIFICATION METHODS ---

  Future<bool> sendAdminVerificationCode(String email) async {
    _isVerificationLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final apiService = ApiService();
      final result = await apiService.sendAdminVerificationCode(email);

      if (result['success'] == true) {
        _adminEmail = email;
        _isAdminVerification = true;
        _errorMessage = null;
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Gagal mengirim kode verifikasi';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      return false;
    } finally {
      _isVerificationLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyAdminCode(String code) async {
    if (_adminEmail == null) return false;

    _isVerificationLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final apiService = ApiService();
      final result = await apiService.verifyAdminCode(_adminEmail!, code);

      if (result['success'] == true) {
        _isAdminVerification = false;
        _adminEmail = null;
        _errorMessage = null;
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Kode verifikasi salah';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      return false;
    } finally {
      _isVerificationLoading = false;
      notifyListeners();
    }
  }

  void cancelAdminVerification() {
    _isAdminVerification = false;
    _adminEmail = null;
    _errorMessage = null;
    notifyListeners();
  }
}
