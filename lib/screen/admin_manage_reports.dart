import 'package:flutter/material.dart';

import '../services/api_service.dart';

class AdminManageReports extends StatefulWidget {
  const AdminManageReports({super.key});

  @override
  State<AdminManageReports> createState() => _AdminManageReportsState();
}

class _AdminManageReportsState extends State<AdminManageReports> {
  final ApiService _api = ApiService();
  List<dynamic> _reports = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final res = await _api.getReportsRaw();
    if (res['success'] == true) {
      setState(() {
        _reports = res['data'] is List ? res['data'] : [];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Gagal memuat laporan')),
      );
    }
    setState(() => _isLoading = false);
  }

  void _showUpdateStatusModal(Map<String, dynamic> report) {
    String current = report['status_laporan'] ?? 'Diterima';
    showModalBottomSheet(
      context: context,
      builder: (c) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ubah Status Laporan',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: current,
              items: [
                'Diterima',
                'Diproses',
                'Selesai',
                'Ditolak',
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) {
                if (v != null) current = v;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(c),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(c);
                      final res = await _api.updateReportStatus(
                        report['_id'] ?? report['id'] ?? '',
                        current,
                      );
                      if (res['success'] == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Status laporan diperbarui'),
                          ),
                        );
                        _load();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              res['message'] ?? 'Gagal memperbarui status',
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('Simpan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Laporan')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: _reports.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 80),
                          Center(child: Text('Belum ada laporan')),
                        ],
                      )
                    : ListView.separated(
                        itemCount: _reports.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final r = _reports[index] as Map<String, dynamic>;
                          final title = r['judul_laporan'] ?? r['title'] ?? '-';
                          final status = r['status_laporan'] ?? '-';
                          final pelapor = r['pelapor_id'] != null
                              ? (r['pelapor_id']['nama_lengkap'] ??
                                    r['pelapor_id']['name'] ??
                                    'User')
                              : 'Anonim';
                          return ListTile(
                            title: Text(title),
                            subtitle: Text('Pelapor: $pelapor'),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _statusColor(status).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: _statusColor(status),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            onTap: () => _showUpdateStatusModal(r),
                          );
                        },
                      ),
              ),
      ),
    );
  }

  Color _statusColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'selesai':
        return Colors.green;
      case 'diproses':
        return Colors.blue;
      case 'diterima':
        return Colors.orange;
      case 'ditolak':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
