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
            return res.status(401).json({ success: false, message: 'User tidak terautentikasi' });
        }

        if (!jenis_surat || !keperluan) {
            return res.status(400).json({ success: false, message: 'Jenis surat dan keperluan harus diisi' });
        }

        // Proses lampiran dokumen
        const lampiranDokumen = {
            ktp: req.files?.ktp ? `/uploads/${req.files.ktp[0].filename}` : null,
            kk: req.files?.kk ? `/uploads/${req.files.kk[0].filename}` : null,
            dokumen_lain: []
        };

        // Proses dokumen lain jika ada (dari Flutter: field 'files')
        if (req.files?.dokumen_lain && dokumen_lain_nama) {
            const namaDokumenArray = Array.isArray(dokumen_lain_nama) ? dokumen_lain_nama : [dokumen_lain_nama];
            req.files.dokumen_lain.forEach((file, index) => {
                lampiranDokumen.dokumen_lain.push({
                    nama_dokumen: namaDokumenArray[index] || `Dokumen ${index + 1}`,
                    file_url: `/uploads/${file.filename}`
                });
            });
        } else if (req.files?.files) {
            // Handle field 'files' dari Flutter
            req.files.files.forEach((file, index) => {
                lampiranDokumen.dokumen_lain.push({
                    nama_dokumen: file.originalname || `Dokumen ${index + 1}`,
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

        res.status(201).json({ success: true, data: savedSurat });
    } catch (err) {
        console.error('❌ Error in POST /surat-pengantar:', err);
        res.status(500).json({ success: false, message: err.message || 'Internal server error' });
    }
});

// === READ (Membaca Surat Pengantar) ===
// GET /api/surat-pengantar (untuk user melihat pengajuannya sendiri)
router.get('/', authenticateUser, async (req, res) => {
    try {
        const userId = req.user?.id;
        if (!userId) {
            return res.status(401).json({ success: false, message: 'User tidak terautentikasi' });
        }

        const surat = await SuratPengantar.find({ pengaju_id: userId })
                            .populate('pengaju_id', 'nama_lengkap email')
                            .sort({ createdAt: -1 });
        res.json({ success: true, data: surat });
    } catch (err) {
        console.error('❌ Error in GET /surat-pengantar:', err);
        res.status(500).json({ success: false, message: err.message });
    }
});

// GET /api/surat-pengantar/admin (untuk admin melihat semua pengajuan) - HARUS SEBELUM :id
router.get('/admin', authenticateUser, async (req, res) => {
    try {
        // Check if user is admin
        if (req.user?.role !== 'ketua_rt') {
            return res.status(403).json({ success: false, message: 'Akses ditolak. Hanya admin yang dapat mengakses.' });
        }

        const surat = await SuratPengantar.find()
                            .populate('pengaju_id', 'nama_lengkap email')
                            .sort({ createdAt: -1 });
        res.json({ success: true, data: surat });
    } catch (err) {
        console.error('❌ Error in GET /surat-pengantar/admin:', err);
        res.status(500).json({ success: false, message: err.message });
    }
});

// === UPDATE (Admin mengubah status pengajuan) ===
// PUT /api/surat-pengantar/:id
router.put('/:id', requireAdmin, async (req, res) => {
    try {
        const { status_pengajuan, tanggapan_admin, file_surat } = req.body;

        if (!['Diajukan', 'Diproses', 'Disetujui', 'Ditolak'].includes(status_pengajuan)) {
            return res.status(400).json({ success: false, message: 'Status tidak valid' });
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
            return res.status(404).json({ success: false, message: 'Surat pengantar tidak ditemukan' });
        }

        res.json({ success: true, data: updatedSurat });
    } catch (err) {
        console.error('❌ Error in PUT /surat-pengantar/:id:', err);
        res.status(500).json({ success: false, message: err.message });
    }
});

// === DELETE (Menghapus pengajuan surat) ===
// DELETE /api/surat-pengantar/:id
router.delete('/:id', authenticateUser, async (req, res) => {
    try {
        const deletedSurat = await SuratPengantar.findByIdAndDelete(req.params.id);

        if (!deletedSurat) {
            return res.status(404).json({ success: false, message: 'Surat pengantar tidak ditemukan' });
        }

        res.json({ success: true, message: 'Pengajuan surat berhasil dihapus' });
    } catch (err) {
        console.error('❌ Error in DELETE /surat-pengantar/:id:', err);
        res.status(500).json({ success: false, message: err.message });
    }
});

module.exports = router;
