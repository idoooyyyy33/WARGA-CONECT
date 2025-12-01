const express = require('express');
const router = express.Router();
const User = require('../models/User');
const { authenticateUser, requireAdmin } = require('../middleware/auth');

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
router.get('/stats', authenticateUser, requireAdmin, async (req, res) => {
    try {
        // Hitung jumlah data dari berbagai koleksi
        const userCount = await User.countDocuments({ role: 'warga' }); // Hanya hitung warga
        const pengumumanCount = await require('../models/Pengumuman').countDocuments();
        const laporanCount = await require('../models/LaporanWarga').countDocuments();
        const iuranCount = await require('../models/Iuran').countDocuments();
        const kegiatanCount = await require('../models/KegiatanWarga').countDocuments();
        const umkmCount = await require('../models/Umkm').countDocuments();
        const suratPengantarCount = await require('../models/SuratPengantar').countDocuments();

        // Hitung laporan dengan status pending (Diterima atau Diproses)
        const laporanPendingCount = await require('../models/LaporanWarga').countDocuments({
            $or: [
                { status_laporan: 'Diterima' },
                { status_laporan: 'Diproses' }
            ]
        });

        // Hitung total iuran bulan ini
        const currentDate = new Date();
        const currentMonth = currentDate.getMonth() + 1; // getMonth() returns 0-11
        const currentYear = currentDate.getFullYear();

        const iuranBulanIni = await require('../models/Iuran').aggregate([
            {
                $match: {
                    periode_bulan: currentMonth,
                    periode_tahun: currentYear,
                    status_pembayaran: "Lunas"
                }
            },
            {
                $group: {
                    _id: null,
                    total: { $sum: "$jumlah" }
                }
            }
        ]);

        const totalIuranBulanIni = iuranBulanIni.length > 0 ? iuranBulanIni[0].total : 0;

        res.json({
            totalWarga: userCount,
            totalPengumuman: pengumumanCount,
            totalLaporan: laporanCount,
            totalLaporanPending: laporanPendingCount,
            totalIuran: iuranCount,
            totalIuranBulanIni: totalIuranBulanIni,
            totalKegiatan: kegiatanCount,
            totalUmkm: umkmCount,
            totalSuratPengantar: suratPengantarCount
        });

    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// === ADMIN AKTIVITAS TERBARU ===

// GET /api/admin/aktivitas (Aktivitas terbaru untuk dashboard admin)
router.get('/aktivitas', authenticateUser, requireAdmin, async (req, res) => {
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
                tipe: 'pengumuman',
                judul: `Pengumuman baru: ${item.judul}`,
                deskripsi: item.isi.substring(0, 100) + '...',
                createdAt: item.createdAt
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
                tipe: 'laporan',
                judul: `Laporan baru: ${item.judul_laporan}`,
                deskripsi: item.isi_laporan.substring(0, 100) + '...',
                createdAt: item.createdAt
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
                tipe: 'surat_pengantar',
                judul: `Surat Pengantar: ${item.jenis_surat}`,
                deskripsi: `Pengajuan ${item.keperluan}`,
                createdAt: item.createdAt
            });
        });

        // Iuran terbaru
        const iuran = await require('../models/Iuran')
            .find()
            .populate('warga_id', 'nama_lengkap')
            .sort({ createdAt: -1 })
            .limit(3);

        iuran.forEach(item => {
            activities.push({
                tipe: 'iuran',
                judul: `Pembayaran iuran: ${item.jenis_iuran}`,
                deskripsi: `Oleh ${item.warga_id?.nama_lengkap || 'Warga'} - Rp ${item.jumlah}`,
                createdAt: item.createdAt
            });
        });

        // Warga terbaru
        const wargaBaru = await User.find({ role: "warga" })
            .sort({ createdAt: -1 })
            .limit(3);

        wargaBaru.forEach(item => {
            activities.push({
                tipe: 'warga',
                judul: `Warga baru: ${item.nama_lengkap}`,
                deskripsi: `Bergabung pada ${item.createdAt.toISOString().split('T')[0]}`,
                createdAt: item.createdAt
            });
        });

        // Kegiatan terbaru
        const kegiatan = await require('../models/KegiatanWarga')
            .find()
            .populate('penanggung_jawab_id', 'nama_lengkap')
            .sort({ createdAt: -1 })
            .limit(3);

        kegiatan.forEach(item => {
            activities.push({
                tipe: 'kegiatan',
                judul: `Kegiatan: ${item.nama_kegiatan}`,
                deskripsi: item.deskripsi.substring(0, 100) + '...',
                createdAt: item.createdAt
            });
        });

        // UMKM terbaru
        const umkm = await require('../models/Umkm')
            .find()
            .populate('pemilik_id', 'nama_lengkap')
            .sort({ createdAt: -1 })
            .limit(3);

        umkm.forEach(item => {
            activities.push({
                tipe: 'umkm',
                judul: `UMKM baru: ${item.nama_usaha}`,
                deskripsi: `Oleh ${item.pemilik_id?.nama_lengkap || 'Warga'}`,
                createdAt: item.createdAt
            });
        });

        // Urutkan berdasarkan tanggal terbaru
        activities.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

        // Ambil hanya limit yang diminta
        const result = activities.slice(0, limit);

        res.json(result);

    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

module.exports = router;


// === ADMIN LAPORAN MANAGEMENT ===

// GET /api/admin/laporan (Admin melihat semua laporan)
router.get("/laporan", authenticateUser, requireAdmin, async (req, res) => {
    try {
        const laporan = await require("../models/LaporanWarga")
            .find()
            .populate("pelapor_id", "nama_lengkap")
            .sort({ createdAt: -1 });

        const transformedData = laporan.map(item => ({
            id: item._id,
            judul: item.judul_laporan || "Laporan",
            deskripsi: item.isi_laporan || "",
            kategori: item.kategori_laporan || "Lainnya",
            status: item.status_laporan || "Menunggu",
            tanggal: item.createdAt ? item.createdAt.toISOString().split("T")[0] : "",
            nama_pelapor: item.pelapor_id?.nama_lengkap || "Anonim",
            lokasi: item.lokasi || "",
            tanggapan: item.tanggapan || "",
        }));

        res.json(transformedData);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// PUT /api/admin/laporan/:id (Admin update status laporan)
router.put("/laporan/:id", authenticateUser, requireAdmin, async (req, res) => {
    try {
        const { status_laporan, tanggapan } = req.body;

        if (!["Diterima", "Diproses", "Selesai", "Ditolak"].includes(status_laporan)) {
            return res.status(400).json({ message: "Status tidak valid" });
        }

        const updatedLaporan = await require("../models/LaporanWarga").findByIdAndUpdate(
            req.params.id,
            { status_laporan: status_laporan, tanggapan: tanggapan },
            { new: true }
        );

        if (!updatedLaporan) {
            return res.status(404).json({ message: "Laporan tidak ditemukan" });
        }

        res.json(updatedLaporan);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// DELETE /api/admin/laporan/:id (Admin hapus laporan)
router.delete("/laporan/:id", authenticateUser, requireAdmin, async (req, res) => {
    try {
        const deletedLaporan = await require("../models/LaporanWarga").findByIdAndDelete(req.params.id);

        if (!deletedLaporan) {
            return res.status(404).json({ message: "Laporan tidak ditemukan" });
        }

        res.json({ message: "Laporan berhasil dihapus" });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// === ADMIN IURAN MANAGEMENT ===

// GET /api/admin/iuran (Admin melihat semua iuran dengan filter bulan/tahun)
router.get("/iuran", authenticateUser, requireAdmin, async (req, res) => {
    try {
        const { bulan, tahun } = req.query;

        let filter = {};
        if (bulan && tahun) {
            filter = {
                "periode.bulan": parseInt(bulan),
                "periode.tahun": parseInt(tahun)
            };
        }

        const iuran = await require("../models/Iuran")
            .find(filter)
            .populate("warga_id", "nama_lengkap")
            .sort({ createdAt: -1 });

        const transformedData = iuran.map(item => ({
            id: item._id?.toString() || "",
            warga_id: item.warga_id?._id?.toString() || "",
            nama_warga: item.warga_id?.nama_lengkap || "Tidak Diketahui",
            jenis_iuran: item.jenis_iuran || "Iuran RT",
            nominal: item.jumlah || 0,
            status: item.status_pembayaran || "Belum Lunas",
            tanggal_bayar: item.tanggal_bayar,
            metode_pembayaran: item.metode_pembayaran || "-",
            bukti_pembayaran: item.bukti_pembayaran,
            periode_bulan: item.periode?.bulan?.toString() || "",
            periode_tahun: item.periode?.tahun || 0,
        }));

        res.json(transformedData);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// POST /api/admin/iuran (Admin buat iuran baru)
router.post("/iuran", authenticateUser, requireAdmin, async (req, res) => {
    try {
        const iuranData = req.body;
        const newIuran = new (require("../models/Iuran"))(iuranData);
        const savedIuran = await newIuran.save();
        res.status(201).json(savedIuran);
    } catch (err) {
        res.status(400).json({ message: err.message });
    }
});

// PUT /api/admin/iuran/:id (Admin update iuran)
router.put("/iuran/:id", authenticateUser, requireAdmin, async (req, res) => {
    try {
        const updateData = req.body;
        const updatedIuran = await require("../models/Iuran").findByIdAndUpdate(
            req.params.id,
            updateData,
            { new: true }
        );

        if (!updatedIuran) {
            return res.status(404).json({ message: "Iuran tidak ditemukan" });
        }

        res.json(updatedIuran);
    } catch (err) {
        res.status(400).json({ message: err.message });
    }
});

// DELETE /api/admin/iuran/:id (Admin hapus iuran)
router.delete("/iuran/:id", authenticateUser, requireAdmin, async (req, res) => {
    try {
        const deletedIuran = await require("../models/Iuran").findByIdAndDelete(req.params.id);

        if (!deletedIuran) {
            return res.status(404).json({ message: "Iuran tidak ditemukan" });
        }

        res.json({ message: "Iuran berhasil dihapus" });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// POST /api/admin/iuran/massal (Admin buat iuran massal)
router.post("/iuran/massal", authenticateUser, requireAdmin, async (req, res) => {
    try {
        const { pembuat_id, judul_iuran, jenis_iuran, jumlah, periode, jatuh_tempo } = req.body;

        // Buat iuran untuk semua warga
        const wargaList = await User.find({ role: "warga" });

        const iuranPromises = wargaList.map(warga => {
            const newIuran = new (require("../models/Iuran"))({
                warga_id: warga._id,
                pembuat_id: pembuat_id,
                judul_iuran: judul_iuran,
                jenis_iuran: jenis_iuran,
                jumlah: jumlah,
                periode: periode,
                jatuh_tempo: jatuh_tempo,
                status_pembayaran: "Belum Lunas"
            });
            return newIuran.save();
        });

        const savedIuran = await Promise.all(iuranPromises);
        res.status(201).json(savedIuran);
    } catch (err) {
        res.status(400).json({ message: err.message });
    }
});

// GET /api/admin/iuran/massal (Admin lihat template iuran massal)
router.get("/iuran/massal", requireAdmin, async (req, res) => {
    try {
        // Return template atau info iuran massal
        res.json({ message: "Endpoint untuk template iuran massal" });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// PUT /api/admin/iuran/massal/:id (Admin update template iuran massal)
router.put("/iuran/massal/:id", authenticateUser, requireAdmin, async (req, res) => {
    try {
        const updateData = req.body;
        // Update template iuran massal
        res.json({ message: "Template iuran massal berhasil diupdate" });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// DELETE /api/admin/iuran/massal/:id (Admin hapus template iuran massal)
router.delete("/iuran/massal/:id", authenticateUser, requireAdmin, async (req, res) => {
    try {
        // Hapus template iuran massal
        res.json({ message: "Template iuran massal berhasil dihapus" });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// === ADMIN UMKM MANAGEMENT ===

// GET /api/admin/umkm (Admin melihat semua UMKM)
router.get("/umkm", authenticateUser, requireAdmin, async (req, res) => {
    try {
        const umkm = await require("../models/Umkm")
            .find()
            .populate("pemilik_id", "nama_lengkap")
            .sort({ createdAt: -1 });

        res.json(umkm);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// POST /api/admin/umkm (Admin buat UMKM baru)
router.post("/umkm", requireAdmin, async (req, res) => {
    try {
        const { pemilik_id } = req.body;

        // Cek apakah pemilik_id ada di database
        const user = await User.findById(pemilik_id);
        if (!user) {
            return res.status(404).json({ message: 'Data warga tidak ditemukan' });
        }

        const umkmData = req.body;
        const newUmkm = new (require("../models/Umkm"))(umkmData);
        const savedUmkm = await newUmkm.save();
        res.status(201).json(savedUmkm);
    } catch (err) {
        res.status(400).json({ message: err.message });
    }
});

// PUT /api/admin/umkm/:id (Admin update UMKM)
router.put("/umkm/:id", authenticateUser, requireAdmin, async (req, res) => {
    try {
        const updateData = req.body;
        const updatedUmkm = await require("../models/Umkm").findByIdAndUpdate(
            req.params.id,
            updateData,
            { new: true }
        );

        if (!updatedUmkm) {
            return res.status(404).json({ message: "UMKM tidak ditemukan" });
        }

        res.json(updatedUmkm);
    } catch (err) {
        res.status(400).json({ message: err.message });
    }
});

// DELETE /api/admin/umkm/:id (Admin hapus UMKM)
router.delete("/umkm/:id", requireAdmin, async (req, res) => {
    try {
        const deletedUmkm = await require("../models/Umkm").findByIdAndDelete(req.params.id);

        if (!deletedUmkm) {
            return res.status(404).json({ message: "UMKM tidak ditemukan" });
        }

        res.json({ message: "UMKM berhasil dihapus" });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// === ADMIN WARGA MANAGEMENT ===

// GET /api/admin/warga (Admin melihat semua warga)
router.get("/warga", authenticateUser, requireAdmin, async (req, res) => {
    try {
        const warga = await User.find({ role: "warga" }).sort({ createdAt: -1 });
        res.json(warga);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// POST /api/admin/warga (Admin buat warga baru)
router.post("/warga", requireAdmin, async (req, res) => {
    try {
        const wargaData = req.body;
        wargaData.role = "warga"; // Pastikan role adalah warga
        const newWarga = new User(wargaData);
        const savedWarga = await newWarga.save();
        res.status(201).json(savedWarga);
    } catch (err) {
        res.status(400).json({ message: err.message });
    }
});

// PUT /api/admin/warga/:id (Admin update warga)
router.put("/warga/:id", authenticateUser, requireAdmin, async (req, res) => {
    try {
        const updateData = req.body;
        const updatedWarga = await User.findByIdAndUpdate(
            req.params.id,
            updateData,
            { new: true }
        );

        if (!updatedWarga) {
            return res.status(404).json({ message: "Warga tidak ditemukan" });
        }

        res.json(updatedWarga);
    } catch (err) {
        res.status(400).json({ message: err.message });
    }
});

// DELETE /api/admin/warga/:id (Admin hapus warga)
router.delete("/warga/:id", requireAdmin, async (req, res) => {
    try {
        const deletedWarga = await User.findByIdAndDelete(req.params.id);

        if (!deletedWarga) {
            return res.status(404).json({ message: "Warga tidak ditemukan" });
        }

        res.json({ message: "Warga berhasil dihapus" });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

module.exports = router;

