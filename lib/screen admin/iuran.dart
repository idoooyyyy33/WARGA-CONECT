// lib/screens/iuran_page.dart
// VERSI FINAL PREMIUM — IURAN ADMIN PAGE (2025 Edition)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class ModernPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (double i = -size.height; i < size.width * 1.5; i += 40) {
      canvas.drawLine(
        Offset(i, -size.height * 0.5),
        Offset(i - size.width * 0.5, size.height * 1.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class IuranPage extends StatefulWidget {
  final VoidCallback? onBackPressed;
  const IuranPage({super.key, this.onBackPressed});

  @override
  State<IuranPage> createState() => _IuranPageState();
}

class _IuranPageState extends State<IuranPage> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nominalController = TextEditingController();
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _minNominalController = TextEditingController();
  final TextEditingController _maxNominalController = TextEditingController();

  List<dynamic> _allIuran = [];
  List<dynamic> _filteredIuran = [];
  List<dynamic> _wargaList = [];
  // Selection for bulk actions
  final Set<String> _selectedIds = {};
  bool _isBulkProcessing = false;
  bool _isLoading = true;
  bool _showAdvancedFilter = false;

  late TabController _tabController;
  late AnimationController _headerCtrl;
  late AnimationController _contentCtrl;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  int _selectedMonth = 11; // November - showing existing data
  int _selectedYear = 2025;
  int? _filterMinNominal;
  int? _filterMaxNominal;

  final List<String> _filters = [
    'Semua',
    'Menunggu Verifikasi',
    'Lunas',
    'Belum Lunas',
  ];
  final List<String> _bulanList = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic));

    _tabController.addListener(_applyFilters);
    _searchController.addListener(_applyFilters);

    _headerCtrl.forward();
    Future.delayed(
      const Duration(milliseconds: 300),
      () => _contentCtrl.forward(),
    );
    _loadData();
  }

  // Bulk actions
  Future<void> _bulkMarkLunas() async {
    if (_selectedIds.isEmpty) return;
    setState(() => _isBulkProcessing = true);
    int success = 0;
    for (final id in _selectedIds) {
      final res = await _apiService.updateIuranStatus(id, 'Lunas');
      if (res['success'] == true) success++;
    }
    setState(() => _isBulkProcessing = false);
    _showSnackBar(
      'Selesai: $success dari ${_selectedIds.length} berhasil diupdate',
      Colors.green,
    );
    _selectedIds.clear();
    await _loadData();
  }

  Future<void> _exportSelectedCsv() async {
    if (_selectedIds.isEmpty) return;
    final selected = _allIuran
        .where((i) => _selectedIds.contains(i['id']?.toString()))
        .toList();
    final buffer = StringBuffer();
    buffer.writeln(
      'id,nama_warga,nominal,status,periode_bulan,periode_tahun,tanggal_bayar',
    );
    for (var i in selected) {
      final id = i['id']?.toString() ?? '';
      final nama = (i['nama_warga'] ?? '').toString().replaceAll(',', ' ');
      final nom = (i['nominal'] ?? 0).toString();
      final status = (i['status'] ?? '').toString();
      final pb = (i['periode_bulan'] ?? '').toString();
      final pt = (i['periode_tahun'] ?? '').toString();
      final tb = (i['tanggal_bayar'] ?? '').toString();
      buffer.writeln('$id,$nama,$nom,$status,$pb,$pt,$tb');
    }

    final csv = buffer.toString();
    // show dialog with CSV and copy button
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Export CSV (salin)'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(child: SelectableText(csv)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: csv));
              Navigator.pop(context);
              _showSnackBar('CSV disalin ke clipboard', Colors.green);
            },
            child: const Text('Salin'),
          ),
        ],
      ),
    );
  }

  void _clearSelection() {
    setState(() => _selectedIds.clear());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerCtrl.dispose();
    _contentCtrl.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final iuranRes = await _apiService.getIuran(
        bulan: _selectedMonth,
        tahun: _selectedYear,
      );
      final wargaRes = await _apiService.getWarga();

      if (iuranRes['success'] && wargaRes['success']) {
        setState(() {
          _allIuran = iuranRes['data'] ?? [];
          _wargaList = wargaRes['data'] ?? [];
          _applyFilters();
        });
      } else {
        _showSnackBar(iuranRes['message'] ?? 'Gagal memuat data', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Koneksi bermasalah', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    final filter = _filters[_tabController.index];
    final minNom = _filterMinNominal ?? 0;
    final maxNom = _filterMaxNominal ?? 999999999;

    setState(() {
      _filteredIuran = _allIuran.where((i) {
        final nama = (i['nama_warga'] ?? '').toString().toLowerCase();
        final searchOk = nama.contains(query);

        if (!searchOk) return false;

        final status = (i['status'] ?? 'Belum Lunas').toString();
        final nominal = (i['nominal'] ?? 0) as int;

        final matchStatus = filter == 'Semua' || status == filter;
        final matchNominal = nominal >= minNom && nominal <= maxNom;

        return matchStatus && matchNominal;
      }).toList();
    });
  }

  void _showEditIuranDialog(Map<String, dynamic> item) {
    _nominalController.text = (item['nominal'] ?? 0).toString();
    _judulController.text = item['judul'] ?? 'Iuran';
    _deskripsiController.text = item['deskripsi'] ?? '';

    String selectedStatus = item['status'] ?? 'Belum Lunas';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: Text('✏️ Edit Iuran - ${item['nama_warga']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Judul Iuran
                TextField(
                  controller: _judulController,
                  decoration: InputDecoration(
                    labelText: 'Judul Iuran',
                    hintText: 'misal: Iuran Kas, Bencana Alam, Kegiatan',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(
                      Icons.label_rounded,
                      color: Color(0xFF8B5CF6),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Deskripsi
                TextField(
                  controller: _deskripsiController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Deskripsi (opsional)',
                    hintText: 'Jelaskan untuk apa iuran ini...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(
                      Icons.description_rounded,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Nominal
                TextField(
                  controller: _nominalController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Nominal (Rp)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(
                      Icons.attach_money_rounded,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Status
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Belum Lunas',
                      child: Text('Belum Lunas'),
                    ),
                    DropdownMenuItem(
                      value: 'Menunggu Verifikasi',
                      child: Text('Menunggu Verifikasi'),
                    ),
                    DropdownMenuItem(value: 'Lunas', child: Text('Lunas')),
                  ],
                  onChanged: (v) {
                    setState(() => selectedStatus = v ?? 'Belum Lunas');
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final id = item['id'].toString();
                final nominal = int.tryParse(_nominalController.text) ?? 0;

                final updateData = {
                  'jumlah': nominal,
                  'judul': _judulController.text,
                  'deskripsi': _deskripsiController.text,
                };

                final res = await _apiService.updateIuranInfo(id, updateData);

                if (mounted) Navigator.pop(context);
                if (res['success'] == true) {
                  _showSnackBar('✓ Data berhasil diupdate', Colors.green);
                  _loadData();
                } else {
                  _showSnackBar('✗ Gagal: ${res['message']}', Colors.red);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
              ),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String msg, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: c,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Map<String, dynamic> get _stats {
    int lunas = 0, menunggu = 0, belum = 0;
    int totalNominal = 0, totalLunas = 0;
    for (var i in _allIuran) {
      final s = (i['status'] ?? 'Belum Lunas').toString();
      final nom = (i['nominal'] ?? 0) as int;
      totalNominal += nom;
      if (s == 'Lunas') {
        lunas++;
        totalLunas += nom;
      } else if (s == 'Menunggu Verifikasi') {
        menunggu++;
      } else {
        belum++;
      }
    }
    final total = _wargaList.length;
    final persentase = total > 0
        ? ((lunas / total) * 100).toStringAsFixed(1)
        : '0.0';
    return {
      'lunas': lunas,
      'menunggu': menunggu,
      'belum': belum,
      'total': total,
      'totalNominal': totalNominal,
      'totalLunas': totalLunas,
      'persentase': persentase,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showKelolaIuranDialog(),
        backgroundColor: const Color(0xFFF59E0B),
        icon: const Icon(Icons.settings_rounded, color: Colors.white),
        label: const Text(
          'Kelola Iuran',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFFF59E0B),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
              SliverToBoxAdapter(child: _buildStats(isMobile)),
              SliverPadding(
                padding: EdgeInsets.all(isMobile ? 16 : 28),
                sliver: _isLoading
                    ? const SliverFillRemaining(
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      )
                    : _filteredIuran.isEmpty
                    ? SliverFillRemaining(child: _buildEmpty())
                    : SliverList.builder(
                        itemCount: _filteredIuran.length,
                        itemBuilder: (_, i) => FadeTransition(
                          opacity: _contentCtrl,
                          child: _buildPremiumCard(_filteredIuran[i]),
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
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
        ),
        borderRadius: BorderRadius.circular(isMobile ? 20 : 28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.5),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: ModernPatternPainter())),
          Padding(
            padding: EdgeInsets.all(isMobile ? 20 : 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed:
                          widget.onBackPressed ?? () => Navigator.pop(context),
                    ),
                    const Text(
                      'Kelola Iuran Warga',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Cari nama warga...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // === BULAN DAN TAHUN SELECTOR ===
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedMonth,
                        decoration: InputDecoration(
                          labelText: 'Bulan',
                          labelStyle: TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.15),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        items: List.generate(12, (i) {
                          return DropdownMenuItem(
                            value: i + 1,
                            child: Text(_bulanList[i]),
                          );
                        }),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedMonth = val);
                            _loadData();
                          }
                        },
                        dropdownColor: const Color(0xFF1E293B),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedYear,
                        decoration: InputDecoration(
                          labelText: 'Tahun',
                          labelStyle: TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.15),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        items: List.generate(5, (i) {
                          int year = DateTime.now().year - 2 + i;
                          return DropdownMenuItem(
                            value: year,
                            child: Text(year.toString()),
                          );
                        }),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedYear = val);
                            _loadData();
                          }
                        },
                        dropdownColor: const Color(0xFF1E293B),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  tabs: _filters
                      .map(
                        (f) => Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(f),
                              const SizedBox(width: 8),
                              _badge(f),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                // Bulk action bar
                if (_selectedIds.isNotEmpty)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_selectedIds.length} dipilih',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      if (_isBulkProcessing)
                        const Padding(
                          padding: EdgeInsets.only(right: 12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      TextButton.icon(
                        onPressed: _isBulkProcessing
                            ? null
                            : _exportSelectedCsv,
                        icon: const Icon(Icons.download, color: Colors.white),
                        label: const Text(
                          'Export',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white24,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isBulkProcessing ? null : _bulkMarkLunas,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                        ),
                        child: const Text('Mark Lunas'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _clearSelection,
                        child: const Text(
                          'Batal',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String filter) {
    final stats = _stats;
    int count = filter == 'Semua'
        ? _allIuran.length
        : filter == 'Menunggu Verifikasi'
        ? stats['menunggu']!
        : filter == 'Lunas'
        ? stats['lunas']!
        : stats['belum']!;
    return count == 0
        ? const SizedBox()
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          );
  }

  Widget _buildStats(bool isMobile) {
    final s = _stats;
    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 28),
      child: Row(
        children: [
          _statBox('Lunas', '${s['lunas']}', const Color(0xFF10B981)),
          const SizedBox(width: 16),
          _statBox('Menunggu', '${s['menunggu']}', const Color(0xFF3B82F6)),
          const SizedBox(width: 16),
          _statBox('Belum Bayar', '${s['belum']}', const Color(0xFFDC2626)),
          const SizedBox(width: 16),
          _statBox('Total Warga', '${s['total']}', const Color(0xFF8B5CF6)),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payments_rounded, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Belum Ada Data Iuran',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCard(Map<String, dynamic> item) {
    final status = (item['status'] ?? 'Belum Lunas').toString();
    final color = status == 'Lunas'
        ? const Color(0xFF10B981)
        : status == 'Menunggu Verifikasi'
        ? const Color(0xFF3B82F6)
        : const Color(0xFFDC2626);
    final icon = status == 'Lunas'
        ? Icons.check_circle_rounded
        : status == 'Menunggu Verifikasi'
        ? Icons.hourglass_top_rounded
        : Icons.schedule_rounded;

    final judul = (item['judul'] ?? 'Iuran').toString();
    final deskripsi = (item['deskripsi'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFFAFAFA)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: status == 'Menunggu Verifikasi'
            ? () => _showVerificationDialog(item)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row dengan checkbox dan action buttons
              Row(
                children: [
                  // Selection checkbox
                  Builder(
                    builder: (_) {
                      final id = item['id']?.toString() ?? '';
                      return Checkbox(
                        value: _selectedIds.contains(id),
                        onChanged: (v) {
                          setState(() {
                            if (v == true)
                              _selectedIds.add(id);
                            else
                              _selectedIds.remove(id);
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Judul Iuran - ditampilkan prominently
                        Text(
                          judul,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8B5CF6),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['nama_warga'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Edit button
                  IconButton(
                    icon: const Icon(Icons.edit_rounded),
                    color: const Color(0xFF8B5CF6),
                    onPressed: () => _showEditIuranDialog(item),
                    tooltip: 'Edit iuran',
                  ),
                  // Menu dropdown
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert_rounded),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'info',
                        child: Text('Lihat Info'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Hapus',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                    onSelected: (v) {
                      if (v == 'delete') {
                        _confirmDelete(item['id'].toString());
                      } else if (v == 'info') {
                        _showIuranInfo(item);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Info row: nominal, status, tanggal
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.08), color.withOpacity(0.04)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nominal',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            NumberFormat.currency(
                              locale: 'id_ID',
                              symbol: 'Rp ',
                            ).format(item['nominal'] ?? 0),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Status',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon, color: color, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  status,
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (item['tanggal_bayar'] != null &&
                        item['tanggal_bayar'].toString().isNotEmpty)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Dibayar',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Builder(
                              builder: (_) {
                                final tb = item['tanggal_bayar'].toString();
                                try {
                                  final dt = DateTime.parse(tb);
                                  return Text(
                                    DateFormat('dd MMM yyyy').format(dt),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  );
                                } catch (e) {
                                  return Text(
                                    tb,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Deskripsi jika ada
              if (deskripsi.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2D5F3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF8B5CF6),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          deskripsi,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF5B21B6),
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showIuranInfo(Map<String, dynamic> item) {
    final judul = item['judul'] ?? 'Iuran';
    final deskripsi = item['deskripsi'] ?? 'Tidak ada deskripsi';
    final status = item['status'] ?? 'Belum Lunas';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(judul),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Warga: ${item['nama_warga']}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                'Nominal: Rp ${NumberFormat('#,###').format(item['nominal'] ?? 0)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                'Status: $status',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Keterangan:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      deskripsi,
                      style: const TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showVerificationDialog(Map<String, dynamic> item) {
    String selectedStatus = item['status'] ?? 'Belum Lunas';
    final nominal = item['nominal'] ?? 0;
    final bukti = item['bukti_pembayaran'] ?? '';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: Text('Verifikasi - ${item['nama_warga']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Judul: ${item['judul'] ?? 'Iuran'}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Text(
                  'Nominal: Rp ${NumberFormat('#,###').format(nominal)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                if (bukti.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bukti Pembayaran:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 150,
                        width: double.maxFinite,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade200,
                        ),
                        child: Image.network(
                          'http://10.61.28.85:3000/uploads/$bukti',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Center(child: Text(bukti)),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Status Verifikasi',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Belum Lunas',
                      child: Text('Belum Lunas'),
                    ),
                    DropdownMenuItem(
                      value: 'Menunggu Verifikasi',
                      child: Text('Menunggu Verifikasi'),
                    ),
                    DropdownMenuItem(value: 'Lunas', child: Text('Lunas')),
                  ],
                  onChanged: (v) {
                    setState(() => selectedStatus = v ?? 'Belum Lunas');
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final res = await _apiService.updateIuranStatus(
                  item['id'].toString(),
                  selectedStatus,
                );
                if (res['success'] == true) {
                  _showSnackBar('✓ Status diupdate', Colors.green);
                  _loadData();
                } else {
                  _showSnackBar('✗ Gagal: ${res['message']}', Colors.red);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
              ),
              child: const Text('Verifikasi'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Hapus Iuran?'),
        content: const Text('Data akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final res = await _apiService.deleteIuran(id);
              res['success']
                  ? {
                      _showSnackBar('Berhasil dihapus', Colors.green),
                      _loadData(),
                    }
                  : _showSnackBar('Gagal', Colors.red);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showKelolaIuranDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('⚙️ Kelola Iuran'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF8B5CF6),
                ),
                title: const Text('Lihat Informasi'),
                subtitle: const Text('Pelajari jenis-jenis iuran'),
                onTap: () {
                  Navigator.pop(context);
                  _showIuranTypesInfo();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.edit_rounded,
                  color: Color(0xFF3B82F6),
                ),
                title: const Text('Edit Iuran'),
                subtitle: const Text('Ubah nominal atau deskripsi'),
                onTap: () {
                  Navigator.pop(context);
                  _showSelectIuranForEditDialog();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.add_circle_outline,
                  color: Colors.green,
                ),
                title: const Text('Buat Mass Iuran'),
                subtitle: const Text('Buat iuran untuk semua warga'),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateMassIuranDialog();
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showSelectIuranForEditDialog() {
    if (_allIuran.isEmpty) {
      _showSnackBar('Tidak ada iuran untuk diedit', Colors.orange);
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('📝 Pilih Iuran untuk Diedit'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _allIuran.map<Widget>((item) {
              final judul = item['judul'] ?? 'Iuran';
              final nama = item['nama_warga'] ?? 'Unknown';
              final nominal = item['nominal'] ?? 0;
              final status = item['status'] ?? 'Belum Lunas';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: Colors.grey.shade100,
                  leading: const Icon(
                    Icons.receipt_rounded,
                    color: Color(0xFFF59E0B),
                  ),
                  title: Text(judul),
                  subtitle: Text(
                    '$nama - Rp ${NumberFormat('#,###').format(nominal)}',
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: status == 'Lunas'
                          ? Colors.green.shade200
                          : Colors.orange.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditIuranDialog(item);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  void _showCreateMassIuranDialog() {
    final judulCtrl = TextEditingController();
    final deskripsiCtrl = TextEditingController();
    final nominalCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: const Text('➕ Buat Mass Iuran'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: judulCtrl,
                  decoration: InputDecoration(
                    labelText: 'Judul Iuran',
                    hintText: 'misal: Iuran Kas Bulanan',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(
                      Icons.label_rounded,
                      color: Color(0xFF8B5CF6),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: deskripsiCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Deskripsi',
                    hintText: 'Jelaskan untuk apa iuran ini...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(
                      Icons.description_rounded,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nominalCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Nominal (Rp)',
                    hintText: '100000',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(
                      Icons.attach_money_rounded,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_rounded, color: Color(0xFF3B82F6)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Iuran akan dibuat untuk ${_wargaList.length} warga',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF3B82F6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validate input
                if (judulCtrl.text.isEmpty) {
                  _showSnackBar('Judul iuran harus diisi', Colors.red);
                  return;
                }
                if (nominalCtrl.text.isEmpty) {
                  _showSnackBar('Nominal harus diisi', Colors.red);
                  return;
                }

                final nominal = int.tryParse(nominalCtrl.text);
                if (nominal == null || nominal <= 0) {
                  _showSnackBar('Nominal harus angka positif', Colors.red);
                  return;
                }

                Navigator.pop(context);

                // Buat iuran massal via endpoint massal
                _showSnackBar(
                  'Membuat iuran massal untuk ${_wargaList.length} warga...',
                  Colors.blue,
                );

                try {
                  final res = await _apiService.createMassIuran({
                    'judul_iuran': judulCtrl.text,
                    'jenis_iuran': 'umum',
                    'jumlah': nominal,
                    'periode_bulan': _selectedMonth,
                    'periode_tahun': _selectedYear,
                    'jatuh_tempo': null,
                  });

                  if (res['success'] == true) {
                    final data = res['data'];
                    int created = 0;
                    if (data is Map && data['createdCount'] != null) {
                      created = data['createdCount'] as int;
                    } else if (data is List) {
                      created = data.length;
                    } else if (data is Map && data['created'] != null) {
                      created = data['created'] as int;
                    }

                    _showSnackBar(
                      '✓ Berhasil membuat $created/${_wargaList.length} iuran',
                      created == _wargaList.length
                          ? Colors.green
                          : Colors.orange,
                    );
                  } else {
                    _showSnackBar('✗ Gagal: ${res['message']}', Colors.red);
                  }
                } catch (e) {
                  debugPrint('❌ Error create mass iuran: $e');
                  _showSnackBar(
                    '✗ Terjadi kesalahan saat membuat massal',
                    Colors.red,
                  );
                }

                await _loadData();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Buat untuk Semua Warga'),
            ),
          ],
        ),
      ),
    );
  }

  void _showIuranTypesInfo() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('📋 Jenis-Jenis Iuran'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIuranTypeInfo(
                'Iuran Kas',
                'Iuran rutin bulanan untuk operasional/kegiatan RT/RW',
                Icons.wallet_rounded,
                const Color(0xFF10B981),
              ),
              const SizedBox(height: 16),
              _buildIuranTypeInfo(
                'Iuran Bencana Alam',
                'Dana darurat untuk menghadapi bencana alam',
                Icons.warning_rounded,
                const Color(0xFFDC2626),
              ),
              const SizedBox(height: 16),
              _buildIuranTypeInfo(
                'Iuran Kegiatan',
                'Iuran untuk acara/kegiatan khusus komunitas',
                Icons.event_rounded,
                const Color(0xFF3B82F6),
              ),
              const SizedBox(height: 16),
              _buildIuranTypeInfo(
                'Iuran Kesehatan',
                'Dana untuk pemeriksaan kesehatan rutin warga',
                Icons.health_and_safety_rounded,
                const Color(0xFFF59E0B),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildIuranTypeInfo(
    String title,
    String desc,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
