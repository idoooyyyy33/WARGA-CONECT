import 'package:flutter/material.dart';

class UmkmAdminScreen extends StatefulWidget {
  const UmkmAdminScreen({Key? key}) : super(key: key);

  @override
  State<UmkmAdminScreen> createState() => _UmkmAdminScreenState();
}

class _UmkmAdminScreenState extends State<UmkmAdminScreen> {
  // TODO: Integrasi dengan API backend
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola UMKM')),
      body: Center(child: Text('Daftar UMKM akan tampil di sini')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigasi ke form tambah UMKM
        },
        child: const Icon(Icons.add),
        tooltip: 'Tambah UMKM',
      ),
    );
  }
}
