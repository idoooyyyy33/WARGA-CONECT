import 'package:flutter/material.dart';

/// Helper untuk membuat warna dengan opacity tanpa memanggil `.withOpacity`
/// Digunakan agar penggunaan opacity konsisten di seluruh kode.
Color colorWithOpacity(Color color, double opacity) {
  return Color.fromRGBO(color.red, color.green, color.blue, opacity);
}
