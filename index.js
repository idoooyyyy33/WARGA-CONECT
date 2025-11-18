// 1. Impor semua library yang dibutuhkan
const express = require('express');
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const cors = require('cors');
const path = require('path'); // --- TAMBAHAN 1: Impor modul 'path' ---

// --- Impor file route user ---
const userRoutes = require('./routes/user.routes');
const pengumumanRoutes = require('./routes/pengumuman.routes');
const laporanRoutes = require('./routes/laporan.routes.js');
const iuranRoutes = require('./routes/iuran.routes.js');
const kegiatanRoutes = require('./routes/kegiatan.routes.js');
const umkmRoutes = require('./routes/umkm.routes.js');
const adminRoutes = require('./routes/admin.routes');
const suratPengantarRoutes = require('./routes/surat_pengantar.routes');
// 2. Load konfigurasi dari file .env
dotenv.config();

// 3. Inisialisasi aplikasi Express
const app = express();

// --- Konfigurasi Middleware ---
app.use(cors());
app.use(express.json()); // Agar Express bisa membaca JSON
app.use(express.urlencoded({ extended: true })); // Untuk parsing form data

// --- TAMBAHAN 2: Izinkan folder 'uploads' diakses secara publik ---
// Ini akan membuat file di 'uploads/bukti_bayar' bisa dilihat oleh aplikasi
// Contoh: http://172.168.47.153:3000/uploads/bukti_bayar/namagambar.jpg
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));
// --- BATAS TAMBAHAN ---


// Ambil PORT dari file .env, atau gunakan 3000 jika tidak ada
const PORT = process.env.PORT || 3000;

// Ambil koneksi string dari .env (terima kedua nama env yang mungkin digunakan)
const dbURI = process.env.MONGO_URI || process.env.MONGODB_URI;

// Cek jika koneksi DB ada
if (!dbURI) {
  console.error("Error: MONGO_URI atau MONGODB_URI tidak ditemukan di file .env");
  process.exit(1);
}

// 5. Hubungkan ke MongoDB
mongoose.connect(dbURI)
  .then(() => {
    console.log("✅ Berhasil terhubung ke MongoDB (wargaconnect_db)");

    // 6. Jalankan server HANYA JIKA koneksi DB berhasil
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`🚀 Server berjalan di http://10.61.5.241:${PORT}`); // Updated IP
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
app.use('/api/admin', adminRoutes);
app.use('/api/surat-pengantar', suratPengantarRoutes);
