// File: surat_pengantar_screen.dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../services/api_service.dart';

class SuratPengantarScreen extends StatefulWidget {
  const SuratPengantarScreen({super.key});

  @override
  State<SuratPengantarScreen> createState() => _SuratPengantarScreenState();
}

class _SuratPengantarScreenState extends State<SuratPengantarScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _suratList = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSurat();
  }

  Future<void> _loadSurat() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getSuratPengantar();
      if (response['success']) {
        setState(() => _suratList = response['data']);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'disetujui':
        return Colors.green;
      case 'ditolak':
        return Colors.red;
      case 'diproses':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'disetujui':
        return Icons.check_circle;
      case 'ditolak':
        return Icons.cancel;
      case 'diproses':
        return Icons.hourglass_empty;
      default:
        return Icons.pending;
    }
  }

  void _showDetailDialog(Map<String, dynamic> surat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(surat['jenis_surat']),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Keperluan', surat['keperluan']),
              _buildDetailRow('Keterangan', surat['keterangan']),
              _buildDetailRow('Status', surat['status_pengajuan']),
              _buildDetailRow('Tanggal', surat['tanggal_pengajuan']),
              if (surat['tanggapan_admin']?.isNotEmpty ?? false)
                _buildDetailRow('Tanggapan Admin', surat['tanggapan_admin']),
              if (surat['file_surat']?.isNotEmpty ?? false)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement download file
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Download: Coming soon')),
                      );
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Download Surat'),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => const _AddSuratDialog(),
    ).then((success) {
      if (success == true) {
        _loadSurat();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFF10B981),
        icon: const Icon(Icons.add),
        label: const Text('Ajukan Surat'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadSurat,
          color: const Color(0xFF10B981),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  margin: EdgeInsets.all(isMobile ? 12 : 20),
                  padding: EdgeInsets.all(isMobile ? 18 : 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0F172A),
                        Color(0xFF1E293B),
                        Color(0xFF334155),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(isMobile ? 18 : 22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF334155).withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Surat Pengantar',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                          ),
                        ),
                        child: TextField(
                          onChanged: (v) => setState(() => _searchQuery = v),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Cari jenis atau keperluan...',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: Colors.white.withOpacity(0.85),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                (() {
                  final list = _searchQuery.isEmpty
                      ? _suratList
                      : _suratList.where((s) {
                          final j = (s['jenis_surat'] ?? '')
                              .toString()
                              .toLowerCase();
                          final k = (s['keperluan'] ?? '')
                              .toString()
                              .toLowerCase();
                          return j.contains(_searchQuery.toLowerCase()) ||
                              k.contains(_searchQuery.toLowerCase());
                        }).toList();
                  if (list.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada pengajuan surat',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap tombol + untuk mengajukan surat',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? 16 : 20,
                      12,
                      isMobile ? 16 : 20,
                      80,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final surat = list[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(
                                surat['status_pengajuan'],
                              ).withOpacity(0.2),
                              child: Icon(
                                _getStatusIcon(surat['status_pengajuan']),
                                color: _getStatusColor(
                                  surat['status_pengajuan'],
                                ),
                              ),
                            ),
                            title: Text(
                              surat['jenis_surat'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(surat['keperluan'] ?? ''),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                          surat['status_pengajuan'],
                                        ).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        surat['status_pengajuan'] ?? '',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _getStatusColor(
                                            surat['status_pengajuan'],
                                          ),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      surat['tanggal_pengajuan'] ?? '',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap: () => _showDetailDialog(surat),
                          ),
                        );
                      }, childCount: list.length),
                    ),
                  );
                })(),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddSuratDialog extends StatefulWidget {
  const _AddSuratDialog();

  @override
  State<_AddSuratDialog> createState() => _AddSuratDialogState();
}

class _AddSuratDialogState extends State<_AddSuratDialog> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final _keperluanController = TextEditingController();
  final _keteranganController = TextEditingController();

  String _jenisSurat = 'Domisili'; // Match dengan list options
  List<PlatformFile> _selectedFiles = []; // Changed from List<File>
  bool _isLoading = false;

  final List<String> _jenisSuratOptions = [
    'KTP',
    'KK',
    'SKCK',
    'Domisili',
    'Kelahiran',
    'Kematian',
    'Nikah',
    'Lainnya',
  ];

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          _selectedFiles = result.files; // PlatformFile list dari file picker
          debugPrint('📋 Files selected: ${_selectedFiles.length}');
          for (var f in _selectedFiles) {
            if (kIsWeb) {
              // On web, accessing `path` may throw — use bytes info instead
              debugPrint(
                '📋 File: ${f.name}, Size: ${f.size}, Bytes: ${f.bytes?.length ?? 'null'}',
              );
            } else {
              debugPrint(
                '📋 File: ${f.name}, Size: ${f.size}, Path: ${f.path}',
              );
            }
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Error saat memilih file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memilih file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Map filename extension to MediaType for multipart uploads
  MediaType? _mediaTypeForFileName(String name) {
    final parts = name.split('.');
    if (parts.length < 2) return null;
    final ext = parts.last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'pdf':
        return MediaType('application', 'pdf');
      default:
        return null;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final token = await _apiService.getTokenDebug();
      debugPrint('🔐 Token di submit: ${token?.substring(0, 10)}...');

      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Token tidak valid. Silakan login ulang.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final suratData = {
        'pengaju_id': token,
        'jenis_surat': _jenisSurat,
        'keperluan': _keperluanController.text.trim(),
        'keterangan': _keteranganController.text.trim(),
      };

      debugPrint('📋 Surat Data: $suratData');

      List<http.MultipartFile>? files;
      if (_selectedFiles.isNotEmpty) {
        files = [];
        try {
          for (var file in _selectedFiles) {
            debugPrint('📋 Processing file: ${file.name}');

            if (kIsWeb) {
              // On web, PlatformFile.path is often null — use bytes
              if (file.bytes == null) {
                debugPrint('❌ File bytes null on web: ${file.name}');
                throw Exception('File.bytes tidak tersedia: ${file.name}');
              }

              final mt = _mediaTypeForFileName(file.name);
              final multipartFile = http.MultipartFile.fromBytes(
                'files',
                file.bytes!,
                filename: file.name,
                contentType: mt,
              );
              files.add(multipartFile);
              debugPrint('✅ File added successfully (bytes): ${file.name}');
            } else {
              // Mobile / desktop: use path
              if (file.path == null) {
                debugPrint('❌ File path is null: ${file.name}');
                throw Exception('File path tidak tersedia: ${file.name}');
              }

              debugPrint('📋 Creating MultipartFile from path...');
              final mt = _mediaTypeForFileName(file.name);
              final multipartFile = await http.MultipartFile.fromPath(
                'files',
                file.path!,
                contentType: mt,
              );
              files.add(multipartFile);
              debugPrint('✅ File added successfully: ${file.path}');
            }
          }
          debugPrint('📋 Total files: ${files.length}');
        } catch (fileError) {
          debugPrint('❌ Error processing files: $fileError');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error memproses file: $fileError'),
                backgroundColor: Colors.red,
              ),
            );
          }
          if (mounted) setState(() => _isLoading = false);
          return;
        }
      }

      debugPrint('📋 Calling createSuratPengantar...');
      final response = await _apiService.createSuratPengantar(
        suratData,
        files: files,
      );

      debugPrint('📋 Response: $response');

      if (mounted) {
        if (response['success']) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pengajuan surat berhasil dikirim'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Gagal mengajukan surat'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error in _submit: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajukan Surat Pengantar'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _jenisSurat,
                decoration: const InputDecoration(
                  labelText: 'Jenis Surat',
                  border: OutlineInputBorder(),
                ),
                items: _jenisSuratOptions.map((jenis) {
                  return DropdownMenuItem(value: jenis, child: Text(jenis));
                }).toList(),
                onChanged: (value) => setState(() => _jenisSurat = value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _keperluanController,
                decoration: const InputDecoration(
                  labelText: 'Keperluan',
                  border: OutlineInputBorder(),
                  hintText: 'Untuk apa surat ini dibutuhkan?',
                ),
                maxLines: 2,
                validator: (val) =>
                    val?.isEmpty ?? true ? 'Keperluan harus diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _keteranganController,
                decoration: const InputDecoration(
                  labelText: 'Keterangan Tambahan',
                  border: OutlineInputBorder(),
                  hintText: 'Informasi tambahan (opsional)',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickFiles,
                icon: const Icon(Icons.attach_file),
                label: Text(
                  _selectedFiles.isEmpty
                      ? 'Lampirkan Dokumen (Opsional)'
                      : '${_selectedFiles.length} file dipilih',
                ),
              ),
              if (_selectedFiles.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedFiles.map((file) {
                    return Chip(
                      label: Text(file.name, overflow: TextOverflow.ellipsis),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() => _selectedFiles.remove(file));
                      },
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Kirim'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _keperluanController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }
}
