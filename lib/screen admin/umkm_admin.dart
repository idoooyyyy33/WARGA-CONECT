import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class UMKMAdminPage extends StatefulWidget {
  final VoidCallback? onBackPressed;

  const UMKMAdminPage({super.key, this.onBackPressed});

  @override
  State<UMKMAdminPage> createState() => _UMKMAdminPageState();
}

class _UMKMAdminPageState extends State<UMKMAdminPage> {
  final ApiService _apiService = ApiService();
  List<dynamic> _umkmList = [];
  List<dynamic> _wargaList = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _apiService.getUMKMAdmin(),
        _apiService.getWargaAdmin(),
      ]);

      if (mounted) {
        setState(() {
          _isLoading = false;

          if (results[0]['success']) {
            _umkmList = results[0]['data'] is List ? results[0]['data'] : [];
          }

          if (results[1]['success']) {
            _wargaList = results[1]['data'] is List ? results[1]['data'] : [];
          }

          if (!results[0]['success']) {
            _showErrorSnackbar(
              results[0]['message'] ?? 'Gagal memuat data UMKM',
            );
          }
          if (!results[1]['success']) {
            _showErrorSnackbar(
              results[1]['message'] ?? 'Gagal memuat data warga',
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackbar('Terjadi kesalahan: $e');
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<dynamic> get _filteredUMKM {
    if (_searchQuery.isEmpty) {
      return _umkmList;
    }

    return _umkmList.where((umkm) {
      final nama = umkm['nama_usaha']?.toString().toLowerCase() ?? '';
      final pemilik = umkm['pemilik_id'] is Map
          ? umkm['pemilik_id']['nama_lengkap']?.toString().toLowerCase() ?? ''
          : '';
      final kategori = umkm['kategori']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return nama.contains(query) ||
          pemilik.contains(query) ||
          kategori.contains(query);
    }).toList();
  }

  Map<String, dynamic> get _stats {
    final total = _umkmList.length;

    final Map<String, int> categories = {};
    for (var umkm in _umkmList) {
      final kategori = umkm['kategori'] ?? 'Lainnya';
      categories[kategori] = (categories[kategori] ?? 0) + 1;
    }

    final sortedCategories = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'total': total,
      'categories': Map.fromEntries(sortedCategories.take(3)),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddUMKMDialog(),
        backgroundColor: const Color(0xFF06B6D4),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Tambah UMKM',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFF06B6D4),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildLargeHeader(isMobile)),

              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 24,
                    vertical: 12,
                  ),
                  child: _buildStatsCards(isMobile),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                  child: _buildSearchAndAddBar(),
                ),
              ),

              _isLoading
                  ? const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF06B6D4),
                        ),
                      ),
                    )
                  : _filteredUMKM.isEmpty
                  ? SliverFillRemaining(child: _buildEmptyState())
                  : SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        isMobile ? 16 : 24,
                        12,
                        isMobile ? 16 : 24,
                        80,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              _buildUMKMCard(_filteredUMKM[index], index),
                          childCount: _filteredUMKM.length,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLargeHeader(bool isMobile) {
    return Container(
      margin: EdgeInsets.all(isMobile ? 12 : 20),
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
        ),
        borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Material(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: widget.onBackPressed ?? () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Data UMKM',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kelola data usaha warga RT',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Cari nama usaha atau pemilik...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.white.withOpacity(0.8),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackToDashboardButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: widget.onBackPressed ?? () => Navigator.of(context).pop(),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF64748B),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Kembali ke Dashboard',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
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
              colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF06B6D4).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.store_rounded, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Data UMKM',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A202C),
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Kelola data usaha warga RT',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards(bool isMobile) {
    final stats = _stats;
    final categories = stats['categories'] as Map<String, int>;
    final topCategories = categories.entries.toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (isMobile) {
          return Column(
            children: [
              _buildStatCard(
                'Total UMKM',
                '${stats['total']}',
                Icons.store_rounded,
                const Color(0xFF06B6D4),
              ),
              const SizedBox(height: 12),
              if (topCategories.isNotEmpty)
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        topCategories[0].key,
                        '${topCategories[0].value}',
                        Icons.category_rounded,
                        const Color(0xFF10B981),
                      ),
                    ),
                    if (topCategories.length > 1) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          topCategories[1].key,
                          '${topCategories[1].value}',
                          Icons.category_rounded,
                          const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total UMKM',
                '${stats['total']}',
                Icons.store_rounded,
                const Color(0xFF06B6D4),
              ),
            ),
            if (topCategories.isNotEmpty) ...[
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  topCategories[0].key,
                  '${topCategories[0].value}',
                  Icons.category_rounded,
                  const Color(0xFF10B981),
                ),
              ),
              if (topCategories.length > 1) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    topCategories[1].key,
                    '${topCategories[1].value}',
                    Icons.category_rounded,
                    const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ],
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndAddBar() {
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
                hintText: 'Cari nama usaha atau pemilik...',
                hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Color(0xFF64748B),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: const Color(0xFF06B6D4),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () => _showAddUMKMDialog(),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 60),
          CircularProgressIndicator(color: Color(0xFF06B6D4), strokeWidth: 3),
          SizedBox(height: 16),
          Text(
            'Memuat data UMKM...',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUMKMList() {
    if (_filteredUMKM.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: _filteredUMKM.asMap().entries.map((entry) {
        final index = entry.key;
        final umkm = entry.value;
        return _buildUMKMCard(umkm, index);
      }).toList(),
    );
  }

  Widget _buildUMKMCard(dynamic umkm, int index) {
    final namaUsaha = umkm['nama_usaha'] ?? 'Tidak Diketahui';
    final namaPemilik = umkm['pemilik_id'] is Map
        ? umkm['pemilik_id']['nama_lengkap'] ?? 'Tidak Diketahui'
        : 'Tidak Diketahui';
    final kategori = umkm['kategori'] ?? 'Lainnya';
    final lokasi = umkm['lokasi'] ?? 'Tidak ada lokasi';
    final noHp = umkm['no_hp_usaha'] ?? '-';

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
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF06B6D4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.store_rounded,
                  color: Color(0xFF06B6D4),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      namaUsaha,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A202C),
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pemilik: $namaPemilik',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06B6D4).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        kategori,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF06B6D4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (noHp != '-') ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            size: 14,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            noHp,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            lokasi,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: Color(0xFF64748B),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == 'detail') {
                    _showUMKMDetail(umkm);
                  } else if (value == 'edit') {
                    _showEditUMKMDialog(umkm);
                  } else if (value == 'delete') {
                    _showDeleteConfirmation(umkm);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'detail',
                    child: Row(
                      children: [
                        Icon(
                          Icons.visibility_rounded,
                          size: 20,
                          color: Color(0xFF06B6D4),
                        ),
                        SizedBox(width: 12),
                        Text('Lihat Detail'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_rounded,
                          size: 20,
                          color: Color(0xFFF59E0B),
                        ),
                        SizedBox(width: 12),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_rounded,
                          size: 20,
                          color: Color(0xFFDC2626),
                        ),
                        SizedBox(width: 12),
                        Text('Hapus'),
                      ],
                    ),
                  ),
                ],
              ),
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
              color: const Color(0xFF06B6D4).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.store_rounded,
              size: 64,
              color: const Color(0xFF06B6D4).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Belum Ada Data UMKM',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A202C),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tambahkan UMKM pertama Anda',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddUMKMDialog(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tambah UMKM'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF06B6D4),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== CRUD OPERATIONS ====================

  void _showAddUMKMDialog() {
    final formKey = GlobalKey<FormState>();
    String? selectedPemilikId;
    final namaUsahaController = TextEditingController();
    final deskripsiController = TextEditingController();
    final noHpController = TextEditingController();
    final lokasiController = TextEditingController();

    String? selectedKategori;
    final kategoriLainnyaController = TextEditingController();
    bool showKategoriLainnya = false;

    if (_wargaList.isEmpty) {
      _showErrorSnackbar(
        'Data warga tidak ditemukan. Tidak bisa menambah UMKM.',
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF06B6D4).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: Color(0xFF06B6D4),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Tambah UMKM Baru',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A202C),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    DropdownButtonFormField<String>(
                      value: selectedPemilikId,
                      hint: const Text('Pilih Pemilik'),
                      decoration: const InputDecoration(
                        labelText: 'Pemilik',
                        prefixIcon: Icon(Icons.person_rounded),
                        border: OutlineInputBorder(),
                      ),
                      items: _wargaList.map((warga) {
                        return DropdownMenuItem<String>(
                          value: warga['_id'].toString(),
                          child: Text(warga['nama_lengkap'] ?? 'Warga Error'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        selectedPemilikId = value;
                      },
                      validator: (value) =>
                          value == null ? 'Pemilik harus dipilih' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: namaUsahaController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Usaha',
                        prefixIcon: Icon(Icons.business_rounded),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Nama usaha harus diisi'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: selectedKategori,
                      hint: const Text('Pilih Kategori'),
                      decoration: const InputDecoration(
                        labelText: 'Kategori',
                        prefixIcon: Icon(Icons.category_rounded),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Makanan',
                          child: Text('Makanan'),
                        ),
                        DropdownMenuItem(
                          value: 'Minuman',
                          child: Text('Minuman'),
                        ),
                        DropdownMenuItem(value: 'Jasa', child: Text('Jasa')),
                        DropdownMenuItem(
                          value: 'Kerajinan',
                          child: Text('Kerajinan'),
                        ),
                        DropdownMenuItem(
                          value: 'Lainnya',
                          child: Text('Lainnya'),
                        ),
                        DropdownMenuItem(
                          value: 'custom',
                          child: Text('-- Isi Sendiri --'),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedKategori = value;
                          showKategoriLainnya = (value == 'custom');
                          if (!showKategoriLainnya) {
                            kategoriLainnyaController.clear();
                          }
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Kategori harus dipilih' : null,
                    ),

                    if (showKategoriLainnya) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: kategoriLainnyaController,
                        decoration: const InputDecoration(
                          labelText: 'Kategori Lainnya',
                          prefixIcon: Icon(Icons.edit_rounded),
                          border: OutlineInputBorder(),
                          hintText: 'Masukkan kategori custom',
                        ),
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Kategori custom harus diisi'
                            : null,
                      ),
                    ],

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: deskripsiController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi',
                        prefixIcon: Icon(Icons.description_rounded),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: noHpController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'No. HP Usaha',
                        prefixIcon: Icon(Icons.phone_rounded),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: lokasiController,
                      decoration: const InputDecoration(
                        labelText: 'Lokasi',
                        prefixIcon: Icon(Icons.location_on_rounded),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                String finalKategori;
                                if (selectedKategori == 'custom') {
                                  finalKategori = kategoriLainnyaController.text
                                      .trim();
                                } else {
                                  finalKategori = selectedKategori!;
                                }

                                final result = await _apiService.createUMKM({
                                  'pemilik_id': selectedPemilikId,
                                  'nama_usaha': namaUsahaController.text,
                                  'deskripsi': deskripsiController.text,
                                  'kategori': finalKategori,
                                  'no_hp_usaha': noHpController.text,
                                  'lokasi': lokasiController.text,
                                });

                                if (mounted) {
                                  Navigator.pop(context);
                                  if (result['success']) {
                                    _showSuccessSnackbar(
                                      'UMKM baru berhasil ditambahkan',
                                    );
                                    _loadData();
                                  } else {
                                    _showErrorSnackbar(
                                      result['message'] ??
                                          'Gagal menambahkan UMKM',
                                    );
                                  }
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF06B6D4),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
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
      ),
    );
  }

  void _showEditUMKMDialog(dynamic umkm) {
    final formKey = GlobalKey<FormState>();

    String? selectedPemilikId = umkm['pemilik_id']?['_id']?.toString();
    final namaUsahaController = TextEditingController(
      text: umkm['nama_usaha'] ?? '',
    );
    final deskripsiController = TextEditingController(
      text: umkm['deskripsi'] ?? '',
    );
    final noHpController = TextEditingController(
      text: umkm['no_hp_usaha'] ?? '',
    );
    final lokasiController = TextEditingController(text: umkm['lokasi'] ?? '');

    String kategoriExisting = umkm['kategori'] ?? 'Lainnya';
    String? selectedKategori;
    final kategoriLainnyaController = TextEditingController();
    bool showKategoriLainnya = false;

    List<String> validKategori = [
      'Makanan',
      'Minuman',
      'Jasa',
      'Kerajinan',
      'Lainnya',
    ];
    if (validKategori.contains(kategoriExisting)) {
      selectedKategori = kategoriExisting;
    } else {
      selectedKategori = 'custom';
      kategoriLainnyaController.text = kategoriExisting;
      showKategoriLainnya = true;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
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
                          child: const Icon(
                            Icons.edit_rounded,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Edit UMKM',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A202C),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    DropdownButtonFormField<String>(
                      value: selectedPemilikId,
                      hint: const Text('Pilih Pemilik'),
                      decoration: const InputDecoration(
                        labelText: 'Pemilik',
                        prefixIcon: Icon(Icons.person_rounded),
                        border: OutlineInputBorder(),
                      ),
                      items: _wargaList.map((warga) {
                        return DropdownMenuItem<String>(
                          value: warga['_id'].toString(),
                          child: Text(warga['nama_lengkap'] ?? 'Warga Error'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        selectedPemilikId = value;
                      },
                      validator: (value) =>
                          value == null ? 'Pemilik harus dipilih' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: namaUsahaController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Usaha',
                        prefixIcon: Icon(Icons.business_rounded),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Nama usaha harus diisi'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: selectedKategori,
                      hint: const Text('Pilih Kategori'),
                      decoration: const InputDecoration(
                        labelText: 'Kategori',
                        prefixIcon: Icon(Icons.category_rounded),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Makanan',
                          child: Text('Makanan'),
                        ),
                        DropdownMenuItem(
                          value: 'Minuman',
                          child: Text('Minuman'),
                        ),
                        DropdownMenuItem(value: 'Jasa', child: Text('Jasa')),
                        DropdownMenuItem(
                          value: 'Kerajinan',
                          child: Text('Kerajinan'),
                        ),
                        DropdownMenuItem(
                          value: 'Lainnya',
                          child: Text('Lainnya'),
                        ),
                        DropdownMenuItem(
                          value: 'custom',
                          child: Text('-- Isi Sendiri --'),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedKategori = value;
                          showKategoriLainnya = (value == 'custom');
                          if (!showKategoriLainnya) {
                            kategoriLainnyaController.clear();
                          }
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Kategori harus dipilih' : null,
                    ),

                    if (showKategoriLainnya) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: kategoriLainnyaController,
                        decoration: const InputDecoration(
                          labelText: 'Kategori Lainnya',
                          prefixIcon: Icon(Icons.edit_rounded),
                          border: OutlineInputBorder(),
                          hintText: 'Masukkan kategori custom',
                        ),
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Kategori custom harus diisi'
                            : null,
                      ),
                    ],

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: deskripsiController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi',
                        prefixIcon: Icon(Icons.description_rounded),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: noHpController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'No. HP Usaha',
                        prefixIcon: Icon(Icons.phone_rounded),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: lokasiController,
                      decoration: const InputDecoration(
                        labelText: 'Lokasi',
                        prefixIcon: Icon(Icons.location_on_rounded),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                String finalKategori;
                                if (selectedKategori == 'custom') {
                                  finalKategori = kategoriLainnyaController.text
                                      .trim();
                                } else {
                                  finalKategori = selectedKategori!;
                                }

                                final result = await _apiService
                                    .updateUMKM(umkm['_id'], {
                                      'pemilik_id': selectedPemilikId,
                                      'nama_usaha': namaUsahaController.text,
                                      'deskripsi': deskripsiController.text,
                                      'kategori': finalKategori,
                                      'no_hp_usaha': noHpController.text,
                                      'lokasi': lokasiController.text,
                                    });

                                if (mounted) {
                                  Navigator.pop(context);
                                  if (result['success']) {
                                    _showSuccessSnackbar(
                                      'UMKM berhasil diperbarui',
                                    );
                                    _loadData();
                                  } else {
                                    _showErrorSnackbar(
                                      result['message'] ??
                                          'Gagal memperbarui UMKM',
                                    );
                                  }
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Update'),
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
      ),
    );
  }

  void _showDeleteConfirmation(dynamic umkm) {
    final namaUsaha = umkm['nama_usaha'] ?? 'UMKM ini';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.delete_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 10),
            Text('Konfirmasi Hapus'),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus "$namaUsaha"? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Batal',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final result = await _apiService.deleteUMKM(umkm['_id']);
              if (mounted) {
                Navigator.pop(context);
                if (result['success']) {
                  _showSuccessSnackbar('UMKM berhasil dihapus');
                  _loadData();
                } else {
                  _showErrorSnackbar(
                    result['message'] ?? 'Gagal menghapus UMKM',
                  );
                }
              }
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

  void _showUMKMDetail(dynamic umkm) {
    final namaUsaha = umkm['nama_usaha'] ?? 'Tidak Diketahui';
    final namaPemilik = umkm['pemilik_id'] is Map
        ? umkm['pemilik_id']['nama_lengkap'] ?? 'Tidak Diketahui'
        : 'Tidak Diketahui';
    final kategori = umkm['kategori'] ?? 'Lainnya';
    final deskripsi = umkm['deskripsi'] ?? 'Tidak ada deskripsi';
    final lokasi = umkm['lokasi'] ?? 'Tidak ada lokasi';
    final noHp = umkm['no_hp_usaha'] ?? '-';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06B6D4).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.store_rounded,
                        color: Color(0xFF06B6D4),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Detail UMKM',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A202C),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDetailRow(
                  'Nama Usaha',
                  namaUsaha,
                  Icons.business_rounded,
                ),
                const SizedBox(height: 16),
                _buildDetailRow('Pemilik', namaPemilik, Icons.person_rounded),
                const SizedBox(height: 16),
                _buildDetailRow('Kategori', kategori, Icons.category_rounded),
                const SizedBox(height: 16),
                _buildDetailRow(
                  'Deskripsi',
                  deskripsi,
                  Icons.description_rounded,
                ),
                const SizedBox(height: 16),
                _buildDetailRow('No. HP', noHp, Icons.phone_rounded),
                const SizedBox(height: 16),
                _buildDetailRow('Lokasi', lokasi, Icons.location_on_rounded),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Tutup'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF64748B)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1A202C),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
