// 1. Impor semua library yang dibutuhkan
const express = require('express');
const mongoose = require('mongoose');
const dotenv = require('dotenv');

// 2. Load konfigurasi dari file .env
dotenv.config();

// 3. Inisialisasi aplikasi Express
const app = express();

// Ambil PORT dari file .env, atau gunakan 3000 jika tidak ada
const PORT = process.env.PORT || 3000;

// Ambil koneksi string dari .env
const dbURI = process.env.MONGO_URI;

// Cek jika MONGO_URI ada
if (!dbURI) {
    console.error("Error: MONGO_URI tidak ditemukan di file .env");
    process.exit(1); // Keluar dari aplikasi jika URI DB tidak ada
}

// 5. Hubungkan ke MongoDB
mongoose.connect(dbURI)
  .then(() => {
    console.log("✅ Berhasil terhubung ke MongoDB (wargaconnect_db)");

    // 6. Jalankan server HANYA JIKA koneksi DB berhasil
    app.listen(PORT, () => {
      console.log(`🚀 Server berjalan di http://localhost:${PORT}`);
    });
  })
  .catch((err) => {
    console.error("Error: Gagal terhubung ke MongoDB", err);
  });

// 7. Contoh "route" sederhana untuk tes
app.get('/', (req, res) => {
  res.send('Selamat datang di WargaConnect API!');
});