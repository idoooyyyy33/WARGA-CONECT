import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';

class IuranPage extends StatefulWidget {
  final VoidCallback? onBackPressed;

  const IuranPage({super.key, this.onBackPressed});

  @override
  State<IuranPage> createState() => _IuranPageState();
}

class _IuranPageState extends State<IuranPage> {
  final ApiService _apiService = ApiService();
  List<dynamic> _iuranList = [];
  List<dynamic> _wargaList = [];
  bool _isLoading = true;
  bool _isUpdatingStatus = false;
  String _selectedFilter = 'Semua';
  String _searchQuery = '';
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  // Menambah filter 'Menunggu Verifikasi'
  final List<String> _filterOptions = ['Semua', 'Menunggu Verifikasi', 'Lunas', 'Belum Lunas'];
  final List<String> _bulanList = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final iuranResult = await _apiService.getIuran(_selectedMonth, _selectedYear);
      // Memastikan memanggil getWargaAdmin (yang URL-nya benar)
      final wargaResult = await _apiService.getWargaAdmin(); 
      
      if (mounted) {
        if (iuranResult['success'] && wargaResult['success']) {
          setState(() {
            _iuranList = iuranResult['data'] ?? [];
            _wargaList = wargaResult['data'] ?? [];
            _isLoading = false;
          });
        } else {
           _showSnackBar(
            iuranResult['message'] ?? wargaResult['message'] ?? 'Gagal memuat data', 
            isError: true
          );
           setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Error: $e', isError: true);
      }
    }
  }

  Future<void> _bayarIuran(String wargaId, int nominal, String bulan, int tahun, String metodePembayaran) async {
    try {
      final result = await _apiService.bayarIuran(wargaId, nominal, bulan, tahun, metodePembayaran);
      if (result['success']) {
        _showSnackBar('Pembayaran iuran berhasil dicatat', isError: false);
        _loadData();
      } else {
        _showSnackBar(result['message'] ?? 'Gagal mencatat pembayaran', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _deleteIuran(String id) async {
    try {
      final result = await _apiService.deleteIuran(id); 
      if (result['success']) {
        _showSnackBar('Data iuran berhasil dihapus', isError: false);
        _loadData();
      } else {
        _showSnackBar(result['message'] ?? 'Gagal menghapus', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    }
  }

  // Fungsi untuk update status (Setujui/Tolak)
  Future<void> _updateIuranStatus(String iuranId, String newStatus) async {
    setState(() => _isUpdatingStatus = true);
    
    try {
      // Panggil fungsi API yang sudah kita tambahkan di api_service.dart
      final result = await _apiService.updateIuranStatus(iuranId, newStatus);
      
      if (mounted) {
        if (result['success']) {
          _showSnackBar(
            newStatus == 'Lunas' ? 'Pembayaran Disetujui' : 'Pembayaran Ditolak', 
            isError: false
          );
          _loadData(); // Refresh data
        } else {
          _showSnackBar(result['message'] ?? 'Gagal update status', isError: true);
        }
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isUpdatingStatus = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFDC2626) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  List<dynamic> get _filteredIuran {
    var filtered = _iuranList;

    // Menambahkan filter 'Menunggu Verifikasi'
    if (_selectedFilter == 'Lunas') {
      filtered = filtered.where((item) => item['status'] == 'Lunas').toList();
    } else if (_selectedFilter == 'Belum Lunas') {
      // Tampilkan juga yang statusnya null atau string kosong sebagai 'Belum Lunas'
      filtered = filtered.where((item) => item['status'] == 'Belum Lunas' || item['status'] == null || item['status'] == '').toList();
    } else if (_selectedFilter == 'Menunggu Verifikasi') {
      filtered = filtered.where((item) => item['status'] == 'Menunggu Verifikasi').toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        final nama = item['nama_warga']?.toString().toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        return nama.contains(query);
      }).toList();
    }

    return filtered;
  }

  Map<String, dynamic> get _stats {
    int totalLunas = 0;
    int totalBelumLunas = 0;
    int totalMenunggu = 0;
    int totalPendapatan = 0;

    for (var item in _iuranList) {
      final status = item['status']?.toString() ?? 'Belum Lunas';
      if (status == 'Lunas') {
        totalLunas++;
        totalPendapatan += (item['nominal'] as int?) ?? 0;
      } else if (status == 'Menunggu Verifikasi') {
        totalMenunggu++;
      } else { // Termasuk 'Belum Lunas' atau null
        totalBelumLunas++;
      }
    }

    return {
      'lunas': totalLunas,
      'belumLunas': totalBelumLunas,
      'menunggu': totalMenunggu,
      'pendapatan': totalPendapatan,
      'total': _iuranList.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBackToDashboardButton(),
        _buildHeader(),
        const SizedBox(height: 24),
        _buildStatsCards(),
        const SizedBox(height: 24),
        _buildFilterBar(),
        const SizedBox(height: 24),
        _buildSearchBar(),
        const SizedBox(height: 24),
        _isLoading
          ? _buildLoadingState()
          : _isUpdatingStatus
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)))
            : _buildIuranList(),
      ],
    );
  }

  Widget _buildBackToDashboardButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onBackPressed ?? () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Kembali ke Dashboard',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.payment_rounded, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Iuran RT',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A202C),
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Manajemen pembayaran iuran warga',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _showBayarDialog(),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('Catat Bayar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF59E0B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    final stats = _stats;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Menunggu Verifikasi',
                '${stats['menunggu']}',
                Icons.hourglass_top_rounded,
                const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Lunas',
                '${stats['lunas']}',
                Icons.check_circle_rounded,
                const Color(0xFF10B981),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Belum Lunas',
                '${stats['belumLunas']}',
                Icons.schedule_rounded,
                const Color(0xFFDC2626),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Pendapatan',
                _formatRupiah(stats['pendapatan']),
                Icons.payments_rounded,
                const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded, color: Color(0xFF64748B), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<int>(
                    value: _selectedMonth,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: List.generate(12, (index) {
                      return DropdownMenuItem(
                        value: index + 1,
                        child: Text(_bulanList[index]),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedMonth = value);
                        _loadData();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 100,
                  child: DropdownButton<int>(
                    value: _selectedYear,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: List.generate(5, (index) {
                      final year = DateTime.now().year - 2 + index;
                      return DropdownMenuItem(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedYear = value);
                        _loadData();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButton<String>(
            value: _selectedFilter,
            underline: const SizedBox(),
            icon: const Icon(Icons.filter_list_rounded, color: Color(0xFF64748B)),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            borderRadius: BorderRadius.circular(14),
            items: _filterOptions.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() => _selectedFilter = newValue);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: const InputDecoration(
          hintText: 'Cari nama warga...',
          hintStyle: TextStyle(color: Color(0xFF94A3B8)),
          prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF64748B)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          const CircularProgressIndicator(
            color: Color(0xFFF59E0B),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          const Text(
            'Memuat data...',
            style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildIuranList() {
    if (_filteredIuran.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredIuran.length,
      itemBuilder: (context, index) {
        final item = _filteredIuran[index];
        return _buildIuranCard(item, index);
      },
    );
  }

  Widget _buildIuranCard(Map<String, dynamic> item, int index) {
    final namaWarga = item['nama_warga']?.toString() ?? 'Tidak Diketahui';
    final nominal = item['nominal'] as int? ?? 0;
    final status = item['status']?.toString() ?? 'Belum Lunas';
    final tanggalBayar = item['tanggal_bayar']?.toString();
    final metodePembayaran = item['metode_pembayaran']?.toString() ?? '-';
    final iuranId = item['id']?.toString(); 
    final buktiBayarPath = item['bukti_pembayaran']?.toString();

    final bool isLunas = status == 'Lunas';
    final bool isMenunggu = status == 'Menunggu Verifikasi';
    final Color statusColor = _getStatusColor(status);
    final IconData statusIcon = isLunas 
      ? Icons.check_circle_rounded 
      : (isMenunggu ? Icons.hourglass_top_rounded : Icons.schedule_rounded);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column( 
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          namaWarga,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A202C),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatRupiah(nominal),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFF59E0B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isLunas && iuranId != null)
                    IconButton(
                      onPressed: () => _showDeleteDialog(iuranId),
                      icon: const Icon(Icons.delete_rounded),
                      color: const Color(0xFFDC2626),
                      iconSize: 20,
                    ),
                ],
              ),
              if (isLunas && tanggalBayar != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(tanggalBayar),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.credit_card_rounded, size: 12, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(
                      metodePembayaran,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              // Tombol Verifikasi
              if (isMenunggu && iuranId != null) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.image_search_rounded, size: 18),
                    label: const Text('Lihat Bukti & Verifikasi'),
                    onPressed: () {
                      _showVerificationDialog(item);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6), // Biru
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.payment_rounded,
              size: 64,
              color: const Color(0xFFF59E0B).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Belum Ada Data Iuran',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A202C),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Data iuran untuk ${_bulanList[_selectedMonth - 1]} $_selectedYear belum tersedia',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  void _showBayarDialog() {
    String? selectedWargaId;
    final nominalController = TextEditingController(text: '50000');
    String selectedMetode = 'Tunai';
    final metodeOptions = ['Tunai', 'Transfer', 'E-Wallet'];

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          child: StatefulBuilder(
            builder: (context, setDialogState) => SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.payment_rounded, color: Color(0xFFF59E0B), size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Catat Pembayaran Iuran',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A202C),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    value: selectedWargaId,
                    decoration: InputDecoration(
                      labelText: 'Pilih Warga',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                    items: _wargaList.map((warga) {
                      return DropdownMenuItem<String>(
                        value: warga['_id'].toString(), 
                        child: Text(warga['nama_lengkap'] ?? warga['nama'] ?? 'N/A'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() => selectedWargaId = value);
                    },
                    validator: (value) => value == null ? 'Warga harus dipilih' : null,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nominalController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Nominal (Rp)',
                      hintText: 'Masukkan nominal',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      prefixText: 'Rp ',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Metode Pembayaran',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A202C),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    children: metodeOptions.map((metode) {
                      final isSelected = selectedMetode == metode;
                      return FilterChip(
                        label: Text(metode),
                        selected: isSelected,
                        onSelected: (bool selected) {
                          if (selected) setDialogState(() => selectedMetode = metode);
                        },
                        selectedColor: const Color(0xFFF59E0B).withOpacity(0.2),
                        checkmarkColor: const Color(0xFFF59E0B),
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
                        ),
                        labelStyle: TextStyle(
                          color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFF64748B),
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (selectedWargaId == null || nominalController.text.isEmpty) {
                              _showSnackBar('Semua field harus diisi', isError: true);
                              return;
                            }

                            Navigator.pop(ctx);
                            _bayarIuran(
                              selectedWargaId!,
                              int.parse(nominalController.text),
                              _bulanList[_selectedMonth - 1],
                              _selectedYear,
                              selectedMetode,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Simpan'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ), 
          ),
        ),
      ),
    );
  }
  
  // --- TAMBAHAN: Dialog Verifikasi ---
  void _showVerificationDialog(Map<String, dynamic> item) {
    final String iuranId = item['id'].toString();
    final String? buktiBayarPath = item['bukti_pembayaran']?.toString();
    
    // Membangun URL gambar dari backend
    // Ganti 'localhost' atau '127.0.0.1' dengan IP server jika perlu
    // Pastikan baseUrl tidak memiliki '/api' di akhir saat membangun URL gambar
    final String imageUrl = ApiService.baseUrl.replaceAll('/api', '') + 
                            '/$buktiBayarPath'.replaceAll('\\', '/');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Verifikasi Pembayaran'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Warga: ${item['nama_warga'] ?? 'N/A'}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text('Jumlah: ${_formatRupiah(item['nominal'] ?? 0)}'),
              const SizedBox(height: 16),
              const Text(
                'Bukti Pembayaran:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              
              (buktiBayarPath == null || buktiBayarPath.isEmpty) 
              ? Container(
                  height: 200,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Warga tidak melampirkan bukti',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  // Menampilkan gambar dari URL server
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    // Menampilkan loading spinner saat gambar dimuat
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        alignment: Alignment.center,
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / 
                                loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    // Menampilkan error jika gambar gagal dimuat
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('Error loading image: $error');
                      debugPrint('Image URL: $imageUrl');
                      return Container(
                        height: 200,
                        alignment: Alignment.center,
                        color: Colors.grey[200],
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, color: Colors.red, size: 40),
                            SizedBox(height: 8),
                            Text(
                              'Gagal memuat bukti', 
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Tombol Tolak
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateIuranStatus(iuranId, 'Belum Lunas');
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
            child: const Text('Tolak'),
          ),
          // Tombol Setujui
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateIuranStatus(iuranId, 'Lunas');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            child: const Text('Setujui'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Data Iuran?'),
        content: const Text('Data yang dihapus tidak dapat dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteIuran(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  String _formatRupiah(int nominal) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(nominal);
  }

  String _formatDate(String? date) { 
    if (date == null) return ''; 
    try {
      final dateTime = DateTime.parse(date);
      return DateFormat('dd MMM yyyy', 'id_ID').format(dateTime);
    } catch (e) {
      return date;
    }
  }

  // Helper baru untuk warna status
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Lunas':
        return const Color(0xFF10B981); // Hijau
      case 'Menunggu Verifikasi':
        return const Color(0xFF3B82F6); // Biru
      case 'Belum Lunas':
        return const Color(0xFFDC2626); // Merah
      default:
        return const Color(0xFF64748B); // Abu-abu
    }
  }
}