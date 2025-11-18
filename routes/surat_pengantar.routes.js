const express = require('express');
const router = express.Router();
const SuratPengantar = require('../models/SuratPengantar');
const { authenticateUser, requireAdmin } = require('../middleware/auth');
const { uploadLampiran } = require('../middleware/upload');

// === CREATE (Pengajuan Surat Pengantar Baru) ===
// POST /api/surat-pengantar
router.post('/', authenticateUser, uploadLampiran, async (req, res) => {
    try {
        const { jenis_surat, keperluan, keterangan, dokumen_lain_nama } = req.body;

        // Ambil user ID dari token (middleware auth akan menambahkannya)
        const pengaju_id = req.user?.id || req.body.pengaju_id;

        if (!pengaju_id) {
            return res.status(401).json({ message: 'User tidak terautentikasi' });
        }

        // Proses lampiran dokumen
        const lampiranDokumen = {
            ktp: req.files?.ktp ? `/uploads/${req.files.ktp[0].filename}` : null,
            kk: req.files?.kk ? `/uploads/${req.files.kk[0].filename}` : null,
            dokumen_lain: []
        };

        // Proses dokumen lain jika ada
        if (req.files?.dokumen_lain && dokumen_lain_nama) {
            const namaDokumenArray = Array.isArray(dokumen_lain_nama) ? dokumen_lain_nama : [dokumen_lain_nama];
            req.files.dokumen_lain.forEach((file, index) => {
                lampiranDokumen.dokumen_lain.push({
                    nama_dokumen: namaDokumenArray[index] || `Dokumen ${index + 1}`,
                    file_url: `/uploads/${file.filename}`
                });
            });
        }

        const suratBaru = new SuratPengantar({
            pengaju_id,
            jenis_surat,
            keperluan,
            keterangan,
            lampiran_dokumen: lampiranDokumen,
            // status_pengajuan otomatis 'Diajukan'
        });

        const savedSurat = await suratBaru.save();
        await savedSurat.populate('pengaju_id', 'nama_lengkap email');

        res.status(201).json(savedSurat);
    } catch (err) {
        res.status(400).json({ message: err.message });
    }
});

// === READ (Membaca Surat Pengantar) ===
// GET /api/surat-pengantar (untuk user melihat pengajuannya sendiri)
router.get('/', authenticateUser, async (req, res) => {
    try {
        const userId = req.user?.id;
        if (!userId) {
            return res.status(401).json({ message: 'User tidak terautentikasi' });
        }

        const surat = await SuratPengantar.find({ pengaju_id: userId })
                            .populate('pengaju_id', 'nama_lengkap email')
                            .sort({ createdAt: -1 });
        res.json(surat);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// GET /api/surat-pengantar/admin (untuk admin melihat semua pengajuan)
router.get('/admin', requireAdmin, async (req, res) => {
    try {
        const surat = await SuratPengantar.find()
                            .populate('pengaju_id', 'nama_lengkap email')
                            .sort({ createdAt: -1 });
        res.json(surat);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// === UPDATE (Admin mengubah status pengajuan) ===
// PUT /api/surat-pengantar/:id
router.put('/:id', requireAdmin, async (req, res) => {
    try {
        const { status_pengajuan, tanggapan_admin, file_surat } = req.body;

        if (!['Diajukan', 'Diproses', 'Disetujui', 'Ditolak'].includes(status_pengajuan)) {
            return res.status(400).json({ message: 'Status tidak valid' });
        }

        const updateData = {
            status_pengajuan,
            tanggapan_admin,
            file_surat,
            updatedAt: Date.now()
        };

        const updatedSurat = await SuratPengantar.findByIdAndUpdate(
            req.params.id,
            updateData,
            { new: true }
        ).populate('pengaju_id', 'nama_lengkap email');

        if (!updatedSurat) {
            return res.status(404).json({ message: 'Surat pengantar tidak ditemukan' });
        }

        res.json(updatedSurat);
    } catch (err) {
        res.status(400).json({ message: err.message });
    }
});

// === DELETE (Menghapus pengajuan surat) ===
// DELETE /api/surat-pengantar/:id
router.delete('/:id', authenticateUser, async (req, res) => {
    try {
        const deletedSurat = await SuratPengantar.findByIdAndDelete(req.params.id);

        if (!deletedSurat) {
            return res.status(404).json({ message: 'Surat pengantar tidak ditemukan' });
        }

        res.json({ message: 'Pengajuan surat berhasil dihapus' });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

module.exports = router;
