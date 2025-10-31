import 'package:flutter/material.dart';

import '../services/api_service.dart';

class AdminManageUsers extends StatefulWidget {
  const AdminManageUsers({super.key});

  @override
  State<AdminManageUsers> createState() => _AdminManageUsersState();
}

class _AdminManageUsersState extends State<AdminManageUsers> {
  final ApiService _api = ApiService();
  List<dynamic> _users = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final res = await _api.getUsers();
    if (res['success'] == true) {
      setState(() {
        _users = res['data'] is List ? res['data'] : [];
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Error')));
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Pengguna')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: _users.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 80),
                          Center(child: Text('Belum ada pengguna')),
                        ],
                      )
                    : ListView.separated(
                        itemCount: _users.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final u = _users[index];
                          final name =
                              u['nama_lengkap'] ??
                              u['name'] ??
                              u['username'] ??
                              'User';
                          final email = u['email'] ?? '-';
                          final role = u['role'] ?? 'user';
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(name.isNotEmpty ? name[0] : 'U'),
                            ),
                            title: Text(name),
                            subtitle: Text('$email · Role: $role'),
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (c) => Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text('Email: $email'),
                                      const SizedBox(height: 8),
                                      Text('Role: $role'),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(c),
                                            child: const Text('Tutup'),
                                          ),
                                          const SizedBox(width: 8),
                                          OutlinedButton(
                                            onPressed: () {
                                              Navigator.pop(c);
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Fitur hapus belum diimplementasikan',
                                                  ),
                                                ),
                                              );
                                            },
                                            child: const Text('Hapus'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
      ),
    );
  }
}
