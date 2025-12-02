import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

// --- Painter Geometris (Konsisten dengan Dashboard) ---
class ModernPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03) // FIXED: withValues
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

class KegiatanPage extends StatefulWidget {
  final VoidCallback? onBackPressed;
  const KegiatanPage({super.key, this.onBackPressed});

  @override
  State<KegiatanPage> createState() => _KegiatanPageState();
}

class _KegiatanPageState extends State<KegiatanPage> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _allKegiatan = [];
  List<dynamic> _filteredKegiatan = [];
  bool _isLoading = true;

  // Animation & Controllers
  late TabController _tabController;
  late AnimationController _headerCtrl;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  final List<String> _filters = ['Semua', 'Akan Datang', 'Berlangsung', 'Selesai'];
  final List<String> _kategoriOptions = ['Rapat', 'Gotong Royong', 'Olahraga', 'Keagamaan', 'Sosial', 'Lainnya'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Setup Animasi Header
    _headerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic));

    _tabController.addListener(_filterKegiatan);
    _searchController.addListener(_filterKegiatan);

    _headerCtrl.forward();
    _loadKegiatan();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerCtrl.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadKegiatan() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiService.getKegiatan();
      if (res['success'] && mounted) {
        setState(() {
          _allKegiatan = res['data'] ?? [];
          _filterKegiatan();
        });
      }
    } catch (e) {
      _showSnackBar('Gagal memuat data kegiatan', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterKegiatan() {
    final query = _searchController.text.toLowerCase();
    final filter = _filters[_tabController.index];

    setState(() {
      _filteredKegiatan = _allKegiatan.where((k) {
        final nama = (k['nama_kegiatan'] ?? '').toString().toLowerCase();
        final lokasi = (k['lokasi'] ?? '').toString().toLowerCase();
        final kategori = (k['kategori'] ?? '').toString().toLowerCase();
        
        final matchesQuery = nama.contains(query) || lokasi.contains(query) || kategori.contains(query);

        if (filter == 'Semua') return matchesQuery;
        
        final status = _getStatusKegiatan(k['tanggal']?.toString() ?? '', k['waktu']?.toString() ?? '00:00');
        return matchesQuery && status == filter;
      }).toList();

      // Sort: Tanggal terdekat di atas
      _filteredKegiatan.sort((a, b) {
        final dateA = DateTime.tryParse('${a['tanggal']} ${a['waktu']}') ?? DateTime.now();
        final dateB = DateTime.tryParse('${b['tanggal']} ${b['waktu']}') ?? DateTime.now();
        return dateA.compareTo(dateB);
      });
    });
  }

  String _getStatusKegiatan(String tanggal, String waktu) {
    try {
      final now = DateTime.now();
      // Parsing format yyyy-MM-dd dan HH:mm:ss atau HH:mm
      final dateTimeStr = '$tanggal ${waktu.length > 5 ? waktu : "$waktu:00"}';
      final dateTime = DateTime.parse(dateTimeStr);
      
      final diff = dateTime.difference(now);

      if (dateTime.isBefore(now)) {
        // Jika selisihnya kurang dari 3 jam yang lalu, anggap masih berlangsung
        if (diff.inHours > -3) return 'Berlangsung'; 
        return 'Selesai';
      }
      
      // Jika hari ini
      if (dateTime.day == now.day && dateTime.month == now.month && dateTime.year == now.year) {
        return 'Akan Datang';
      }
      
      return 'Akan Datang';
    } catch (e) {
      return 'Akan Datang';
    }
  }

  // --- Helpers ---

  Color _getKategoriColor(String kategori) {
    switch (kategori) {
      case 'Gotong Royong': return const Color(0xFF10B981); // Green
      case 'Rapat': return const Color(0xFF3B82F6); // Blue
      case 'Perayaan': return const Color(0xFFEC4899); // Pink
      case 'Olahraga': return const Color(0xFFF59E0B); // Amber
      case 'Keagamaan': return const Color(0xFF8B5CF6); // Violet
      case 'Sosial': return const Color(0xFF06B6D4); // Cyan
      default: return const Color(0xFF64748B); // Slate
    }
  }

  IconData _getKategoriIcon(String kategori) {
    switch (kategori) {
      case 'Gotong Royong': return Icons.cleaning_services_rounded;
      case 'Rapat': return Icons.meeting_room_rounded;
      case 'Perayaan': return Icons.celebration_rounded;
      case 'Olahraga': return Icons.sports_soccer_rounded;
      case 'Keagamaan': return Icons.mosque_rounded;
      case 'Sosial': return Icons.groups_rounded;
      default: return Icons.event_rounded;
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      )
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
        backgroundColor: const Color(0xFF8B5CF6),
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Kegiatan Baru', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadKegiatan,
          color: const Color(0xFF8B5CF6),
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
                  ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6))))
                  : _filteredKegiatan.isEmpty
                      ? SliverFillRemaining(child: _buildEmptyState())
                      : SliverPadding(
                          padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, 8, isMobile ? 16 : 24, 80),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return _buildActivityCard(_filteredKegiatan[index], index);
                              },
                              childCount: _filteredKegiatan.length,
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
            color: const Color(0xFF1E293B).withValues(alpha: 0.4), // FIXED: withValues
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
                    color: Colors.white.withValues(alpha: 0.1), // FIXED: withValues
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
                      'Agenda Kegiatan',
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
                  color: Colors.white.withValues(alpha: 0.1), // FIXED: withValues
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)), // FIXED: withValues
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Cari kegiatan...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)), // FIXED: withValues
                    prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.7)), // FIXED: withValues
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
                  color: Colors.black.withValues(alpha: 0.05), // FIXED: withValues
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(Icons.event_note_rounded, size: 64, color: Colors.grey[300]),
          ),
          const SizedBox(height: 24),
          Text(
            'Belum ada kegiatan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Buat kegiatan baru untuk warga',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> item, int index) {
    final status = _getStatusKegiatan(item['tanggal']?.toString() ?? '', item['waktu']?.toString() ?? '00:00');
    final kategori = (item['kategori'] ?? 'Lainnya').toString();
    final color = _getKategoriColor(kategori);
    final icon = _getKategoriIcon(kategori);
    final dateFormatted = _formatDate(item['tanggal']?.toString() ?? '');

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
              color: Colors.black.withValues(alpha: 0.03), // FIXED: withValues
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1), // FIXED: withValues
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(icon, color: color, size: 28),
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
                                    color: status == 'Akan Datang' ? Colors.blue.withValues(alpha: 0.1) // FIXED: withValues
                                        : status == 'Berlangsung' ? Colors.green.withValues(alpha: 0.1) // FIXED: withValues
                                        : Colors.grey.withValues(alpha: 0.1), // FIXED: withValues
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: status == 'Akan Datang' ? Colors.blue 
                                          : status == 'Berlangsung' ? Colors.green 
                                          : Colors.grey,
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
                            const SizedBox(height: 4),
                            Text(
                              item['nama_kegiatan'] ?? 'Kegiatan Baru',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['penyelenggara'] ?? 'Pengurus RT',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
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
                    children: [
                      _infoChip(Icons.calendar_today_rounded, dateFormatted),
                      const SizedBox(width: 12),
                      _infoChip(Icons.access_time_rounded, item['waktu']?.toString() ?? '--:--'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                       const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF94A3B8)),
                       const SizedBox(width: 4),
                       Expanded(
                         child: Text(
                           item['lokasi'] ?? 'Lokasi tidak ditentukan',
                           style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                           maxLines: 1,
                           overflow: TextOverflow.ellipsis,
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

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF64748B)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
      ],
    );
  }

  // --- Dialogs & Functions ---

  void _showAddEditDialog({Map<String, dynamic>? data}) {
    final isEdit = data != null;
    final formKey = GlobalKey<FormState>();
    
    // Controllers
    final namaCtrl = TextEditingController(text: data?['nama_kegiatan']);
    final deskripsiCtrl = TextEditingController(text: data?['deskripsi']);
    final lokasiCtrl = TextEditingController(text: data?['lokasi']);
    final penyelenggaraCtrl = TextEditingController(text: data?['penyelenggara'] ?? 'Pengurus RT');
    
    // State variables for dialog
    String selectedKategori = data?['kategori'] ?? _kategoriOptions.first;
    DateTime? selectedDate = data != null ? DateTime.tryParse(data['tanggal'].toString()) : DateTime.now();
    
    // Parsing TimeOfDay dengan aman
    TimeOfDay? selectedTime;
    if (data != null && data['waktu'] != null) {
      try {
        final parts = data['waktu'].toString().split(':');
        selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } catch (e) {
        selectedTime = TimeOfDay.now();
      }
    } else {
      selectedTime = TimeOfDay.now();
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
                    isEdit ? 'Edit Kegiatan' : 'Buat Kegiatan Baru', 
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildLabel('Detail Utama'),
                        TextFormField(
                          controller: namaCtrl,
                          decoration: _inputDecor('Nama Kegiatan', Icons.event_note_rounded),
                          validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _kategoriOptions.contains(selectedKategori) ? selectedKategori : _kategoriOptions.first,
                          decoration: _inputDecor('Kategori', Icons.category_rounded),
                          items: _kategoriOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (v) => setModalState(() => selectedKategori = v!),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) setModalState(() => selectedDate = picked);
                                },
                                child: InputDecorator(
                                  decoration: _inputDecor('Tanggal', Icons.calendar_today_rounded),
                                  child: Text(selectedDate != null ? DateFormat('dd/MM/yyyy').format(selectedDate!) : 'Pilih Tanggal'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: selectedTime ?? TimeOfDay.now(),
                                  );
                                  if (picked != null) setModalState(() => selectedTime = picked);
                                },
                                child: InputDecorator(
                                  decoration: _inputDecor('Waktu', Icons.access_time_rounded),
                                  child: Text(selectedTime != null ? selectedTime!.format(context) : 'Pilih Waktu'),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildLabel('Lokasi & Info'),
                        TextFormField(
                          controller: lokasiCtrl,
                          decoration: _inputDecor('Lokasi', Icons.location_on_rounded),
                          validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: penyelenggaraCtrl,
                          decoration: _inputDecor('Penyelenggara', Icons.groups_rounded),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: deskripsiCtrl,
                          maxLines: 3,
                          decoration: _inputDecor('Deskripsi', Icons.description_rounded),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        if (selectedDate == null || selectedTime == null) {
                          _showSnackBar('Tanggal dan Waktu wajib diisi', Colors.orange);
                          return;
                        }
                        
                        Navigator.pop(context); // Tutup dialog

                        // Formatted Strings for API
                        final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate!);
                        final timeStr = '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}';

                        // PERBAIKAN: Memisahkan argumen untuk createKegiatan dan updateKegiatan
                        // Agar sesuai dengan error: "7 positional arguments expected"
                        dynamic res;
                        if (isEdit) {
                           res = await _apiService.updateKegiatan(
                             data!['id'].toString(), // Arg 1: ID
                             namaCtrl.text,          // Arg 2: Nama
                             selectedKategori,       // Arg 3: Kategori
                             dateStr,                // Arg 4: Tanggal
                             timeStr,                // Arg 5: Waktu
                             lokasiCtrl.text,        // Arg 6: Lokasi
                             penyelenggaraCtrl.text, // Arg 7: Penyelenggara
                             deskripsiCtrl.text      // Arg 8: Deskripsi
                           );
                        } else {
                          // FIX: Mengirim argumen secara terpisah, BUKAN sebagai Map
                          res = await _apiService.createKegiatan(
                            namaCtrl.text,           // Arg 1
                            selectedKategori,        // Arg 2
                            dateStr,                 // Arg 3
                            timeStr,                 // Arg 4
                            lokasiCtrl.text,         // Arg 5
                            penyelenggaraCtrl.text,  // Arg 6
                            deskripsiCtrl.text       // Arg 7
                          );
                        }

                        if (res['success']) {
                          _showSnackBar(isEdit ? 'Kegiatan diperbarui' : 'Kegiatan dibuat', Colors.green);
                          _loadKegiatan();
                        } else {
                          _showSnackBar(res['message'] ?? 'Gagal menyimpan', Colors.red);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text(isEdit ? 'Simpan Perubahan' : 'Buat Kegiatan', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            );
          }
        ),
      ),
    );
  }

  void _showDetailDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), // FIXED: withValues
              child: Icon(_getKategoriIcon(item['kategori'] ?? ''), color: const Color(0xFF8B5CF6)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item['nama_kegiatan'] ?? 'Detail',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow(Icons.category_rounded, 'Kategori', item['kategori'] ?? '-'),
              _detailRow(Icons.calendar_today_rounded, 'Tanggal', _formatDate(item['tanggal']?.toString() ?? '')),
              _detailRow(Icons.access_time_rounded, 'Waktu', item['waktu']?.toString() ?? '-'),
              _detailRow(Icons.location_on_rounded, 'Lokasi', item['lokasi'] ?? '-'),
              _detailRow(Icons.groups_rounded, 'Oleh', item['penyelenggara'] ?? '-'),
              const Divider(height: 24),
              const Text('Deskripsi:', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
              const SizedBox(height: 4),
              Text(item['deskripsi'] ?? 'Tidak ada deskripsi', style: const TextStyle(height: 1.5, color: Color(0xFF334155))),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup', style: TextStyle(color: Color(0xFF64748B))),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
                children: [
                  TextSpan(text: '$label: ', style: const TextStyle(color: Color(0xFF64748B))),
                  TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Kegiatan?'),
        content: const Text('Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final res = await _apiService.deleteKegiatan(id);
              if (res['success']) {
                _showSnackBar('Kegiatan dihapus', Colors.green);
                _loadKegiatan();
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
    );
  }

  String _formatDate(String date) {
    if (date.isEmpty) return '-';
    try {
      return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.parse(date));
    } catch (e) {
      return date;
    }
  }
}