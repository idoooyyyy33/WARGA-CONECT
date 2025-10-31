import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/color_utils.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  // Metode ini tidak digunakan dalam build, tetapi saya biarkan karena sudah ada di kode.
  // Color _withOpacity(Color color, double opacity) {
  //   return Color.fromRGBO(
  //     color.red,
  //     color.green,
  //     color.blue,
  //     opacity,
  //   );
  // }

  Widget _buildServiceCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.04), blurRadius: 16),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // Gunakan helper untuk konsistensi
                color: colorWithOpacity(color, 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorWithOpacity(Colors.black, 0.5),
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
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorWithOpacity(color, 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorWithOpacity(Colors.black, 0.5),
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: colorWithOpacity(Colors.black, 0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header dengan Current Balance
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row with Profile and Search
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
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

                            return Row(
                              children: [
                                Container(
                                  width: 45,
                                  height: 45,
                                  decoration: BoxDecoration(
                                    color: colorWithOpacity(
                                      const Color(0xFF3B82F6),
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    color: Color(0xFF3B82F6),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Halo, ',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: colorWithOpacity(
                                          Colors.black,
                                          0.6,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      userName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                        IconButton(
                          onPressed: () {
                            // Implementasi pencarian
                          },
                          icon: const Icon(Icons.search_rounded, size: 28),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Balance Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: colorWithOpacity(
                              const Color(0xFF3B82F6),
                              0.3,
                            ),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Pengguna',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colorWithOpacity(
                                        Colors.white,
                                        0.8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Ambil jumlah pengguna dari backend melalui ApiService
                                  FutureBuilder<Map<String, dynamic>>(
                                    future: ApiService().getUsers(),
                                    builder: (context, snapshot) {
                                      String display;
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        display = '...';
                                      } else if (snapshot.hasError ||
                                          !snapshot.hasData ||
                                          snapshot.data!['success'] != true) {
                                        display = '-';
                                      } else {
                                        final data = snapshot.data!['data'];
                                        if (data is List) {
                                          display = data.length.toString();
                                        } else if (data is Map &&
                                            data.containsKey('length')) {
                                          display = data['length'].toString();
                                        } else {
                                          display = '-';
                                        }
                                      }

                                      return Text(
                                        display,
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorWithOpacity(Colors.white, 0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.groups_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Services Text
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Menu Utama',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Main Menu Grid
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.1,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                          ),
                      children: [
                        _buildServiceCard(
                          context: context,
                          icon: Icons.campaign_rounded,
                          title: 'Pengumuman',
                          subtitle: 'Kelola pengumuman',
                          color: const Color(0xFF8B5CF6),
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/admin/announcements',
                          ),
                        ),
                        _buildServiceCard(
                          context: context,
                          icon: Icons.account_circle_rounded,
                          title: 'Pengguna',
                          subtitle: 'Kelola pengguna',
                          color: const Color(0xFF3B82F6),
                          onTap: () =>
                              Navigator.pushNamed(context, '/admin/users'),
                        ),
                        _buildServiceCard(
                          context: context,
                          icon: Icons.account_balance_wallet_rounded,
                          title: 'Iuran',
                          subtitle: 'Kelola pembayaran',
                          color: const Color(0xFF10B981),
                          onTap: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Fitur dalam pengembangan'),
                                ),
                              ),
                        ),
                        _buildServiceCard(
                          context: context,
                          icon: Icons.event_rounded,
                          title: 'Kegiatan',
                          subtitle: 'Kelola kegiatan',
                          color: const Color(0xFFF59E0B),
                          onTap: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Fitur dalam pengembangan'),
                                ),
                              ),
                        ),
                        _buildServiceCard(
                          context: context,
                          icon: Icons.store_rounded,
                          title: 'UMKM',
                          subtitle: 'Kelola UMKM',
                          color: const Color(0xFF6366F1),
                          onTap: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Fitur dalam pengembangan'),
                                ),
                              ),
                        ),
                        _buildServiceCard(
                          context: context,
                          icon: Icons.report_problem_rounded,
                          title: 'Laporan',
                          subtitle: 'Kelola laporan',
                          color: const Color(0xFFEF4444),
                          onTap: () =>
                              Navigator.pushNamed(context, '/admin/reports'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ), // <-- Penutupan yang benar untuk SliverToBoxAdapter Grid
            // Recent Activities Section
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Aktivitas Terbaru',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: colorWithOpacity(Colors.black, 0.04),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildActivityItem(
                            icon: Icons.campaign_rounded,
                            title: 'Pengumuman Baru',
                            subtitle: 'Rapat RT bulan November',
                            time: '10:45',
                            color: const Color(0xFF8B5CF6),
                          ),
                          const Divider(height: 1),
                          _buildActivityItem(
                            icon: Icons.report_problem_rounded,
                            title: 'Laporan Masuk',
                            subtitle: 'Lampu jalan mati di Blok A',
                            time: '09:30',
                            color: const Color(0xFFEF4444),
                          ),
                          const Divider(height: 1),
                          _buildActivityItem(
                            icon: Icons.account_balance_wallet_rounded,
                            title: 'Pembayaran Iuran',
                            subtitle: 'Iuran Keamanan - Nov 2025',
                            time: '08:15',
                            color: const Color(0xFF10B981),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
