import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

// ============================================================================
// 1. CUSTOM PAINTERS (Background Header - Sama dengan Dashboard)
// ============================================================================

class ModernPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(
        size.width * 0.25, size.height * 0.6, size.width * 0.5, size.height * 0.8);
    path.quadraticBezierTo(
        size.width * 0.75, size.height * 1.0, size.width, size.height * 0.8);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GeometricPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final double step = 40;
    for (double i = -size.height; i < size.width; i += step) {
      canvas.drawLine(Offset(i, size.height), Offset(i + size.height, 0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// 2. MAIN SCREEN (Daftar Surat)
// ============================================================================

class SuratPengantarAdminScreen extends StatefulWidget {
  final VoidCallback onBackPressed;
  const SuratPengantarAdminScreen({super.key, required this.onBackPressed});

  @override
  State<SuratPengantarAdminScreen> createState() => _SuratPengantarAdminScreenState();
}

class _SuratPengantarAdminScreenState extends State<SuratPengantarAdminScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _allSurat = [];
  List<dynamic> _filteredSurat = [];
  bool _isLoading = true;

  late TabController _tabController;
  late AnimationController _headerAnim;
  late AnimationController _contentAnim;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  // Filter Status Tabs
  final List<String> _statusFilters = ['Semua', 'Diajukan', 'Diproses', 'Disetujui', 'Ditolak'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusFilters.length, vsync: this);
    
    // Setup Animations
    _headerAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _contentAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    _headerFade = CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerAnim, curve: Curves.easeOutCubic));

    // Listeners
    _tabController.addListener(_applyFilters);
    _searchController.addListener(_applyFilters);

    // Start Animation & Load Data
    _headerAnim.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _contentAnim.forward();
    });
    _loadSurat();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerAnim.dispose();
    _contentAnim.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSurat() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getSuratPengantarAdmin();
      if (!mounted) return;

      if (response['success']) {
        setState(() {
          _allSurat = response['data'] ?? [];
          _applyFilters();
        });
      } else {
        _showSnackBar(response['message'] ?? 'Gagal memuat data', Colors.red);
      }
    } catch (e) {
      debugPrint('Error loading surat: $e');
      _showSnackBar('Gagal terhubung ke server', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    if (!mounted) return;
    final query = _searchController.text.toLowerCase();
    final statusIndex = _tabController.index;
    final statusLabel = _statusFilters[statusIndex];

    setState(() {
      _filteredSurat = _allSurat.where((surat) {
        final nama = (surat['nama_pengaju'] ?? '').toString().toLowerCase();
        final jenis = (surat['jenis_surat'] ?? '').toString().toLowerCase();
        final matchesQuery = nama.contains(query) || jenis.contains(query);
        
        if (statusLabel == 'Semua') return matchesQuery;
        
        final statusSurat = (surat['status_pengajuan'] ?? '').toString().toLowerCase();
        return matchesQuery && statusSurat == statusLabel.toLowerCase();
      }).toList();
    });
  }

  void _showDetailDialog(Map<String, dynamic> surat) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SuratDetailDialog(
        surat: surat,
        onStatusUpdated: _loadSurat,
      ),
    );
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadSurat,
          color: const Color(0xFF1E293B),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _headerFade,
                  child: SlideTransition(
                    position: _headerSlide,
                    child: _buildHeader(isMobile),
                  ),
                ),
              ),
              if (_isLoading)
                const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Color(0xFF1E293B))))
              else if (_filteredSurat.isEmpty)
                SliverFillRemaining(child: _buildEmptyState())
              else
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return FadeTransition(
                          opacity: _contentAnim,
                          child: _buildSuratCard(index, _filteredSurat[index], isMobile)
                        );
                      },
                      childCount: _filteredSurat.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      margin: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
        ),
        borderRadius: BorderRadius.circular(isMobile ? 20 : 28),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1E293B).withOpacity(0.4), blurRadius: 30, offset: const Offset(0, 10)),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: ModernPatternPainter())),
          Positioned.fill(child: CustomPaint(painter: GeometricPatternPainter())),
          Padding(
            padding: EdgeInsets.all(isMobile ? 20 : 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: widget.onBackPressed,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Manajemen Surat',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Search Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      icon: Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.7)),
                      hintText: 'Cari nama atau jenis surat...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Custom Tab Bar
                SizedBox(
                  height: 40,
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicator: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    dividerColor: Colors.transparent,
                    tabs: _statusFilters.map((text) => Tab(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mark_email_unread_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Tidak ada data surat',
            style: TextStyle(fontSize: 16, color: Colors.grey[500], fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildSuratCard(int index, Map<String, dynamic> surat, bool isMobile) {
    final status = surat['status_pengajuan'] ?? 'diajukan';
    final color = _getStatusColor(status);
    final icon = _getStatusIcon(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDetailDialog(surat),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status.toString().toUpperCase(),
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                            ),
                          ),
                          Text(
                            _formatDate(surat['tanggal_pengajuan']),
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        surat['jenis_surat'] ?? 'Surat Pengantar',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Oleh: ${surat['nama_pengaju'] ?? '-'}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'disetujui': return const Color(0xFF10B981);
      case 'ditolak': return const Color(0xFFEF4444);
      case 'diproses': return const Color(0xFFF59E0B);
      default: return const Color(0xFF3B82F6);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'disetujui': return Icons.check_circle_outline_rounded;
      case 'ditolak': return Icons.highlight_off_rounded;
      case 'diproses': return Icons.history_edu_rounded;
      default: return Icons.mark_email_unread_outlined;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(dateStr));
    } catch (e) {
      return dateStr;
    }
  }
}

// ============================================================================
// 3. DETAIL DIALOG (Tampilan Detail Warga + Form Admin)
// ============================================================================

class SuratDetailDialog extends StatefulWidget {
  final Map<String, dynamic> surat;
  final Function() onStatusUpdated;

  const SuratDetailDialog({
    super.key,
    required this.surat,
    required this.onStatusUpdated,
  });

  @override
  State<SuratDetailDialog> createState() => _SuratDetailDialogState();
}

class _SuratDetailDialogState extends State<SuratDetailDialog> {
  final ApiService _apiService = ApiService();
  late String _selectedStatus;
  late TextEditingController _tanggapanCtrl;
  late TextEditingController _fileLinkCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Normalize status string from API
    String rawStatus = (widget.surat['status_pengajuan'] ?? 'Diajukan').toString();
    _selectedStatus = rawStatus.substring(0, 1).toUpperCase() + rawStatus.substring(1).toLowerCase();
    
    // Fallback if status not recognized
    if (!['Diajukan', 'Diproses', 'Disetujui', 'Ditolak'].contains(_selectedStatus)) {
      _selectedStatus = 'Diajukan';
    }

    _tanggapanCtrl = TextEditingController(text: widget.surat['tanggapan_admin'] ?? '');
    _fileLinkCtrl = TextEditingController(text: widget.surat['file_surat'] ?? '');
  }

  @override
  void dispose() {
    _tanggapanCtrl.dispose();
    _fileLinkCtrl.dispose();
    super.dispose();
  }

  Future<void> _simpanPerubahan() async {
    setState(() => _isSaving = true);
    try {
      final res = await _apiService.updateStatusSuratPengantar(
        widget.surat['id'].toString(),
        _selectedStatus.toLowerCase(), 
        _tanggapanCtrl.text.trim(),
        _fileLinkCtrl.text.trim().isEmpty ? null : _fileLinkCtrl.text.trim(),
      );

      if (!mounted) return;

      if (res['success']) {
        Navigator.pop(context);
        widget.onStatusUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status berhasil diperbarui'), backgroundColor: Color(0xFF10B981)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Gagal memperbarui'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan jaringan'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Text(
                widget.surat['jenis_surat'] ?? 'Surat Pengantar',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

            // --- CONTENT (Scrollable) ---
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // BAGIAN 1: INFO PENGAJU
                    _buildSectionTitle('Pengaju'),
                    const SizedBox(height: 12),
                    _buildInfoField('Nama Lengkap Warga', widget.surat['nama_pengaju']),
                    _buildInfoField('Email', widget.surat['email_pengaju']),
                    _buildInfoField('Keperluan', widget.surat['keperluan']),
                    _buildInfoField(
                      'Keterangan', 
                      widget.surat['keterangan'] ?? '-', 
                      isLongText: true
                    ),
                    _buildInfoField(
                      'Tanggal Pengajuan', 
                      _formatDate(widget.surat['tanggal_pengajuan'])
                    ),

                    const SizedBox(height: 24),
                    const Divider(thickness: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 24),

                    // BAGIAN 2: UPDATE STATUS (ADMIN)
                    _buildSectionTitle('Update Status'),
                    const SizedBox(height: 16),
                    
                    // Dropdown Status
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: _inputDecoration('Status Pengajuan'),
                      items: ['Diajukan', 'Diproses', 'Disetujui', 'Ditolak']
                          .map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(
                                  status, 
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _getStatusColor(status),
                                  )
                                ),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedStatus = val!),
                    ),
                    const SizedBox(height: 16),

                    // Tanggapan Admin
                    TextField(
                      controller: _tanggapanCtrl,
                      maxLines: 3,
                      minLines: 2,
                      style: const TextStyle(fontSize: 14),
                      decoration: _inputDecoration('Tanggapan Admin').copyWith(
                        hintText: 'Contoh: Silakan ambil surat besok jam 09.00...',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Link File Surat
                    TextField(
                      controller: _fileLinkCtrl,
                      style: const TextStyle(fontSize: 14),
                      decoration: _inputDecoration('Link File Surat (PDF / G-Drive)').copyWith(
                        prefixIcon: const Icon(Icons.link_rounded, color: Color(0xFF64748B)),
                        hintText: 'https://...',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

            // --- TOMBOL AKSI ---
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        foregroundColor: const Color(0xFF475569),
                      ),
                      child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _simpanPerubahan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
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

  // --- WIDGET HELPERS ---

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(), // <--- Ubah teks jadi kapital di sini
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Color(0xFF94A3B8), // Slate-400
        letterSpacing: 0.5,
        // Hapus baris 'uppercase: true'
      ),
    );
  }

  Widget _buildInfoField(String label, String? value, {bool isLongText = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          isLongText 
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                value ?? '-',
                style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.5),
              ),
            )
          : Text(
              value ?? '-',
              style: const TextStyle(
                fontSize: 15, 
                fontWeight: FontWeight.w600, 
                color: Color(0xFF1E293B)
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF64748B)),
      floatingLabelStyle: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1E293B), width: 1.5),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Disetujui': return const Color(0xFF10B981);
      case 'Ditolak': return const Color(0xFFEF4444);
      case 'Diproses': return const Color(0xFFF59E0B);
      default: return const Color(0xFF3B82F6);
    }
  }
}