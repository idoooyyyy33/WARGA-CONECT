const express = require('express');
const router = express.Router();
const User = require('../models/User');
const { requireAdmin } = require('../middleware/auth');

// === ADMIN VERIFICATION METHODS ===

// POST /api/admin/send-verification (Kirim kode verifikasi ke email admin)
router.post('/send-verification', async (req, res) => {
    try {
        const { email } = req.body;

        // Cari user dengan email tersebut
        const user = await User.findOne({ email: email });
        if (!user) {
            return res.status(404).json({ message: 'User tidak ditemukan' });
        }

        // Cek apakah user adalah ketua_rt (admin)
        if (user.role !== 'ketua_rt') {
            return res.status(403).json({ message: 'User bukan admin' });
        }

        // Untuk simulasi, kita buat kode verifikasi sederhana
        // Dalam production, gunakan email service seperti nodemailer
        const verificationCode = Math.floor(100000 + Math.random() * 900000).toString();

        // Simpan kode verifikasi ke database (dalam production gunakan field terpisah)
        // Untuk sementara, kita return kode langsung untuk testing
        console.log(`📧 Kode verifikasi untuk ${email}: ${verificationCode}`);

        res.status(200).json({
            message: 'Kode verifikasi dikirim ke email',
            code: verificationCode // Hanya untuk testing, hapus di production
        });

    } catch (err) {
        res.status(500).json({ message: "Gagal mengirim kode verifikasi: " + err.message });
    }
});

// POST /api/admin/verify-code (Verifikasi kode admin)
router.post('/verify-code', async (req, res) => {
    try {
        const { email, code } = req.body;

        // Cari user dengan email tersebut
        const user = await User.findOne({ email: email });
        if (!user) {
            return res.status(404).json({ message: 'User tidak ditemukan' });
        }

        // Cek apakah user adalah ketua_rt (admin)
        if (user.role !== 'ketua_rt') {
            return res.status(403).json({ message: 'User bukan admin' });
        }

        // Untuk simulasi, kita terima kode apapun sebagai valid
        // Dalam production, bandingkan dengan kode yang disimpan di database
        if (!code || code.length !== 6) {
            return res.status(400).json({ message: 'Kode verifikasi tidak valid' });
        }

        res.status(200).json({
            message: 'Verifikasi admin berhasil',
            user: {
                _id: user._id,
                nama_lengkap: user.nama_lengkap,
                email: user.email,
                role: user.role
            }
        });

    } catch (err) {
        res.status(500).json({ message: "Gagal verifikasi kode: " + err.message });
    }
});

// === ADMIN STATS ===

// GET /api/admin/stats (Statistik dashboard admin)
router.get('/stats', requireAdmin, async (req, res) => {
    try {
        // Hitung jumlah data dari berbagai koleksi
        const userCount = await User.countDocuments();
        const pengumumanCount = await require('../models/Pengumuman').countDocuments();
        const laporanCount = await require('../models/LaporanWarga').countDocuments();
        const iuranCount = await require('../models/Iuran').countDocuments();
        const kegiatanCount = await require('../models/KegiatanWarga').countDocuments();
        const umkmCount = await require('../models/Umkm').countDocuments();
        const suratPengantarCount = await require('../models/SuratPengantar').countDocuments();

        res.json({
            total_users: userCount,
            total_pengumuman: pengumumanCount,
            total_laporan: laporanCount,
            total_iuran: iuranCount,
            total_kegiatan: kegiatanCount,
            total_umkm: umkmCount,
            total_surat_pengantar: suratPengantarCount
        });

    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// === ADMIN AKTIVITAS TERBARU ===

// GET /api/admin/aktivitas (Aktivitas terbaru untuk dashboard admin)
router.get('/aktivitas', requireAdmin, async (req, res) => {
    try {
        const limit = parseInt(req.query.limit) || 10;

        // Ambil aktivitas terbaru dari berbagai koleksi
        const activities = [];

        // Pengumuman terbaru
        const pengumuman = await require('../models/Pengumuman')
            .find()
            .populate('penulis_id', 'nama_lengkap')
            .sort({ createdAt: -1 })
            .limit(3);

        pengumuman.forEach(item => {
            activities.push({
                type: 'pengumuman',
                title: `Pengumuman baru: ${item.judul}`,
                description: item.isi.substring(0, 100) + '...',
                author: item.penulis_id?.nama_lengkap || 'Admin',
                date: item.createdAt
            });
        });

        // Laporan terbaru
        const laporan = await require('../models/LaporanWarga')
            .find()
            .populate('pelapor_id', 'nama_lengkap')
            .sort({ createdAt: -1 })
            .limit(3);

        laporan.forEach(item => {
            activities.push({
                type: 'laporan',
                title: `Laporan baru: ${item.judul_laporan}`,
                description: item.isi_laporan.substring(0, 100) + '...',
                author: item.pelapor_id?.nama_lengkap || 'Anonim',
                date: item.createdAt
            });
        });

        // Surat Pengantar terbaru
        const surat = await require('../models/SuratPengantar')
            .find()
            .populate('pengaju_id', 'nama_lengkap')
            .sort({ createdAt: -1 })
            .limit(3);

        surat.forEach(item => {
            activities.push({
                type: 'surat_pengantar',
                title: `Surat Pengantar: ${item.jenis_surat}`,
                description: `Pengajuan ${item.keperluan}`,
                author: item.pengaju_id?.nama_lengkap || 'Anonim',
                date: item.createdAt
            });
        });

        // Urutkan berdasarkan tanggal terbaru
        activities.sort((a, b) => new Date(b.date) - new Date(a.date));

        // Ambil hanya limit yang diminta
        const result = activities.slice(0, limit);

        res.json(result);

    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

module.exports = router;
