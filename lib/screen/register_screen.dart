import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

// ignore_for_file: use_build_context_synchronously

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nikController = TextEditingController();
  final _kkController = TextEditingController();
  final _nameController = TextEditingController();
  final _rtController = TextEditingController();
  final _rwController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  int _currentStep = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nikController.dispose();
    _kkController.dispose();
    _nameController.dispose();
    _rtController.dispose();
    _rwController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateNIK(String? value) {
    if (value == null || value.isEmpty) {
      return 'NIK tidak boleh kosong';
    }
    if (value.length != 16) {
      return 'NIK harus 16 digit';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'NIK harus berupa angka';
    }
    return null;
  }

  String? _validateKK(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nomor KK tidak boleh kosong';
    }
    if (value.length != 16) {
      return 'Nomor KK harus 16 digit';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Nomor KK harus berupa angka';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nomor HP tidak boleh kosong';
    }
    if (!RegExp(r'^[0-9]{10,13}$').hasMatch(value)) {
      return 'Nomor HP tidak valid';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email tidak boleh kosong';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Format email tidak valid';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (value.length < 8) {
      return 'Password minimal 8 karakter';
    }
    if (!RegExp(r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$').hasMatch(value)) {
      return 'Password harus mengandung huruf besar, kecil, angka & simbol';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password tidak boleh kosong';
    }
    if (value != _passwordController.text) {
      return 'Password tidak sama';
    }
    return null;
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _nikController.text.isNotEmpty &&
            _kkController.text.isNotEmpty &&
            _nameController.text.isNotEmpty &&
            _validateNIK(_nikController.text) == null &&
            _validateKK(_kkController.text) == null;
      case 1:
        return _rtController.text.isNotEmpty &&
            _rwController.text.isNotEmpty &&
            _phoneController.text.isNotEmpty &&
            _validatePhone(_phoneController.text) == null;
      case 2:
        return _emailController.text.isNotEmpty &&
            _passwordController.text.isNotEmpty &&
            _confirmPasswordController.text.isNotEmpty &&
            _validateEmail(_emailController.text) == null &&
            _validatePassword(_passwordController.text) == null &&
            _validateConfirmPassword(_confirmPasswordController.text) == null;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      setState(() {
        if (_currentStep < 2) {
          _currentStep++;
          _animationController.reset();
          _animationController.forward();
        }
      });
    } else {
      _formKey.currentState!.validate();
    }
  }

  void _previousStep() {
    setState(() {
      if (_currentStep > 0) {
        _currentStep--;
        _animationController.reset();
        _animationController.forward();
      }
    });
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final userData = {
        'nik': _nikController.text.trim(),
        'no_kk': _kkController.text.trim(),
        'nama_lengkap': _nameController.text.trim(),
        'rt': _rtController.text.trim(),
        'rw': _rwController.text.trim(),
        'no_hp': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
      };

      final success = await authProvider.register(userData);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Registrasi berhasil! Silakan login dengan akun Anda.'),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(authProvider.errorMessage ?? 'Registrasi gagal'),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          _buildStepCircle(0, 'Data Diri'),
          _buildStepLine(0),
          _buildStepCircle(1, 'Alamat'),
          _buildStepLine(1),
          _buildStepCircle(2, 'Akun'),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;

    return Expanded(
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Theme.of(context).primaryColor : Colors.grey.shade300,
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: isActive
                  ? Icon(
                      step < _currentStep ? Icons.check : Icons.circle,
                      color: Colors.white,
                      size: step < _currentStep ? 24 : 12,
                    )
                  : Text(
                      '${step + 1}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Theme.of(context).primaryColor : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int step) {
    final isActive = _currentStep > step;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 32),
        decoration: BoxDecoration(
          color: isActive ? Theme.of(context).primaryColor : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
    String? helperText,
    int? maxLength,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          helperMaxLines: 2,
          prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red.shade400),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        keyboardType: keyboardType,
        validator: validator,
        obscureText: obscureText,
        enabled: !_isLoading,
        maxLength: maxLength,
      ),
    );
  }

  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Data Identitas',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Masukkan data sesuai KTP dan KK Anda',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 32),
        _buildTextField(
          controller: _nikController,
          label: 'NIK',
          icon: Icons.badge_outlined,
          keyboardType: TextInputType.number,
          validator: _validateNIK,
          helperText: 'Nomor Induk Kependudukan (16 digit)',
          maxLength: 16,
        ),
        _buildTextField(
          controller: _kkController,
          label: 'Nomor Kartu Keluarga',
          icon: Icons.family_restroom,
          keyboardType: TextInputType.number,
          validator: _validateKK,
          helperText: 'Nomor KK (16 digit)',
          maxLength: 16,
        ),
        _buildTextField(
          controller: _nameController,
          label: 'Nama Lengkap',
          icon: Icons.person_outline,
          validator: (value) => value?.isEmpty == true ? 'Nama tidak boleh kosong' : null,
          helperText: 'Nama sesuai KTP',
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Alamat & Kontak',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Informasi tempat tinggal dan kontak Anda',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _rtController,
                label: 'RT',
                icon: Icons.home_outlined,
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty == true ? 'RT tidak boleh kosong' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _rwController,
                label: 'RW',
                icon: Icons.location_city_outlined,
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty == true ? 'RW tidak boleh kosong' : null,
              ),
            ),
          ],
        ),
        _buildTextField(
          controller: _phoneController,
          label: 'Nomor HP',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: _validatePhone,
          helperText: 'Contoh: 081234567890',
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Buat Akun',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Buat email dan password untuk login',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 32),
        _buildTextField(
          controller: _emailController,
          label: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: _validateEmail,
          helperText: 'Email akan digunakan untuk login',
        ),
        _buildTextField(
          controller: _passwordController,
          label: 'Password',
          icon: Icons.lock_outline,
          obscureText: _obscurePassword,
          validator: _validatePassword,
          helperText: 'Min 8 karakter, huruf besar, kecil, angka & simbol',
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: Colors.grey.shade600,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
        ),
        _buildTextField(
          controller: _confirmPasswordController,
          label: 'Konfirmasi Password',
          icon: Icons.lock_outline,
          obscureText: _obscureConfirmPassword,
          validator: _validateConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: Colors.grey.shade600,
            ),
            onPressed: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Registrasi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildStepIndicator(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          if (_currentStep == 0) _buildStep0(),
                          if (_currentStep == 1) _buildStep1(),
                          if (_currentStep == 2) _buildStep2(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_currentStep < 2)
                    Row(
                      children: [
                        if (_currentStep > 0)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : _previousStep,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(color: Theme.of(context).primaryColor),
                              ),
                              child: const Text(
                                'Kembali',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        if (_currentStep > 0) const SizedBox(width: 16),
                        Expanded(
                          flex: _currentStep == 0 ? 1 : 2,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _nextStep,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Lanjut',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (_currentStep == 2) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _previousStep,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: Theme.of(context).primaryColor),
                            ),
                            child: const Text(
                              'Kembali',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Daftar',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (!_isLoading)
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: RichText(
                        text: TextSpan(
                          text: 'Sudah punya akun? ',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                          children: [
                            TextSpan(
                              text: 'Login',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}