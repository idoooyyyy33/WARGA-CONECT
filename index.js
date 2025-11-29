// 1. Import semua library yang dibutuhkan
const express = require('express');
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const cors = require('cors');
const path = require('path');

// --- Import file route ---
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
app.use(cors({
  origin: true,
  credentials: true
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// --- Static files ---
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Ambil PORT dari file .env, atau gunakan 3000 jika tidak ada
const PORT = process.env.PORT || 3000;

// Ambil koneksi string dari .env
const dbURI = process.env.MONGO_URI || process.env.MONGODB_URI;

// Cek jika koneksi DB ada
if (!dbURI) {
  console.error("❌ Error: MONGO_URI atau MONGODB_URI tidak ditemukan di file .env");
  process.exit(1);
}

// 5. Hubungkan ke MongoDB
mongoose.connect(dbURI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => {
  console.log("✅ Berhasil terhubung ke MongoDB");

  // 6. Jalankan server HANYA JIKA koneksi DB berhasil
  app.listen(PORT, '172.168.47.124', () => {
    console.log(`🚀 Server berjalan di http://172.168.47.124:${PORT}`);
    console.log(`🚀 Akses juga via http://localhost:${PORT}`);
    console.log(`🚀 API base URL: http://172.168.47.124:${PORT}/api`);
  });
})
.catch((err) => {
  console.error("❌ Gagal terhubung ke MongoDB:", err);
  process.exit(1);
});

// 7. Route sederhana untuk tes
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Selamat datang di WargaConnect API!',
    version: '1.0.0',
    endpoints: {
      users: '/api/users',
      pengumuman: '/api/pengumuman',
      laporan: '/api/laporan',
      iuran: '/api/iuran',
      kegiatan: '/api/kegiatan',
      umkm: '/api/umkm',
      admin: '/api/admin',
      suratPengantar: '/api/surat-pengantar'
    }
  });
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

// --- Error Handling Middleware ---
app.use((err, req, res, next) => {
  console.error('❌ Error:', err);
  res.status(500).json({
    success: false,
    message: 'Internal server error',
    error: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// --- 404 Handler ---
// Use app.all instead of app.use with wildcard pattern to avoid path-to-regexp issues
// Use a path-less `app.use` so router/path-to-regexp is not invoked here
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: `Route ${req.originalUrl} not found`,
    availableRoutes: [
      '/api/users',
      '/api/pengumuman',
      '/api/laporan',
      '/api/iuran',
      '/api/kegiatan',
      '/api/umkm',
      '/api/admin',
      '/api/surat-pengantar'
    ]
  });
});

module.exports = app;
