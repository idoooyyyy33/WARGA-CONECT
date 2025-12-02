import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:image_picker/image_picker.dart'; // <-- Tambahan
import 'dart:typed_data';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _payments = [];
  bool _isLoading = false;

  // --- TAMBAHAN ---
  final ImagePicker _picker = ImagePicker();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);

    final result = await _apiService.getPayments();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success']) {
          _payments = result['data'] is List ? result['data'] : [];
        } else {
          _showSnackBar(
            result['message'] ?? 'Gagal memuat data pembayaran',
            isError: true,
          );
        }
      });
    }
  }

  // --- TAMBAHAN: Fungsi untuk menampilkan dialog pembayaran ---
  void _showPaymentDialog(dynamic payment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20,
          left: 24,
          right: 24,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Pembayaran ${payment['title'] ?? 'Iuran'}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Total Tagihan: Rp ${payment['amount']?.toString() ?? '0'}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Metode Pembayaran',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 16),

              // Opsi 1: QRIS
              const Text(
                'Scan QRIS (via m-banking, GoPay, OVO, Dana, dll):',
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    image: const DecorationImage(
                      // Ganti dengan URL gambar QRIS Anda
                      image: NetworkImage(
                        'https://i.ibb.co/L0xJ1pX/qr-code-placeholder.png',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Opsi 2: Transfer Manual
              const Text(
                'Atau Transfer ke Rekening:',
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BCA: 1234567890',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text('a/n Bendahara RT 01', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Opsi 3: Bayar Tunai
              const Center(
                child: Text(
                  'Anda juga bisa bayar **Tunai** langsung ke Bendahara.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
              ),
              const SizedBox(height: 24),

              // Tombol Aksi Upload Bukti
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // Tutup dialog
                    _uploadProof(payment['id']); // Panggil fungsi upload
                  },
                  icon: const Icon(
                    Icons.upload_file_rounded,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Saya Sudah Bayar (Upload Bukti)',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // --- TAMBAHAN: Fungsi untuk memilih gambar & upload ---
  Future<void> _uploadProof(String paymentId) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image == null) {
        _showSnackBar('Pemilihan gambar dibatalkan', isError: true);
        return;
      }

      // --- PERBAIKAN: Baca isi file (bytes) dan ambil nama filenya ---
      final Uint8List imageBytes = await image.readAsBytes();
      final String fileName = image.name;
      // --- BATAS PERBAIKAN ---

      _showLoadingDialog();

      // --- PERBAIKAN: Kirim bytes dan nama file, bukan path ---
      final result = await _apiService.uploadPaymentProof(
        paymentId,
        imageBytes,
        fileName,
      );

      if (mounted) {
        Navigator.pop(context); // Tutup loading

        if (result['success']) {
          _showSnackBar(
            'Bukti bayar berhasil di-upload. Menunggu verifikasi admin.',
            isError: false,
          );
          _loadPayments(); // Refresh list
        } else {
          _showSnackBar(
            result['message'] ?? 'Gagal meng-upload bukti',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Tutup loading
      _showSnackBar('Error: $e', isError: true);
    }
  }

  // --- TAMBAHAN: Helper dialog ---
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF10B981)),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade400 : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  // --- BATAS TAMBAHAN ---

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPayments,
          color: const Color(0xFF10B981),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildLargeHeader(isMobile)),

              _isLoading
                  ? const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF10B981),
                        ),
                      ),
                    )
                  : _filteredPayments.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada data pembayaran',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        isMobile ? 16 : 20,
                        12,
                        isMobile ? 16 : 20,
                        80,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final payment = _filteredPayments[index];
                          return _buildPaymentCard(payment);
                        }, childCount: _filteredPayments.length),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  List<dynamic> get _filteredPayments {
    if (_searchQuery.isEmpty) return _payments;
    final q = _searchQuery.toLowerCase();
    return _payments.where((p) {
      final title = (p['title'] ?? p['name'] ?? '').toString().toLowerCase();
      final note = (p['note'] ?? '').toString().toLowerCase();
      return title.contains(q) || note.contains(q);
    }).toList();
  }

  Widget _buildLargeHeader(bool isMobile) {
    return Container(
      margin: EdgeInsets.all(isMobile ? 12 : 20),
      padding: EdgeInsets.all(isMobile ? 18 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
        ),
        borderRadius: BorderRadius.circular(isMobile ? 18 : 22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Iuran Warga',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Cari iuran...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.white.withOpacity(0.85),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(dynamic payment) {
    // --- PERBAIKAN --- Ambil ID dan Status
    final String paymentId = payment['id']?.toString() ?? '';
    final String status = payment['status']?.toString() ?? 'Menunggu';
    final bool isPaid = status.toLowerCase() == 'lunas';
    final bool isPending = status.toLowerCase() == 'menunggu verifikasi';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA7F3D0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    payment['type'] ?? 'Iuran',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      status,
                    ).withOpacity(0.2), // Pakai status
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status, // Pakai status
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(status), // Pakai status
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              payment['description'] ?? 'Pembayaran iuran',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Rp ${payment['amount']?.toString() ?? '0'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF10B981),
                  ),
                ),
                const Spacer(),
                if (payment['date'] != null)
                  Text(
                    payment['date'],
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
              ],
            ),

            // --- PERBAIKAN: Tambahkan tombol bayar ---
            if (!isPaid) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isPending
                      ? null
                      : () {
                          // Nonaktifkan jika sedang "Menunggu Verifikasi"
                          _showPaymentDialog(payment);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPending
                        ? Colors.grey
                        : const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isPending ? 'Menunggu Verifikasi' : 'Bayar Sekarang',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
            // --- BATAS PERBAIKAN ---
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'lunas':
        return Colors.green;
      case 'menunggu verifikasi': // --- TAMBAHAN ---
        return Colors.blue;
      default: // 'Menunggu' atau status tidak dikenal
        return Colors.orange;
    }
  }
}
