// 1. Impor semua library yang dibutuhkan
const express = require('express');
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const cors = require('cors'); // <-- BARIS BARU 1: Impor 'cors'

// --- Impor file route user ---
const userRoutes = require('./routes/user.routes'); 
const pengumumanRoutes = require('./routes/pengumuman.routes');
const laporanRoutes = require('./routes/laporan.routes.js');
const iuranRoutes = require('./routes/iuran.routes.js');
const kegiatanRoutes = require('./routes/kegiatan.routes.js');
const umkmRoutes = require('./routes/umkm.routes.js');
// 2. Load konfigurasi dari file .env
dotenv.config();

// 3. Inisialisasi aplikasi Express
const app = express();

// --- Konfigurasi Middleware ---
app.use(cors()); // <-- BARIS BARU 2: Gunakan 'cors' (WAJIB di atas routes)
app.use(express.json()); // Agar Express bisa membaca JSON

// Ambil PORT dari file .env, atau gunakan 3000 jika tidak ada
const PORT = process.env.PORT || 3000;

// Ambil koneksi string dari .env
const dbURI = process.env.MONGO_URI;

// Cek jika MONGO_URI ada
if (!dbURI) {
    console.error("Error: MONGO_URI tidak ditemukan di file .env");
    process.exit(1);
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

// --- Menghubungkan Routes ---
app.use('/api/users', userRoutes);
app.use('/api/pengumuman', pengumumanRoutes);
app.use('/api/laporan', laporanRoutes);
app.use('/api/iuran', iuranRoutes);
app.use('/api/kegiatan', kegiatanRoutes);
app.use('/api/umkm', umkmRoutes);