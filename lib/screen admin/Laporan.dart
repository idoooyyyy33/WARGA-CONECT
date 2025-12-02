import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

// --- Painter yang sama dengan Dashboard untuk konsistensi ---
class ModernPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
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

class LaporanPage extends StatefulWidget {
  final VoidCallback? onBackPressed;
  const LaporanPage({super.key, this.onBackPressed});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  // Data
  List<dynamic> _allLaporan = [];
  List<dynamic> _filteredLaporan = [];
  bool _isLoading = true;
  String _selectedCategory = 'Semua';

  // Animation & Controllers
  late TabController _tabController;
  late AnimationController _headerAnimController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;

  final List<String> _statusFilters = ['Semua', 'Diterima', 'Diproses', 'Selesai', 'Ditolak'];
  final List<String> _categories = ['Semua', 'Infrastruktur', 'Keamanan', 'Kebersihan', 'Sosial', 'Lainnya'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusFilters.length, vsync: this);
    
    // Setup Animations
    _headerAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _headerFadeAnimation = CurvedAnimation(parent: _headerAnimController, curve: Curves.easeOut);
    _headerSlideAnimation = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerAnimController, curve: Curves.easeOutCubic));
    
    _headerAnimController.forward();

    // Listeners
    _tabController.addListener(_filterLaporan);
    _searchController.addListener(_filterLaporan);

    _loadLaporan();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerAnimController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLaporan() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getLaporan();
      if (response['success'] == true && mounted) {
        setState(() {
          _allLaporan = response['data'] ?? [];
          _filterLaporan();
        });
      }
    } catch (e) {
      _showSnackBar('Gagal memuat data laporan', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterLaporan() {
    final query = _searchController.text.toLowerCase();
    final statusFilter = _statusFilters[_tabController.index];

    setState(() {
      _filteredLaporan = _allLaporan.where((item) {
        // Filter Text (Judul / Pelapor)
        final judul = (item['judul'] ?? '').toString().toLowerCase();
        final pelapor = (item['nama_pelapor'] ?? '').toString().toLowerCase();
        final matchesQuery = judul.contains(query) || pelapor.contains(query);

        // Filter Status
        final status = (item['status'] ?? 'Diterima').toString();
        final matchesStatus = statusFilter == 'Semua' || status == statusFilter;

        // Filter Kategori
        final kategori = (item['kategori'] ?? 'Lainnya').toString();
        final matchesCategory = _selectedCategory == 'Semua' || kategori == _selectedCategory;

        return matchesQuery && matchesStatus && matchesCategory;
      }).toList();
      
      // Sort: Terbaru di atas
      _filteredLaporan.sort((a, b) {
        DateTime dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
        DateTime dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
        return dateB.compareTo(dateA);
      });
    });
  }

  // --- Helper Visuals ---
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Diterima': return const Color(0xFFF59E0B); // Amber
      case 'Diproses': return const Color(0xFF3B82F6); // Blue
      case 'Selesai': return const Color(0xFF10B981); // Emerald
      case 'Ditolak': return const Color(0xFFEF4444); // Red
      default: return const Color(0xFF64748B); // Slate
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Infrastruktur': return Icons.construction_rounded;
      case 'Keamanan': return Icons.local_police_rounded;
      case 'Kebersihan': return Icons.cleaning_services_rounded;
      case 'Sosial': return Icons.people_alt_rounded;
      default: return Icons.category_rounded;
    }
  }

  // --- UI Components ---

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadLaporan,
          color: const Color(0xFF0F172A),
          child: CustomScrollView(
            slivers: [
              // 1. Animated Header
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _headerFadeAnimation,
                  child: SlideTransition(
                    position: _headerSlideAnimation,
                    child: _buildHeader(isMobile),
                  ),
                ),
              ),

              // 2. Statistics Summary
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 8),
                  child: _buildStatisticsCards(isMobile),
                ),
              ),

              // 3. Category Filter Chips
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 12),
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            setState(() {
                              _selectedCategory = cat;
                              _filterLaporan();
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor: const Color(0xFF0F172A),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF64748B),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
                            ),
                          ),
                          checkmarkColor: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // 4. Laporan List
              _isLoading
                  ? const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator(color: Color(0xFF0F172A))),
                    )
                  : _filteredLaporan.isEmpty
                      ? SliverFillRemaining(child: _buildEmptyState())
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return _buildLaporanCard(_filteredLaporan[index], isMobile, index);
                            },
                            childCount: _filteredLaporan.length,
                          ),
                        ),
              
              const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      margin: EdgeInsets.all(isMobile ? 12 : 20),
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
        ),
        borderRadius: BorderRadius.circular(isMobile ? 20 : 28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.4),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: ModernPatternPainter())),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row with Back Button
              Row(
                children: [
                  Material(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: widget.onBackPressed ?? () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Manajemen Laporan',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Cari laporan atau pelapor...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.7)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Tab Bar
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  labelColor: const Color(0xFF0F172A),
                  unselectedLabelColor: Colors.white.withOpacity(0.7),
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  dividerColor: Colors.transparent,
                  tabs: _statusFilters.map((text) => Tab(text: text)).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards(bool isMobile) {
    int pending = _allLaporan.where((l) => l['status'] == 'Diterima' || l['status'] == 'Diproses').length;
    int selesai = _allLaporan.where((l) => l['status'] == 'Selesai').length;
    int total = _allLaporan.length;

    return Row(
      children: [
        Expanded(child: _buildStatItem('Total', total.toString(), Colors.indigo, isMobile)),
        SizedBox(width: isMobile ? 8 : 16),
        Expanded(child: _buildStatItem('Aktif', pending.toString(), Colors.orange, isMobile)),
        SizedBox(width: isMobile ? 8 : 16),
        Expanded(child: _buildStatItem('Selesai', selesai.toString(), Colors.green, isMobile)),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, MaterialColor color, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 18 : 22,
              fontWeight: FontWeight.w900,
              color: color.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 11 : 12,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLaporanCard(Map<String, dynamic> item, bool isMobile, int index) {
    final status = (item['status'] ?? 'Diterima').toString();
    final color = _getStatusColor(status);
    final category = (item['kategori'] ?? 'Lainnya').toString();
    final date = _formatDate(item['created_at']);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 50)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () => _showDetailDialog(item),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Icon
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _getCategoryIcon(category),
                          color: const Color(0xFF475569),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: color.withOpacity(0.2)),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                ),
                                Text(
                                  date,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item['judul'] ?? 'Tanpa Judul',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['nama_pelapor'] ?? 'Anonim',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (item['gambar'] != null && item['gambar'].toString().isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: Icon(Icons.image_outlined, size: 20, color: Color(0xFF64748B)),
                        ),
                      TextButton.icon(
                        onPressed: () => _showUpdateStatusDialog(item),
                        icon: const Icon(Icons.edit_note_rounded, size: 18),
                        label: const Text('Tindak Lanjut'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF3B82F6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          backgroundColor: const Color(0xFFEFF6FF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(Icons.check_circle_outline_rounded, size: 64, color: Colors.grey[300]),
          ),
          const SizedBox(height: 24),
          Text(
            'Tidak ada laporan ditemukan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Coba ubah filter atau kata kunci pencarian',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  // --- Dialogs ---

  void _showDetailDialog(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  // Status & Icon Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(_getCategoryIcon(item['kategori'] ?? ''), size: 32, color: const Color(0xFF0F172A)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['kategori'] ?? 'Umum',
                              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['judul'] ?? 'Detail Laporan',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Image Placeholder (Implement real image logic here)
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: item['gambar'] != null && item['gambar'].toString().isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              item['gambar'], // Pastikan URL valid
                              fit: BoxFit.cover,
                              errorBuilder: (_,__,___) => const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image_rounded, color: Colors.grey, size: 40),
                                  Text('Gagal memuat gambar', style: TextStyle(color: Colors.grey))
                                ],
                              ),
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_not_supported_rounded, size: 48, color: Color(0xFFCBD5E1)),
                              SizedBox(height: 8),
                              Text('Tidak ada lampiran foto', style: TextStyle(color: Color(0xFF94A3B8))),
                            ],
                          ),
                  ),
                  const SizedBox(height: 24),

                  // Details
                  _buildDetailItem(Icons.person_outline, 'Pelapor', item['nama_pelapor'] ?? 'Anonim'),
                  _buildDetailItem(Icons.calendar_today_outlined, 'Tanggal', _formatDate(item['created_at'])),
                  _buildDetailItem(Icons.location_on_outlined, 'Lokasi', item['lokasi'] ?? 'Tidak disebutkan'),
                  
                  const SizedBox(height: 24),
                  const Text('Deskripsi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const SizedBox(height: 8),
                  Text(
                    item['deskripsi'] ?? 'Tidak ada deskripsi.',
                    style: const TextStyle(fontSize: 15, height: 1.6, color: Color(0xFF475569)),
                  ),

                  // Tanggapan Section
                  if (item['tanggapan'] != null && item['tanggapan'].toString().isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.admin_panel_settings_rounded, size: 20, color: Color(0xFF059669)),
                              SizedBox(width: 8),
                              Text('Tanggapan Admin', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['tanggapan'],
                            style: const TextStyle(color: Color(0xFF065F46), height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 100), // Spacing for floating button
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
            ],
          ),
        ],
      ),
    );
  }

  void _showUpdateStatusDialog(Map<String, dynamic> item) {
    String selectedStatus = item['status'] ?? 'Diterima';
    final tanggapanCtrl = TextEditingController(text: item['tanggapan']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Tindak Lanjut Laporan', style: TextStyle(fontWeight: FontWeight.bold)),
        content: StatefulBuilder(
          builder: (context, setDialogState) => SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Update Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _statusFilters.where((s) => s != 'Semua').map((status) {
                      final isSelected = selectedStatus == status;
                      final color = _getStatusColor(status);
                      return ChoiceChip(
                        label: Text(status),
                        selected: isSelected,
                        onSelected: (val) => setDialogState(() => selectedStatus = status),
                        selectedColor: color.withOpacity(0.2),
                        backgroundColor: Colors.grey[100],
                        labelStyle: TextStyle(
                          color: isSelected ? color : Colors.grey[700],
                          fontWeight: FontWeight.bold,
                        ),
                        side: BorderSide(
                          color: isSelected ? color : Colors.transparent,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text('Tanggapan Admin', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: tanggapanCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Tulis pesan untuk pelapor...',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _confirmDelete(item['id'].toString()),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus Laporan'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              _handleUpdateStatus(item['id'], selectedStatus, tanggapanCtrl.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Simpan Perubahan'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUpdateStatus(dynamic id, String status, String tanggapan) async {
    // Tampilkan loading overlay atau indicator jika perlu
    final result = await _apiService.updateStatusLaporan(id, status, tanggapan);
    if (result['success']) {
      _showSnackBar('Laporan berhasil diperbarui', Colors.green);
      _loadLaporan();
    } else {
      _showSnackBar(result['message'] ?? 'Gagal memperbarui laporan', Colors.red);
    }
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Laporan?'),
        content: const Text('Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close confirm dialog
              Navigator.pop(context); // Close update dialog
              final res = await _apiService.deleteLaporan(id);
              if (res['success'] == true) {
                _showSnackBar('Laporan dihapus', Colors.green);
                _loadLaporan();
              } else {
                _showSnackBar('Gagal menghapus', Colors.red);
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return dateString;
    }
  }
}