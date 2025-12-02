import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

// --- Painter Geometris (Konsisten dengan Dashboard) ---
class ModernPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
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

class PengumumanPage extends StatefulWidget {
  final VoidCallback? onBackPressed;
  const PengumumanPage({super.key, this.onBackPressed});

  @override
  State<PengumumanPage> createState() => _PengumumanPageState();
}

class _PengumumanPageState extends State<PengumumanPage> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _allPengumuman = [];
  List<dynamic> _filteredPengumuman = [];
  bool _isLoading = true;

  // Animation & Controllers
  late TabController _tabController;
  late AnimationController _headerCtrl;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  final List<String> _filters = ['Semua', 'Penting', 'Urgent', 'Normal'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Setup Animasi Header
    _headerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic));

    _tabController.addListener(_filterPengumuman);
    _searchController.addListener(_filterPengumuman);

    _headerCtrl.forward();
    _loadPengumuman();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerCtrl.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPengumuman() async {
    setState(() => _isLoading = true);
    try {
      final result = await _apiService.getPengumuman();
      if (result['success'] && mounted) {
        setState(() {
          _allPengumuman = result['data'] ?? [];
          _filterPengumuman();
        });
      }
    } catch (e) {
      _showSnackBar('Gagal memuat data: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterPengumuman() {
    final query = _searchController.text.toLowerCase();
    final filter = _filters[_tabController.index];

    setState(() {
      _filteredPengumuman = _allPengumuman.where((item) {
        final judul = item['judul']?.toString().toLowerCase() ?? '';
        final isi = item['isi']?.toString().toLowerCase() ?? '';
        final prioritas = item['prioritas']?.toString().toLowerCase() ?? 'normal';

        final matchesQuery = judul.contains(query) || isi.contains(query);
        
        if (filter == 'Semua') return matchesQuery;
        return matchesQuery && prioritas == filter.toLowerCase();
      }).toList();

      // Sort: Terbaru di atas (asumsi created_at atau tanggal ada)
      _filteredPengumuman.sort((a, b) {
        final dateA = DateTime.tryParse(a['created_at'] ?? a['tanggal'] ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['created_at'] ?? b['tanggal'] ?? '') ?? DateTime.now();
        return dateB.compareTo(dateA);
      });
    });
  }

  // --- Helpers ---

  Color _getPriorityColor(String prioritas) {
    switch (prioritas.toLowerCase()) {
      case 'urgent': return const Color(0xFFDC2626); // Red
      case 'penting': return const Color(0xFFF59E0B); // Amber
      default: return const Color(0xFF10B981); // Emerald/Normal
    }
  }

  IconData _getPriorityIcon(String prioritas) {
    switch (prioritas.toLowerCase()) {
      case 'urgent': return Icons.gpp_maybe_rounded;
      case 'penting': return Icons.notification_important_rounded;
      default: return Icons.info_rounded;
    }
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

  // --- UI Build ---

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: const Color(0xFF10B981),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Buat Pengumuman', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPengumuman,
          color: const Color(0xFF10B981),
          child: CustomScrollView(
            slivers: [
              // Header Gradient
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _headerFade,
                  child: SlideTransition(
                    position: _headerSlide,
                    child: _buildHeader(isMobile),
                  ),
                ),
              ),

              // Filter Tabs
              SliverToBoxAdapter(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 8),
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicator: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFF64748B),
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    dividerColor: Colors.transparent,
                    padding: const EdgeInsets.all(4),
                    tabs: _filters.map((f) => Tab(text: f)).toList(),
                  ),
                ),
              ),

              // List Content
              _isLoading
                  ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Color(0xFF10B981))))
                  : _filteredPengumuman.isEmpty
                      ? SliverFillRemaining(child: _buildEmptyState())
                      : SliverPadding(
                          padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, 8, isMobile ? 16 : 24, 80),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildPengumumanCard(_filteredPengumuman[index], index),
                              childCount: _filteredPengumuman.length,
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
            color: const Color(0xFF1E293B).withValues(alpha: 0.4),
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
              Row(
                children: [
                  Material(
                    color: Colors.white.withValues(alpha: 0.1),
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
                      'Papan Pengumuman',
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
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Cari info warga...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.7)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ),
            ],
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            // FIXED: Mengganti ikon yang error
            child: Icon(Icons.notifications_off_rounded, size: 64, color: Colors.grey[300]),
          ),
          const SizedBox(height: 24),
          Text(
            'Belum ada pengumuman',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Bagikan informasi penting kepada warga',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildPengumumanCard(Map<String, dynamic> item, int index) {
    final judul = item['judul']?.toString() ?? 'Tanpa Judul';
    final isi = item['isi']?.toString() ?? '';
    final tanggal = _formatDate(item['tanggal'] ?? item['created_at']);
    final prioritas = item['prioritas']?.toString() ?? 'Normal';
    
    final color = _getPriorityColor(prioritas);
    final icon = _getPriorityIcon(prioritas);

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
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () => _showAddEditDialog(data: item), // Tap to edit for convenience
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    prioritas.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF94A3B8)),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 18), SizedBox(width: 8), Text('Edit')])),
                                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_rounded, color: Colors.red, size: 18), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: Colors.red))])),
                                  ],
                                  onSelected: (val) {
                                    if (val == 'edit') _showAddEditDialog(data: item);
                                    if (val == 'delete') _confirmDelete(item['id'].toString());
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              judul,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isi,
                    style: const TextStyle(color: Color(0xFF64748B), height: 1.5),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 6),
                      Text(
                        tanggal,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
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

  // --- Input & Actions ---

  void _showAddEditDialog({Map<String, dynamic>? data}) {
    final isEdit = data != null;
    final formKey = GlobalKey<FormState>();

    final judulCtrl = TextEditingController(text: data?['judul']);
    final isiCtrl = TextEditingController(text: data?['isi']);
    final penjelasanCtrl = TextEditingController(text: data?['penjelasan']);
    String selectedPrioritas = data?['prioritas']?.toString().toLowerCase() ?? 'normal';
    // Normalisasi prioritas agar sesuai dengan ChoiceChip values
    if (!['normal', 'penting', 'urgent'].contains(selectedPrioritas)) {
      selectedPrioritas = 'normal';
    }

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
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isEdit ? 'Edit Pengumuman' : 'Buat Pengumuman',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView(
                      children: [
                        TextFormField(
                          controller: judulCtrl,
                          decoration: _inputDecor('Judul', Icons.title_rounded),
                          validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: isiCtrl,
                          maxLines: 5,
                          decoration: _inputDecor('Isi Pengumuman', Icons.description_rounded),
                          validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: 16),
                        const Text('Prioritas', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          children: ['normal', 'penting', 'urgent'].map((p) {
                            final isSelected = selectedPrioritas == p;
                            final color = _getPriorityColor(p);
                            return ChoiceChip(
                              label: Text(p[0].toUpperCase() + p.substring(1)),
                              selected: isSelected,
                              onSelected: (val) => setModalState(() => selectedPrioritas = p),
                              selectedColor: color.withValues(alpha: 0.2),
                              backgroundColor: Colors.white,
                              labelStyle: TextStyle(
                                color: isSelected ? color : const Color(0xFF64748B),
                                fontWeight: FontWeight.bold,
                              ),
                              side: BorderSide(color: isSelected ? color : const Color(0xFFE2E8F0)),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: penjelasanCtrl,
                          decoration: _inputDecor('Penjelasan Tambahan (Opsional)', Icons.info_outline_rounded),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(context);
                        
                        dynamic result;
                        if (isEdit) {
                          // Gunakan argumen terpisah sesuai API Service
                          result = await _apiService.updatePengumuman(
                            data!['id'].toString(),
                            judulCtrl.text,
                            isiCtrl.text,
                            selectedPrioritas,
                            penjelasanCtrl.text
                          );
                        } else {
                          // Gunakan argumen terpisah sesuai API Service
                          result = await _apiService.createPengumuman(
                            judulCtrl.text,
                            isiCtrl.text,
                            selectedPrioritas,
                            penjelasanCtrl.text
                          );
                        }

                        if (result['success']) {
                          _showSnackBar(isEdit ? 'Berhasil diperbarui' : 'Berhasil dibuat', Colors.green);
                          _loadPengumuman();
                        } else {
                          _showSnackBar(result['message'] ?? 'Gagal menyimpan', Colors.red);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text(isEdit ? 'Simpan Perubahan' : 'Terbitkan', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Pengumuman?'),
        content: const Text('Data yang dihapus tidak dapat dikembalikan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await _apiService.deletePengumuman(id);
              if (result['success']) {
                _showSnackBar('Pengumuman dihapus', Colors.green);
                _loadPengumuman();
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

  InputDecoration _inputDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF94A3B8)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return 'Tanggal tidak tersedia';
    try {
      final dateTime = DateTime.parse(date);
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dateTime);
    } catch (e) {
      return date;
    }
  }
}