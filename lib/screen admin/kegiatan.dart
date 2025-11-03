import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';

class KegiatanPage extends StatefulWidget {
  final VoidCallback? onBackPressed;

  const KegiatanPage({super.key, this.onBackPressed});

  @override
  State<KegiatanPage> createState() => _KegiatanPageState();
}

class _KegiatanPageState extends State<KegiatanPage> {
  final ApiService _apiService = ApiService();
  List<dynamic> _kegiatanList = [];
  bool _isLoading = true;
  String _selectedFilter = 'Semua';
  String _searchQuery = '';

  final List<String> _filterOptions = ['Semua', 'Akan Datang', 'Berlangsung', 'Selesai'];
  final List<String> _kategoriOptions = [
    'Gotong Royong',
    'Rapat',
    'Perayaan',
    'Olahraga',
    'Keagamaan',
    'Lainnya'
  ];

  @override
  void initState() {
    super.initState();
    _loadKegiatan();
  }

  Future<void> _loadKegiatan() async {
    setState(() => _isLoading = true);
    try {
      final result = await _apiService.getKegiatan();
      if (result['success'] && mounted) {
        setState(() {
          _kegiatanList = result['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteKegiatan(String id) async {
    try {
      final result = await _apiService.deleteKegiatan(id);
      if (result['success']) {
        _showSnackBar('Kegiatan berhasil dihapus', isError: false);
        _loadKegiatan();
      } else {
        _showSnackBar(result['message'] ?? 'Gagal menghapus', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFDC2626) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _getStatusKegiatan(String tanggal, String waktu) {
    try {
      final now = DateTime.now();
      final kegiatanDate = DateTime.parse('$tanggal $waktu');
      
      if (kegiatanDate.isAfter(now)) {
        return 'Akan Datang';
      } else if (kegiatanDate.day == now.day && 
                 kegiatanDate.month == now.month && 
                 kegiatanDate.year == now.year) {
        return 'Berlangsung';
      } else {
        return 'Selesai';
      }
    } catch (e) {
      return 'Akan Datang';
    }
  }

  List<dynamic> get _filteredKegiatan {
    var filtered = _kegiatanList;

    if (_selectedFilter != 'Semua') {
      filtered = filtered.where((item) {
        final status = _getStatusKegiatan(
          item['tanggal']?.toString() ?? '',
          item['waktu']?.toString() ?? '00:00',
        );
        return status == _selectedFilter;
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        final nama = item['nama_kegiatan']?.toString().toLowerCase() ?? '';
        final kategori = item['kategori']?.toString().toLowerCase() ?? '';
        final lokasi = item['lokasi']?.toString().toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        return nama.contains(query) || kategori.contains(query) || lokasi.contains(query);
      }).toList();
    }

    return filtered;
  }

  Map<String, int> get _statusCounts {
    final counts = {'Akan Datang': 0, 'Berlangsung': 0, 'Selesai': 0};
    for (var item in _kegiatanList) {
      final status = _getStatusKegiatan(
        item['tanggal']?.toString() ?? '',
        item['waktu']?.toString() ?? '00:00',
      );
      counts[status] = (counts[status] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBackToDashboardButton(),
        _buildHeader(),
        const SizedBox(height: 24),
        _buildStatusCards(),
        const SizedBox(height: 24),
        _buildSearchAndFilter(),
        const SizedBox(height: 24),
        _isLoading ? _buildLoadingState() : _buildKegiatanList(),
      ],
    );
  }

  Widget _buildBackToDashboardButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (widget.onBackPressed != null) {
                widget.onBackPressed!();
              } else {
                Navigator.of(context).pop();
              }
            },
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
              colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.event_rounded, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kegiatan RT',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A202C),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_kegiatanList.length} kegiatan terjadwal',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _showAddEditDialog(),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('Buat Kegiatan'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B5CF6),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCards() {
    final counts = _statusCounts;
    return Row(
      children: [
        Expanded(
          child: _buildStatusCard(
            'Akan Datang',
            counts['Akan Datang'] ?? 0,
            Icons.upcoming_rounded,
            const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatusCard(
            'Berlangsung',
            counts['Berlangsung'] ?? 0,
            Icons.play_circle_rounded,
            const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatusCard(
            'Selesai',
            counts['Selesai'] ?? 0,
            Icons.check_circle_rounded,
            const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(String title, int count, IconData icon, Color color) {
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
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -0.5,
            ),
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

  Widget _buildSearchAndFilter() {
    return Row(
      children: [
        Expanded(
          child: Container(
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
                hintText: 'Cari kegiatan...',
                hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF64748B)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
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

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          const CircularProgressIndicator(
            color: Color(0xFF8B5CF6),
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

  Widget _buildKegiatanList() {
    if (_filteredKegiatan.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredKegiatan.length,
      itemBuilder: (context, index) {
        final item = _filteredKegiatan[index];
        return _buildKegiatanCard(item, index);
      },
    );
  }

  Widget _buildKegiatanCard(Map<String, dynamic> item, int index) {
    final namaKegiatan = item['nama_kegiatan']?.toString() ?? 'Tanpa Nama';
    final deskripsi = item['deskripsi']?.toString() ?? '';
    final kategori = item['kategori']?.toString() ?? 'Lainnya';
    final tanggal = item['tanggal']?.toString() ?? '';
    final waktu = item['waktu']?.toString() ?? '';
    final lokasi = item['lokasi']?.toString() ?? '';
    final penyelenggara = item['penyelenggara']?.toString() ?? 'RT';

    final status = _getStatusKegiatan(tanggal, waktu);
    
    Color statusColor;
    IconData statusIcon;
    
    switch (status) {
      case 'Berlangsung':
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.play_circle_rounded;
        break;
      case 'Selesai':
        statusColor = const Color(0xFF64748B);
        statusIcon = Icons.check_circle_rounded;
        break;
      default:
        statusColor = const Color(0xFF3B82F6);
        statusIcon = Icons.upcoming_rounded;
    }

    Color kategoriColor;
    IconData kategoriIcon;

    switch (kategori.toLowerCase()) {
      case 'gotong royong':
        kategoriColor = const Color(0xFF10B981);
        kategoriIcon = Icons.cleaning_services_rounded;
        break;
      case 'rapat':
        kategoriColor = const Color(0xFF3B82F6);
        kategoriIcon = Icons.meeting_room_rounded;
        break;
      case 'perayaan':
        kategoriColor = const Color(0xFFEC4899);
        kategoriIcon = Icons.celebration_rounded;
        break;
      case 'olahraga':
        kategoriColor = const Color(0xFFF59E0B);
        kategoriIcon = Icons.sports_soccer_rounded;
        break;
      case 'keagamaan':
        kategoriColor = const Color(0xFF8B5CF6);
        kategoriIcon = Icons.mosque_rounded;
        break;
      default:
        kategoriColor = const Color(0xFF64748B);
        kategoriIcon = Icons.event_rounded;
    }

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
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(statusIcon, size: 16, color: statusColor),
                  const SizedBox(width: 8),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF64748B), size: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'detail',
                        child: Row(
                          children: [
                            Icon(Icons.visibility_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Lihat Detail'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_rounded, size: 18, color: Color(0xFFDC2626)),
                            SizedBox(width: 8),
                            Text('Hapus', style: TextStyle(color: Color(0xFFDC2626))),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'detail') {
                        _showDetailDialog(item);
                      } else if (value == 'edit') {
                        _showAddEditDialog(data: item);
                      } else if (value == 'delete') {
                        _showDeleteDialog(item['id']);
                      }
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kategoriColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(kategoriIcon, color: kategoriColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              namaKegiatan,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A202C),
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: kategoriColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                kategori,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: kategoriColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    deskripsi,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 14, color: const Color(0xFF94A3B8)),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(tanggal),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.access_time_rounded, size: 14, color: const Color(0xFF94A3B8)),
                      const SizedBox(width: 6),
                      Text(
                        waktu,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 14, color: const Color(0xFF94A3B8)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          lokasi,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.person_rounded, size: 14, color: const Color(0xFF94A3B8)),
                      const SizedBox(width: 6),
                      Text(
                        penyelenggara,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
              color: const Color(0xFF8B5CF6).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_rounded,
              size: 64,
              color: const Color(0xFF8B5CF6).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Belum Ada Kegiatan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A202C),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter != 'Semua'
                ? 'Tidak ada kegiatan dengan status $_selectedFilter'
                : 'Klik "Buat Kegiatan" untuk menambah jadwal baru',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.event_rounded, color: Color(0xFF8B5CF6), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Detail Kegiatan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A202C),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailItem('Nama Kegiatan', item['nama_kegiatan']?.toString() ?? '-'),
                      _buildDetailItem('Kategori', item['kategori']?.toString() ?? '-'),
                      _buildDetailItem('Tanggal', _formatDate(item['tanggal']?.toString() ?? '')),
                      _buildDetailItem('Waktu', item['waktu']?.toString() ?? '-'),
                      _buildDetailItem('Lokasi', item['lokasi']?.toString() ?? '-'),
                      _buildDetailItem('Penyelenggara', item['penyelenggara']?.toString() ?? '-'),
                      _buildDetailItem('Deskripsi', item['deskripsi']?.toString() ?? '-', isLong: true),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {bool isLong = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1A202C),
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog({Map<String, dynamic>? data}) {
    final isEdit = data != null;
    final namaController = TextEditingController(text: data?['nama_kegiatan'] ?? '');
    final deskripsiController = TextEditingController(text: data?['deskripsi'] ?? '');
    final lokasiController = TextEditingController(text: data?['lokasi'] ?? '');
    final penyelenggaraController = TextEditingController(text: data?['penyelenggara'] ?? 'RT');
    String selectedKategori = data?['kategori'] ?? 'Lainnya';
    DateTime selectedDate = data?['tanggal'] != null 
        ? DateTime.parse(data!['tanggal']) 
        : DateTime.now();
    TimeOfDay selectedTime = data?['waktu'] != null
        ? TimeOfDay(
            hour: int.parse(data!['waktu'].split(':')[0]),
            minute: int.parse(data!['waktu'].split(':')[1]),
          )
        : TimeOfDay.now();

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
                          color: const Color(0xFF8B5CF6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.event_rounded, color: Color(0xFF8B5CF6), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isEdit ? 'Edit Kegiatan' : 'Buat Kegiatan Baru',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A202C),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: namaController,
                    decoration: InputDecoration(
                      labelText: 'Nama Kegiatan',
                      hintText: 'Masukkan nama kegiatan',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedKategori,
                    decoration: InputDecoration(
                      labelText: 'Kategori',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                    items: _kategoriOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setDialogState(() => selectedKategori = newValue);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: deskripsiController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Deskripsi',
                      hintText: 'Masukkan deskripsi kegiatan',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2030),
                            );
                            if (pickedDate != null) {
                              setDialogState(() => selectedDate = pickedDate);
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Tanggal',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              prefixIcon: const Icon(Icons.calendar_today_rounded),
                            ),
                            child: Text(
                              DateFormat('dd MMM yyyy', 'id_ID').format(selectedDate),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (pickedTime != null) {
                              setDialogState(() => selectedTime = pickedTime);
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Waktu',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              prefixIcon: const Icon(Icons.access_time_rounded),
                            ),
                            child: Text(
                              selectedTime.format(context),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: lokasiController,
                    decoration: InputDecoration(
                      labelText: 'Lokasi',
                      hintText: 'Masukkan lokasi kegiatan',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      prefixIcon: const Icon(Icons.location_on_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: penyelenggaraController,
                    decoration: InputDecoration(
                      labelText: 'Penyelenggara',
                      hintText: 'Masukkan penyelenggara',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      prefixIcon: const Icon(Icons.person_rounded),
                    ),
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
                          onPressed: () async {
                            if (namaController.text.isEmpty || lokasiController.text.isEmpty) {
                              _showSnackBar('Nama dan lokasi harus diisi', isError: true);
                              return;
                            }

                            final tanggal = DateFormat('yyyy-MM-dd').format(selectedDate);
                            final waktu = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

                            try {
                              final result = isEdit
                                  ? await _apiService.updateKegiatan(
                                      data['id'],
                                      namaController.text,
                                      deskripsiController.text,
                                      tanggal,
                                      waktu,
                                      lokasiController.text,
                                      selectedKategori,
                                      penyelenggaraController.text,
                                    )
                                  : await _apiService.createKegiatan(
                                      namaController.text,
                                      deskripsiController.text,
                                      tanggal,
                                      waktu,
                                      lokasiController.text,
                                      selectedKategori,
                                      penyelenggaraController.text,
                                    );

                              if (result['success']) {
                                Navigator.pop(ctx);
                                _showSnackBar(
                                  isEdit ? 'Kegiatan berhasil diupdate' : 'Kegiatan berhasil dibuat',
                                  isError: false,
                                );
                                _loadKegiatan();
                              } else {
                                _showSnackBar(result['message'] ?? 'Gagal menyimpan', isError: true);
                              }
                            } catch (e) {
                              _showSnackBar('Error: $e', isError: true);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(isEdit ? 'Update' : 'Simpan'),
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

  void _showDeleteDialog(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Kegiatan?'),
        content: const Text('Kegiatan yang dihapus tidak dapat dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteKegiatan(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String date) {
    try {
      final dateTime = DateTime.parse(date);
      return DateFormat('dd MMMM yyyy', 'id_ID').format(dateTime);
    } catch (e) {
      return date;
    }
  }
}