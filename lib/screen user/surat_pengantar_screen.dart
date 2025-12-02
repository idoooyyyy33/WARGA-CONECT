// File: surat_pengantar_screen.dart
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
                        const SnackBar(
                          content: Text('Download: Coming soon'),
                        ),
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
          Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Surat Pengantar'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSurat,
              child: _suratList.isEmpty
                  ? Center(
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
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _suratList.length,
                      itemBuilder: (context, index) {
                        final surat = _suratList[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  _getStatusColor(surat['status_pengajuan'])
                                      .withValues(alpha: 0.2),
                              child: Icon(
                                _getStatusIcon(surat['status_pengajuan']),
                                color:
                                    _getStatusColor(surat['status_pengajuan']),
                              ),
                            ),
                            title: Text(
                              surat['jenis_surat'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(surat['keperluan']),
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
                                        ).withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        surat['status_pengajuan'],
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
                                      surat['tanggal_pengajuan'],
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios,
                                size: 16),
                            onTap: () => _showDetailDialog(surat),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: Colors.green.shade700,
        icon: const Icon(Icons.add),
        label: const Text('Ajukan Surat'),
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

  String _jenisSurat = 'Surat Keterangan Domisili';
  List<File> _selectedFiles = [];
  bool _isLoading = false;

  final List<String> _jenisSuratOptions = [
    'Surat Keterangan Domisili',
    'Surat Keterangan Tidak Mampu',
    'Surat Keterangan Usaha',
    'Surat Pengantar KTP',
    'Surat Pengantar KK',
    'Surat Keterangan Kelahiran',
    'Surat Keterangan Kematian',
    'Surat Keterangan Pindah',
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
          _selectedFiles = result.paths.map((path) => File(path!)).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error memilih file: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final token = await _apiService.getTokenDebug();

      final suratData = {
        'pengaju_id': token,
        'jenis_surat': _jenisSurat,
        'keperluan': _keperluanController.text.trim(),
        'keterangan': _keteranganController.text.trim(),
      };

      List<http.MultipartFile>? files;
      if (_selectedFiles.isNotEmpty) {
        files = [];
        for (var file in _selectedFiles) {
          files.add(
            await http.MultipartFile.fromPath(
              'lampiran',
              file.path,
            ),
          );
        }
      }

      final response = await _apiService.createSuratPengantar(
        suratData,
        files: files,
      );

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
                label: Text(_selectedFiles.isEmpty
                    ? 'Lampirkan Dokumen (Opsional)'
                    : '${_selectedFiles.length} file dipilih'),
              ),
              if (_selectedFiles.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedFiles.map((file) {
                    return Chip(
                      label: Text(
                        file.path.split('/').last,
                        overflow: TextOverflow.ellipsis,
                      ),
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