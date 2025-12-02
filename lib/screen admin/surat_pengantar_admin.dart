// File: lib/screens/surat_pengantar_admin.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SuratPengantarAdminScreen extends StatefulWidget {
  final VoidCallback onBackPressed;
  
  const SuratPengantarAdminScreen({
    super.key,
    required this.onBackPressed,
  });

  @override
  State<SuratPengantarAdminScreen> createState() => _SuratPengantarAdminScreenState();
}

class _SuratPengantarAdminScreenState extends State<SuratPengantarAdminScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<dynamic> _allSurat = [];
  List<dynamic> _filteredSurat = [];
  bool _isLoading = false;
  late TabController _tabController;

  final List<String> _statusFilters = [
    'Semua',
    'Diajukan',
    'Diproses',
    'Disetujui',
    'Ditolak'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusFilters.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadSurat();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    _filterByStatus(_statusFilters[_tabController.index]);
  }

  Future<void> _loadSurat() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getSuratPengantarAdmin();
      
      if (!mounted) return;

      if (response['success']) {
        setState(() {
          _allSurat = response['data'] ?? []; // Defensive: pastikan tidak null
          _filterByStatus(_statusFilters[_tabController.index]);
        });
      } else {
        _showSnackBar(
          response['message'] ?? 'Gagal memuat data',
          Colors.red,
        );
      }
    } catch (e) {
       debugPrint("Error UI Load: $e");
       if(mounted) {
         _showSnackBar('Terjadi kesalahan aplikasi', Colors.red);
       }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterByStatus(String status) {
    setState(() {
      if (status == 'Semua') {
        _filteredSurat = List.from(_allSurat);
      } else {
        _filteredSurat = _allSurat.where((surat) {
          // FIX: Ambil status dengan aman (default 'diajukan' jika null)
          final statusSurat = surat['status_pengajuan']?.toString() ?? 'diajukan';
          return statusSurat.toLowerCase() == status.toLowerCase();
        }).toList();
      }
    });
  }

  // FIX: Menangani input null agar tidak crash
  Color _getStatusColor(String? status) {
    switch ((status ?? 'diajukan').toLowerCase()) {
      case 'disetujui':
        return Colors.green;
      case 'ditolak':
        return Colors.red;
      case 'diproses':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  // FIX: Menangani input null agar tidak crash
  IconData _getStatusIcon(String? status) {
    switch ((status ?? 'diajukan').toLowerCase()) {
      case 'disetujui':
        return Icons.check_circle;
      case 'ditolak':
        return Icons.cancel;
      case 'diproses':
        return Icons.hourglass_empty;
      default:
        return Icons.pending;
    }
  }

  void _showDetailDialog(Map<String, dynamic> surat) {
    showDialog(
      context: context,
      builder: (context) => _SuratDetailDialog(
        surat: surat,
        onStatusUpdated: _loadSurat,
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> surat) {
    // FIX: Gunakan 'id' bukan '_id' (sesuai hasil mapping API Service)
    final String suratId = surat['id']?.toString() ?? '';
    final String jenisSurat = surat['jenis_surat'] ?? 'Surat';
    final String namaPengaju = surat['nama_pengaju'] ?? 'Pengguna';

    if (suratId.isEmpty) {
      _showSnackBar('ID Surat tidak valid', Colors.red);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pengajuan'),
        content: Text(
          'Apakah Anda yakin ingin menghapus pengajuan "$jenisSurat" dari $namaPengaju?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Tutup dialog dulu
              
              final response = await _apiService.deleteSuratPengantar(suratId);
              
              if (!mounted) return;
              
              if (response['success']) {
                _showSnackBar('Pengajuan berhasil dihapus', Colors.green);
                _loadSurat(); // Reload data
              } else {
                _showSnackBar(
                  response['message'] ?? 'Gagal menghapus',
                  Colors.red,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBackPressed,
        ),
        title: const Text('Kelola Surat Pengantar'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: _statusFilters.map((status) => Tab(
            text: status,
            icon: _buildTabBadge(status),
          )).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSurat,
              child: _filteredSurat.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tidak ada pengajuan surat',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredSurat.length,
                      itemBuilder: (context, index) {
                        final surat = _filteredSurat[index];
                        // FIX: Ambil data dengan aman (??)
                        final status = surat['status_pengajuan'] as String?;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(status).withOpacity(0.2),
                              child: Icon(
                                _getStatusIcon(status),
                                color: _getStatusColor(status),
                              ),
                            ),
                            title: Text(
                              surat['jenis_surat'] ?? 'Tanpa Judul',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('Pengaju: ${surat['nama_pengaju'] ?? 'Tidak diketahui'}'),
                                const SizedBox(height: 2),
                                Text(
                                  'Keperluan: ${surat['keperluan'] ?? '-'}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(status).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        status ?? 'Diajukan',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _getStatusColor(status),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      surat['tanggal_pengajuan'] ?? '-',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton(
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'detail',
                                  child: Row(
                                    children: [
                                      Icon(Icons.visibility, size: 20),
                                      SizedBox(width: 8),
                                      Text('Lihat Detail'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, size: 20),
                                      SizedBox(width: 8),
                                      Text('Hapus'),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 'detail') {
                                  _showDetailDialog(surat);
                                } else if (value == 'delete') {
                                  _showDeleteConfirmation(surat);
                                }
                              },
                            ),
                            onTap: () => _showDetailDialog(surat),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildTabBadge(String status) {
    if (_allSurat.isEmpty) return const SizedBox();

    final count = status == 'Semua'
        ? _allSurat.length
        : _allSurat
            .where((s) {
              final sStatus = s['status_pengajuan']?.toString() ?? 'diajukan';
              return sStatus.toLowerCase() == status.toLowerCase();
            })
            .length;

    if (count == 0) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count.toString(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.green.shade700,
        ),
      ),
    );
  }
}

// ==================== DIALOG DETAIL & UPDATE ====================

class _SuratDetailDialog extends StatefulWidget {
  final Map<String, dynamic> surat;
  final VoidCallback onStatusUpdated;

  const _SuratDetailDialog({
    required this.surat,
    required this.onStatusUpdated,
  });

  @override
  State<_SuratDetailDialog> createState() => _SuratDetailDialogState();
}

class _SuratDetailDialogState extends State<_SuratDetailDialog> {
  final ApiService _apiService = ApiService();
  final _tanggapanController = TextEditingController();
  final _fileUrlController = TextEditingController();
  String _selectedStatus = 'Diproses'; // Default safe value
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Inisialisasi status dengan pengecekan aman
    final rawStatus = widget.surat['status_pengajuan']?.toString();
    
    // Pastikan status cocok dengan salah satu item dropdown, kalau tidak default ke 'Diproses'
    const validStatuses = ['Diajukan', 'Diproses', 'Disetujui', 'Ditolak'];
    
    // Cari status yang cocok (case insensitive)
    _selectedStatus = validStatuses.firstWhere(
      (s) => s.toLowerCase() == (rawStatus?.toLowerCase() ?? ''),
      orElse: () => 'Diproses', // Fallback jika status aneh
    );

    _tanggapanController.text = widget.surat['tanggapan_admin'] ?? '';
    _fileUrlController.text = widget.surat['file_surat'] ?? '';
  }

  Future<void> _updateStatus() async {
    setState(() => _isLoading = true);

    try {
      final String suratId = widget.surat['id']?.toString() ?? '';
      if (suratId.isEmpty) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Error: ID Surat tidak valid')),
         );
         return;
      }

      final response = await _apiService.updateStatusSuratPengantar(
        suratId,
        _selectedStatus,
        _tanggapanController.text.trim(),
        _fileUrlController.text.trim().isEmpty
            ? null
            : _fileUrlController.text.trim(),
      );

      if (mounted) {
        if (response['success']) {
          Navigator.pop(context);
          widget.onStatusUpdated();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Status berhasil diperbarui'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Gagal memperbarui status'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan ?? untuk mencegah error rendering text null
    final jenisSurat = widget.surat['jenis_surat'] ?? 'Detail Surat';
    
    return AlertDialog(
      title: Text(jenisSurat),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInfoSection(),
            const Divider(height: 24),
            _buildStatusSection(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateStatus,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informasi Pengajuan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        // Gunakan ?? '-' disemua field
        _buildDetailRow('Pengaju', widget.surat['nama_pengaju'] ?? '-'),
        _buildDetailRow('Email', widget.surat['email_pengaju'] ?? '-'),
        _buildDetailRow('Keperluan', widget.surat['keperluan'] ?? '-'),
        _buildDetailRow('Keterangan', widget.surat['keterangan'] ?? '-'),
        _buildDetailRow('Tanggal Pengajuan', widget.surat['tanggal_pengajuan'] ?? '-'),
        _buildDetailRow('Status Saat Ini', widget.surat['status_pengajuan'] ?? 'Diajukan'),
      ],
    );
  }

  Widget _buildStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Update Status',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedStatus,
          decoration: const InputDecoration(
            labelText: 'Status',
            border: OutlineInputBorder(),
          ),
          items: ['Diajukan', 'Diproses', 'Disetujui', 'Ditolak']
              .map((status) =>
                  DropdownMenuItem(value: status, child: Text(status)))
              .toList(),
          onChanged: (value) => setState(() => _selectedStatus = value!),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _tanggapanController,
          decoration: const InputDecoration(
            labelText: 'Tanggapan Admin',
            border: OutlineInputBorder(),
            hintText: 'Berikan tanggapan atau catatan',
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _fileUrlController,
          decoration: const InputDecoration(
            labelText: 'Link File Surat (jika sudah disetujui)',
            border: OutlineInputBorder(),
            hintText: 'https://...',
            prefixIcon: Icon(Icons.link),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tanggapanController.dispose();
    _fileUrlController.dispose();
    super.dispose();
  }
}