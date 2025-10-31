import 'package:flutter/material.dart';

class UmkmListScreen extends StatelessWidget {
  const UmkmListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar UMKM')),
      body: Center(child: Text('Daftar UMKM untuk user akan tampil di sini')),
    );
  }
}
