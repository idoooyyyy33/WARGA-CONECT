import 'package:flutter/material.dart';
import 'package:warga_conect_pt2/services/api_service.dart';

class SuratPengantarAdminScreen extends StatefulWidget {
  final VoidCallback? onBackPressed;

  const SuratPengantarAdminScreen({super.key, this.onBackPressed});

  @override
  State<SuratPengantarAdminScreen> createState() =>
      _SuratPengantarAdminScreenState();
}

class _SuratPengantarAdminScreenState extends State<SuratPengantarAdminScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _suratPengantar = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Defensive: capture any errors from loading so they don't crash the UI silently
    _loadSuratPengantar().catchError((e, stack) {
      debugPrint('❌ Error in initState _loadSuratPengantar: $e');
      debugPrint('Stack: $stack');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    });
  }

  Future<void> _loadSuratPengantar() async {
    setState(() => _isLoading = true);

    debugPrint('🔍 Loading Surat Pengantar for Admin...');

    final result = await _apiService.getSuratPengantarAdmin();

    debugPrint('📥 Result success: ${result['success']}');
    debugPrint('   Message: ${result['message']}');
    debugPrint('   Data length: ${result['data']?.length ?? 0}');

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success']) {
          _suratPengantar = result['data'] is List ? result['data'] : [];
          debugPrint('✅ Loaded ${_suratPengantar.length} surat pengantar');
        } else {
          debugPrint('❌ Error: ${result['message']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ?? 'Gagal memuat surat pengantar',
              ),
              backgroundColor: Colors.red.shade400,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    }
  }

  void _showUpdateStatusDialog(dynamic surat) {
    final tanggapanController = TextEditingController(
      text: surat['tanggapan_admin'] ?? '',
    );
    String selectedStatus = surat['status_pengajuan'] ?? 'Diajukan';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                const Text(
                  'Update Status Pengajuan',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Pengaju: ${surat['nama_pengaju'] ?? 'Tidak diketahui'}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 24),

                // Status Dropdown
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedStatus,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      items: ['Diajukan', 'Diproses', 'Disetujui', 'Ditolak']
                          .map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          })
                          .toList(),
                      onChanged: (String? newValue) {
                        setModalState(() {
                          selectedStatus = newValue!;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Tanggapan Field
                TextField(
                  controller: tanggapanController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Tanggapan Admin',
                    hintText: 'Berikan tanggapan atau alasan keputusan',
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);

                      final result = await _apiService.updateStatusSuratPengantar(
                        surat['id'],
                        selectedStatus,
                        tanggapanController.text,
                        null, // fileUrl - bisa ditambahkan nanti untuk upload file
                      );

                      if (mounted) {
                        if (result['success']) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Status berhasil diperbarui'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _loadSuratPengantar();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                result['message'] ?? 'Gagal memperbarui status',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Update Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFB923C), Color(0xFFF97316)],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFB923C).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Material(
                            color: Colors.white.withOpacity(0.0),
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_rounded,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Kelola Surat Pengantar',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFFB923C),
                        ),
                      )
                    : _suratPengantar.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada pengajuan surat',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadSuratPengantar,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _suratPengantar.length,
                          itemBuilder: (context, index) {
                            final surat = _suratPengantar[index];
                            return _buildSuratCard(surat);
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      );
    } catch (e, stack) {
      // If a synchronous build error happens, show it on-screen instead of blank
      debugPrint('❌ Build error in SuratPengantarAdminScreen: $e');
      debugPrint('Stack: $stack');
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SelectableText('Build error: $e\n\n$stack'),
        ),
      );
    }
  }

  Widget _buildSuratCard(dynamic surat) {
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
                    color: const Color(0xFFFED7AA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    surat['jenis_surat'] ?? 'Lainnya',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFB923C),
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
                      surat['status_pengajuan'],
                    ).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    surat['status_pengajuan'] ?? 'Diajukan',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(surat['status_pengajuan']),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              surat['keperluan'] ?? '',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pengaju: ${surat['nama_pengaju'] ?? 'Tidak diketahui'}',
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
            if (surat['email_pengaju'] != null &&
                surat['email_pengaju'].isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Email: ${surat['email_pengaju']}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
            ],
            if (surat['keterangan'] != null &&
                surat['keterangan'].isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                surat['keterangan'],
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
            ],
            if (surat['tanggapan_admin'] != null &&
                surat['tanggapan_admin'].isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tanggapan Admin:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      surat['tanggapan_admin'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (surat['tanggal_pengajuan'] != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    surat['tanggal_pengajuan'],
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showUpdateStatusDialog(surat),
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Update Status'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Colors.red.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Hapus Pengajuan'),
                          content: const Text(
                            'Apakah Anda yakin ingin menghapus pengajuan ini?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Batal'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Hapus'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        final result = await _apiService.deleteSuratPengantar(
                          surat['id'],
                        );
                        if (mounted) {
                          if (result['success']) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Pengajuan berhasil dihapus'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            _loadSuratPengantar();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  result['message'] ??
                                      'Gagal menghapus pengajuan',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: const Icon(
                        Icons.delete_rounded,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'disetujui':
        return Colors.green;
      case 'diproses':
        return Colors.blue;
      case 'ditolak':
        return Colors.red;
      default: // 'diajukan'
        return Colors.orange;
    }
  }
}
