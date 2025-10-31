import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class AdminManageAnnouncements extends StatefulWidget {
  const AdminManageAnnouncements({super.key});

  @override
  State<AdminManageAnnouncements> createState() =>
      _AdminManageAnnouncementsState();
}

class _AdminManageAnnouncementsState extends State<AdminManageAnnouncements> {
  final ApiService _api = ApiService();
  List<dynamic> _announcements = [];
  bool _isLoading = false;

  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _sendToAll = true; // default: kirim ke semua user

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final res = await _api.getAnnouncementsRaw();
    if (res['success'] == true) {
      setState(() {
        _announcements = res['data'] is List ? res['data'] : [];
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Error')));
    }
    setState(() => _isLoading = false);
  }

  Future<void> _create() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) return;

    setState(() => _isLoading = true);
    // Ambil penulis_id dari AuthProvider yang saat login menyimpan userData
    String? penulisId;
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final userMap = auth.userData;
      if (userMap != null) {
        penulisId =
            userMap['_id'] ?? userMap['id'] ?? userMap['nik']?.toString();
      }
    } catch (_) {
      penulisId = null;
    }

    // Jika penulisId tidak ditemukan, beri tahu user untuk login ulang
    if (penulisId == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Gagal membuat pengumuman: tidak ditemukan informasi penulis. Silakan login ulang.',
          ),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    final payload = {
      'judul': title,
      'isi': content,
      'penulis_id': penulisId,
      // Sertakan flag `to_all` jika admin ingin broadcast ke semua user.
      'to_all': _sendToAll,
    };

    final res = await _api.createAnnouncement(payload);

    if (res['success'] == true) {
      _titleController.clear();
      _contentController.clear();
      await _load();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pengumuman dibuat')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Gagal')));
    }
    setState(() => _isLoading = false);
  }

  Future<void> _delete(String id) async {
    setState(() => _isLoading = true);
    final res = await _api.deleteAnnouncement(id);
    if (res['success'] == true) {
      await _load();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pengumuman dihapus')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Gagal')));
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Pengumuman')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Create form
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Judul'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: 'Isi'),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Checkbox(
                        value: _sendToAll,
                        onChanged: (v) {
                          setState(() {
                            _sendToAll = v ?? false;
                          });
                        },
                      ),
                      const Expanded(
                        child: Text('Kirim ke semua user (broadcast)'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _create,
                  child: _isLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(),
                        )
                      : const Text('Buat Pengumuman'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        itemCount: _announcements.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final item = _announcements[index];
                          final id = item['_id'] ?? item['id'] ?? '';
                          final title =
                              item['judul'] ?? item['title'] ?? 'Pengumuman';
                          final content = item['isi'] ?? '';
                          final author =
                              item['penulis_id']?['nama_lengkap'] ?? 'Admin';
                          return ListTile(
                            title: Text(title),
                            subtitle: Text(
                              '$content\n• oleh $author',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: id == ''
                                  ? null
                                  : () async {
                                      final ok = await showDialog<bool>(
                                        context: context,
                                        builder: (c) => AlertDialog(
                                          title: const Text('Hapus?'),
                                          content: const Text(
                                            'Yakin ingin menghapus pengumuman ini?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(c, false),
                                              child: const Text('Batal'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(c, true),
                                              child: const Text('Hapus'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (ok == true) _delete(id);
                                    },
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
