import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'pengumuman.dart';
import 'Laporan.dart';
import 'iuran.dart';
import 'kegiatan.dart';
import 'umkm_admin.dart';
import 'warga_admin.dart';
import 'surat_pengantar_admin.dart';
import '../screen user/announcements_screen.dart';
import '../screen user/activities_screen.dart';
import '../screen user/umkm_screen.dart';
import '../screen user/reports_screen.dart';
import '../screen user/dashboard_screen.dart';
import '../screen user/payments_screen.dart';
import 'dart:math' show cos, sin;

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _headerAnimController;
  late AnimationController _contentAnimController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  Map<String, dynamic>? _stats;

  // --- PERUBAHAN ---
  // Menambahkan state untuk menampung data aktivitas dan status loading-nya
  List<dynamic> _aktivitasList = [];
  bool _isAktivitasLoading = true;
  // --- AKHIR PERUBAHAN ---

  final List<Map<String, dynamic>> _menuItems = [
    {
      'title': 'Pengumuman',
      'icon': Icons.campaign_rounded,
      'color': const Color(0xFF10B981),
      'desc': 'Kelola pengumuman',
    },
    {
      'title': 'Laporan',
      'icon': Icons.report_rounded,
      'color': const Color(0xFFDC2626),
      'desc': 'Lihat laporan warga',
    },
    {
      'title': 'Iuran',
      'icon': Icons.payment_rounded,
      'color': const Color(0xFFF59E0B),
      'desc': 'Manajemen pembayaran',
    },
    {
      'title': 'Kegiatan',
      'icon': Icons.event_rounded,
      'color': const Color(0xFF8B5CF6),
      'desc': 'Jadwal acara RT',
    },
    {
      'title': 'UMKM',
      'icon': Icons.store_rounded,
      'color': const Color(0xFF06B6D4),
      'desc': 'Data usaha warga',
    },
    {
      'title': 'Warga',
      'icon': Icons.people_rounded,
      'color': const Color(0xFFEC4899),
      'desc': 'Database warga',
    },
    {
      'title': 'Surat Pengantar',
      'icon': Icons.description_rounded,
      'color': const Color(0xFFFB923C),
      'desc': 'Kelola surat pengantar',
    },
  ];

  @override
  void initState() {
    super.initState();
    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _contentAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _headerFadeAnimation = CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeOut,
    );
    _headerSlideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _headerAnimController,
            curve: Curves.easeOutCubic,
          ),
        );
    _headerAnimController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _contentAnimController.forward();
    });
    // --- PERUBAHAN ---
    // Mengganti _loadStats() menjadi _loadDashboardData()
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDashboardData());
  }

  // --- PERUBAHAN ---
  // Mengganti nama _loadStats menjadi _loadDashboardData
  // dan menambahkan pengambilan data aktivitas
  Future<void> _loadDashboardData() async {
    setState(() {
      _isAktivitasLoading = true; // Set loading aktivitas
    });
    try {
      final apiService = ApiService();

      // Mengambil data stats dan aktivitas secara bersamaan
      final results = await Future.wait([
        apiService.getAdminStats(),
        apiService.getAktivitasTerbaru(), // Memanggil fungsi baru
      ]);

      final statsResult = results[0];
      final aktivitasResult = results[1];

      if (mounted) {
        setState(() {
          // Update stats
          if (statsResult['success']) {
            _stats = statsResult['data'];
          }

          // Update aktivitas
          if (aktivitasResult['success']) {
            _aktivitasList = aktivitasResult['data'];
          } else {
            // Jika gagal, set list kosong (atau tampilkan error)
            _aktivitasList = [];
          }
          _isAktivitasLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      if (mounted) {
        setState(() {
          _isAktivitasLoading = false;
          _aktivitasList = [];
        });
      }
    }
  }

  @override
  void dispose() {
    _headerAnimController.dispose();
    _contentAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          // --- PERUBAHAN ---
          // Mengganti onRefresh ke fungsi baru
          onRefresh: _loadDashboardData,
          color: const Color(0xFF2D3748),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (_selectedIndex == 0)
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _headerFadeAnimation,
                    child: SlideTransition(
                      position: _headerSlideAnimation,
                      child: _buildModernHeader(context),
                    ),
                  ),
                ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 12 : 24,
                  _selectedIndex == 0
                      ? (isMobile ? 12 : 24)
                      : (isMobile ? 24 : 40),
                  isMobile ? 12 : 24,
                  24,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _selectedIndex == 0
                        ? _buildDashboardContent()
                        : _buildContentForIndex(_selectedIndex),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      margin: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(isMobile ? 20 : 28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.4),
            blurRadius: 40,
            offset: const Offset(0, 16),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: ModernPatternPainter())),
          Positioned.fill(
            child: CustomPaint(painter: GeometricPatternPainter()),
          ),
          Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) => Transform.scale(
                          scale: value,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 12 : 18,
                              vertical: isMobile ? 8 : 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.2),
                                  Colors.white.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    Icons.admin_panel_settings_rounded,
                                    color: Colors.white,
                                    size: isMobile ? 14 : 16,
                                  ),
                                ),
                                SizedBox(width: isMobile ? 6 : 10),
                                Flexible(
                                  child: Text(
                                    'Admin Panel',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isMobile ? 12 : 14,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) =>
                          Transform.scale(scale: value, child: child),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showLogoutDialog(context),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: EdgeInsets.all(isMobile ? 10 : 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.25),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              Icons.logout_rounded,
                              color: Colors.white,
                              size: isMobile ? 18 : 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 20 : 28),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOut,
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 15,
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          String userName = 'Admin';
                          if (authProvider.userData != null) {
                            final data = authProvider.userData!;
                            userName =
                                data['nama_lengkap']?.toString() ??
                                data['nama']?.toString() ??
                                data['name']?.toString() ??
                                data['username']?.toString() ??
                                'Admin';
                          }
                          return Text(
                            userName,
                            style: TextStyle(
                              fontSize: isMobile ? 24 : 32,
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isMobile ? 16 : 24),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOut,
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (isMobile) {
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildQuickStat(
                                    icon: Icons.people_rounded,
                                    label: 'Warga',
                                    value: '${_stats?['totalWarga'] ?? 0}',
                                    color: const Color(0xFF3B82F6),
                                    isMobile: true,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildQuickStat(
                                    icon: Icons.campaign_rounded,
                                    label: 'Pengumuman',
                                    value: '${_stats?['totalPengumuman'] ?? 0}',
                                    color: const Color(0xFF10B981),
                                    isMobile: true,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildQuickStat(
                                    icon: Icons.report_rounded,
                                    label: 'Laporan',
                                    value: '${_stats?['totalLaporan'] ?? 0}',
                                    color: const Color(0xFFDC2626),
                                    isMobile: true,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      } else {
                        return Row(
                          children: [
                            Expanded(
                              child: _buildQuickStat(
                                icon: Icons.people_rounded,
                                label: 'Total Warga',
                                value: '${_stats?['totalWarga'] ?? 0}',
                                color: const Color(0xFF3B82F6),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _buildQuickStat(
                                icon: Icons.campaign_rounded,
                                label: 'Pengumuman',
                                value: '${_stats?['totalPengumuman'] ?? 0}',
                                color: const Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _buildQuickStat(
                                icon: Icons.report_rounded,
                                label: 'Laporan',
                                value: '${_stats?['totalLaporan'] ?? 0}',
                                color: const Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isMobile = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 8 : 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.3), color.withOpacity(0.15)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: isMobile ? 18 : 20,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.3), width: 1),
                ),
                child: Icon(Icons.trending_up_rounded, color: color, size: 14),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 14),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 22 : 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 11 : 12,
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return FadeTransition(
      opacity: _contentAnimController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.apps_rounded,
            title: 'Menu Utama',
            subtitle: 'Akses cepat ke semua fitur',
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = 2;
              if (constraints.maxWidth >= 1200) {
                crossAxisCount = 4;
              } else if (constraints.maxWidth >= 900) {
                crossAxisCount = 3;
              }

              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: isMobile ? 12 : 16,
                  mainAxisSpacing: isMobile ? 12 : 16,
                  childAspectRatio: isMobile ? 0.95 : 1.0,
                ),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _menuItems.length,
                itemBuilder: (context, index) => _buildMenuCard(
                  index: index,
                  title: _menuItems[index]['title'],
                  desc: _menuItems[index]['desc'],
                  icon: _menuItems[index]['icon'],
                  color: _menuItems[index]['color'],
                  isActive: false,
                  onTap: () => setState(() => _selectedIndex = index + 1),
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          _buildSectionHeader(
            icon: Icons.bar_chart_rounded,
            title: 'Statistik Detail',
            subtitle: 'Ringkasan data terkini',
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = 2;
              if (constraints.maxWidth >= 1200) {
                crossAxisCount = 4;
              } else if (constraints.maxWidth >= 900) {
                crossAxisCount = 3;
              }

              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: isMobile ? 12 : 16,
                mainAxisSpacing: isMobile ? 12 : 16,
                childAspectRatio: isMobile ? 1.1 : 1.3,
                children: [
                  _buildStatCard(
                    index: 0,
                    title: 'Total Warga',
                    value: '${_stats?['totalWarga'] ?? 0}',
                    subtitle: 'Terdaftar',
                    icon: Icons.people_rounded,
                    color: const Color(0xFF3B82F6),
                  ),
                  _buildStatCard(
                    index: 1,
                    title: 'Pengumuman',
                    value: '${_stats?['totalPengumuman'] ?? 0}',
                    subtitle: 'Aktif',
                    icon: Icons.campaign_rounded,
                    color: const Color(0xFF10B981),
                  ),
                  _buildStatCard(
                    index: 2,
                    title: 'Laporan',
                    value: '${_stats?['totalLaporan'] ?? 0}',
                    subtitle: 'Pending',
                    icon: Icons.report_rounded,
                    color: const Color(0xFFDC2626),
                  ),
                  _buildStatCard(
                    index: 3,
                    title: 'Iuran',
                    value:
                        'Rp ${_formatCurrency(_stats?['totalIuranBulanIni'] ?? 0)}',
                    subtitle: 'Bulan ini',
                    icon: Icons.payment_rounded,
                    color: const Color(0xFFF59E0B),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 40),
          _buildSectionHeader(
            icon: Icons.history_rounded,
            title: 'Aktivitas Terbaru',
            subtitle: 'Update sistem terakhir',
          ),
          const SizedBox(height: 20),

          // --- PERUBAHAN ---
          // Mengganti daftar statis dengan widget dinamis _buildActivityList()
          _buildActivityList(),
          // --- AKHIR PERUBAHAN ---
        ],
      ),
    );
  }

  // --- PERUBAHAN ---
  // Widget baru untuk menampilkan daftar aktivitas secara dinamis
  Widget _buildActivityList() {
    if (_isAktivitasLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(color: Color(0xFF334155)),
        ),
      );
    }

    if (_aktivitasList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'Belum ada aktivitas terbaru.',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _aktivitasList.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final aktivitas = _aktivitasList[index];
        // Mendapatkan ikon dan warna berdasarkan tipe aktivitas
        final visual = _getAktivitasVisuals(aktivitas['tipe']);

        return _buildActivityItem(
          index: index,
          title: aktivitas['judul'] ?? 'Aktivitas Tidak Dikenal',
          subtitle: aktivitas['deskripsi'] ?? '',
          // Menggunakan helper untuk format waktu
          time: _formatWaktuLalu(aktivitas['createdAt']),
          icon: visual['icon'],
          color: visual['color'],
        );
      },
    );
  }

  // --- PERUBAHAN ---
  // Helper untuk mendapatkan ikon & warna berdasarkan tipe aktivitas dari API
  Map<String, dynamic> _getAktivitasVisuals(String? tipe) {
    switch (tipe) {
      case 'pengumuman':
        return {
          'icon': Icons.campaign_rounded,
          'color': const Color(0xFF10B981),
        };
      case 'laporan':
        return {'icon': Icons.report_rounded, 'color': const Color(0xFFDC2626)};
      case 'iuran':
        return {
          'icon': Icons.payment_rounded,
          'color': const Color(0xFFF59E0B),
        };
      case 'warga':
        return {'icon': Icons.people_rounded, 'color': const Color(0xFFEC4899)};
      case 'kegiatan':
        return {'icon': Icons.event_rounded, 'color': const Color(0xFF8B5CF6)};
      case 'umkm':
        return {'icon': Icons.store_rounded, 'color': const Color(0xFF06B6D4)};
      default:
        return {
          'icon': Icons.history_rounded,
          'color': const Color(0xFF64748B),
        };
    }
  }

  // --- PERUBAHAN ---
  // Helper untuk mengubah ISO 8601 date string (dari DB) menjadi "X jam lalu"
  String _formatWaktuLalu(String? dateString) {
    if (dateString == null) return '';
    try {
      final dateTime = DateTime.parse(dateString);
      final difference = DateTime.now().difference(dateTime);

      if (difference.inDays > 1) {
        return '${difference.inDays} hari lalu';
      } else if (difference.inDays == 1) {
        return '1 hari lalu';
      } else if (difference.inHours > 1) {
        return '${difference.inHours} jam lalu';
      } else if (difference.inHours == 1) {
        return '1 jam lalu';
      } else if (difference.inMinutes > 1) {
        return '${difference.inMinutes} menit lalu';
      } else if (difference.inMinutes == 1) {
        return '1 menit lalu';
      } else {
        return 'Baru saja';
      }
    } catch (e) {
      return ''; // Mengembalikan string kosong jika format tanggal salah
    }
  }
  // --- AKHIR SEMUA PERUBAHAN ---

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isMobile ? 10 : 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2D3748), Color(0xFF1A202C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2D3748).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: isMobile ? 18 : 20),
        ),
        SizedBox(width: isMobile ? 10 : 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 16 : 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A202C),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: isMobile ? 11 : 13,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard({
    required int index,
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    // Menu yang tidak perlu admin panel
    final noAdminPanelMenus = [
      'Pengumuman',
      'Laporan',
      'Iuran',
      'Kegiatan',
      'UMKM',
    ];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 60)),
      curve: Curves.easeOutBack,
      builder: (context, animValue, child) => Opacity(
        opacity: animValue,
        child: Transform.scale(scale: 0.8 + (0.2 * animValue), child: child),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: noAdminPanelMenus.contains(title)
              ? () {
                  // Navigasi ke screen user sesuai menu
                  Widget targetScreen;
                  switch (title) {
                    case 'Pengumuman':
                      targetScreen = const AnnouncementsScreen();
                      break;
                    case 'Laporan':
                      targetScreen = const ReportsScreen();
                      break;
                    case 'Iuran':
                      targetScreen = const PaymentsScreen();
                      break;
                    case 'Kegiatan':
                      targetScreen = const ActivitiesScreen();
                      break;
                    case 'UMKM':
                      targetScreen = const UMKMScreen();
                      break;
                    default:
                      return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => targetScreen),
                  );
                }
              : onTap,
          borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: EdgeInsets.all(isMobile ? 14 : 20),
            decoration: BoxDecoration(
              gradient: isActive
                  ? LinearGradient(
                      colors: [
                        color.withOpacity(0.15),
                        color.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isActive ? null : Colors.white,
              borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
              border: Border.all(
                color: isActive
                    ? color.withOpacity(0.3)
                    : const Color(0xFFE2E8F0),
                width: isActive ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isActive
                      ? color.withOpacity(0.15)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: isActive ? 16 : 8,
                  offset: Offset(0, isActive ? 6 : 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: EdgeInsets.all(isMobile ? 10 : 14),
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? LinearGradient(
                            colors: [color, color.withOpacity(0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isActive ? null : color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                  ),
                  child: Icon(
                    icon,
                    color: isActive ? Colors.white : color,
                    size: isMobile ? 24 : 28,
                  ),
                ),
                SizedBox(height: isMobile ? 10 : 14),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    fontWeight: FontWeight.w700,
                    color: isActive ? color : const Color(0xFF1A202C),
                    letterSpacing: -0.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isMobile ? 2 : 4),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: isMobile ? 10 : 11,
                    color: const Color(0xFF64748B).withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required int index,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 80)),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) => Opacity(
        opacity: animValue,
        child: Transform.translate(
          offset: Offset(0, 30 * (1 - animValue)),
          child: child,
        ),
      ),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 14 : 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFFAFAFA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 10 : 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: isMobile ? 20 : 22),
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 24,
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
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 13,
                    color: const Color(0xFF1A202C),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: isMobile ? 10 : 11,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required int index,
    required String title,
    required String subtitle,
    required String time,
    required IconData icon,
    required Color color,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + (index * 80)),
      curve: Curves.easeOut,
      builder: (context, animValue, child) => Opacity(
        opacity: animValue,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - animValue)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        // --- PERUBAHAN --- Menggunakan ListTile agar lebih rapi dan responsif
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 18,
            vertical: isMobile ? 4 : 8,
          ),
          leading: Container(
            padding: EdgeInsets.all(isMobile ? 10 : 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: isMobile ? 18 : 20),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 13 : 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A202C),
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: isMobile ? 11 : 12,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            time,
            style: TextStyle(
              fontSize: isMobile ? 10 : 11,
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentForIndex(int index) {
    // index - 1 karena menu items dimulai dari 0
    final selectedMenu = _menuItems[index - 1];

    switch (selectedMenu['title']) {
      case 'Pengumuman':
        return PengumumanPage(
          onBackPressed: () => setState(() => _selectedIndex = 0),
        );
      case 'Laporan':
        return LaporanPage(
          onBackPressed: () => setState(() => _selectedIndex = 0),
        );
      case 'Iuran':
        return IuranPage(
          onBackPressed: () => setState(() => _selectedIndex = 0),
        );
      case 'Kegiatan':
        return KegiatanPage(
          onBackPressed: () => setState(() => _selectedIndex = 0),
        );
      case 'UMKM':
        return UMKMAdminPage(
          onBackPressed: () => setState(() => _selectedIndex = 0),
        );
      case 'Warga':
        return WargaAdminPage(
          onBackPressed: () => setState(() => _selectedIndex = 0),
        );
      case 'Surat Pengantar':
        return SuratPengantarAdminScreen(
          onBackPressed: () => setState(() => _selectedIndex = 0),
        );
      default:
        return _buildPlaceholderContent(
          selectedMenu['title'],
          selectedMenu['icon'],
          selectedMenu['color'],
        );
    }
  }

  Widget _buildPlaceholderContent(String title, IconData icon, Color color) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutBack,
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.scale(scale: 0.8 + (0.2 * value), child: child),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(icon, size: 64, color: color),
            ),
            const SizedBox(height: 28),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A202C),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Halaman ini sedang dalam pengembangan',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF64748B).withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.2), width: 1.5),
              ),
              child: Text(
                'Segera Hadir',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setState(() => _selectedIndex = 0),
              child: const Text('Kembali ke Dashboard'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(int amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}Jt';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}Rb';
    return amount.toString();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi,';
    if (hour < 15) return 'Selamat Siang,';
    if (hour < 18) return 'Selamat Sore,';
    return 'Selamat Malam,';
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width < 600 ? 16 : 28,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFDC2626).withOpacity(0.15),
                      const Color(0xFFDC2626).withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFDC2626),
                  size: 36,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Konfirmasi Logout',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A202C),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Apakah Anda yakin ingin keluar dari akun Anda?',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(
                            color: Color(0xFFCBD5E1),
                            width: 1.5,
                          ),
                        ),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        ).logout();
                        Navigator.of(
                          context,
                        ).pushNamedAndRemoveUntil('/login', (route) => false);
                      },
                      child: const Text(
                        'Logout',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
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
}

// --- PERBAIKAN: Kode 'painter' yang terpotong di akhir ---
// Anda mungkin sudah punya ini, tapi untuk melengkapi file
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

class GeometricPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw circles
    for (double i = 0; i < size.width; i += 80) {
      for (double j = 0; j < size.height; j += 80) {
        canvas.drawCircle(Offset(i, j), 20, paint);
      }
    }

    // Draw lines
    for (double i = 0; i < size.width; i += 80) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double j = 0; j < size.height; j += 80) {
      canvas.drawLine(Offset(0, j), Offset(size.width, j), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
