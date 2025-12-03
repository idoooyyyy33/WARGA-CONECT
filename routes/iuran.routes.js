const express = require('express');
const router = express.Router();
const Iuran = require('../models/Iuran');
// Pastikan path ini benar sesuai struktur foldermu
const { createSingle } = require('../middleware/upload');

// === CREATE (Membuat Iuran Baru oleh Admin/Bendahara) ===
// POST /api/iuran
router.post('/', async (req, res) => {
    try {
        const { warga_id, pembuat_id, judul, kategori, jumlah, tanggal_tenggat, periode_bulan, periode_tahun } = req.body;

        const iuranBaru = new Iuran({
            warga_id,
            pembuat_id,
            judul,
            kategori,
            jumlah,
            tanggal_tenggat,
            periode_bulan,
            periode_tahun
            // status_pembayaran otomatis 'Belum Bayar' di Model
        });

        const savedIuran = await iuranBaru.save();
        res.status(201).json(savedIuran);

    } catch (err) {
        res.status(400).json({ message: err.message });
    }
});

// === READ (Membaca Semua Iuran) ===
// GET /api/iuran
// Bisa filter, misal /api/iuran?warga_id=...
router.get('/', async (req, res) => {
    try {
        let filter = {};
        // Jika ada query ?warga_id=... di URL, filter berdasarkan itu
        if (req.query.warga_id) {
            filter.warga_id = req.query.warga_id;
        }

        const iuran = await Iuran.find(filter)
            .populate('warga_id', 'nama_lengkap')
            .populate('pembuat_id', 'nama_lengkap')
            .sort({ createdAt: -1 });
        res.json(iuran);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// === UPDATE (Mengubah Status Iuran, misal oleh Warga saat update data text) ===
// PUT /api/iuran/:id
router.put('/:id', async (req, res) => {
    try {
        // Warga bisa update 'status_pembayaran' dan 'bukti_pembayaran'
        // Admin bisa update 'status_pembayaran'
        const { status_pembayaran, bukti_pembayaran } = req.body;

        let dataUpdate = {};
        if (status_pembayaran) {
            dataUpdate.status_pembayaran = status_pembayaran;
        }
        if (bukti_pembayaran) {
            dataUpdate.bukti_pembayaran = bukti_pembayaran;
        }

        const updatedIuran = await Iuran.findByIdAndUpdate(
            req.params.id,
            dataUpdate,
            { new: true }
        );

        if (!updatedIuran) {
            return res.status(404).json({ message: 'Iuran tidak ditemukan' });
        }
        res.json(updatedIuran);

    } catch (err) {
        res.status(400).json({ message: err.message });
    }
});

// === UPLOAD BUKTI PEMBAYARAN (PERBAIKAN DI SINI) ===
// PUT /api/iuran/:id/upload-proof
router.put('/:id/upload-proof', createSingle('bukti_pembayaran'), (err, req, res, next) => {
    // Handle multer errors (file validation errors)
    if (err) {
        console.error('❌ Multer error:', err.message);
        return res.status(400).json({ success: false, message: err.message || 'Upload gagal' });
    }
    next();
}, async (req, res) => {
    try {
        // File di multer berada di req.file
        if (!req.file) {
            return res.status(400).json({ success: false, message: 'File bukti_pembayaran tidak ditemukan' });
        }

        // Simpan nama file atau path ke field bukti_pembayaran di dokumen Iuran
        const fileName = req.file.filename;

        const updatedIuran = await Iuran.findByIdAndUpdate(
            req.params.id,
            { bukti_pembayaran: fileName, status_pembayaran: 'Menunggu Verifikasi' },
            { new: true }
        );

        if (!updatedIuran) {
            return res.status(404).json({ success: false, message: 'Iuran tidak ditemukan' });
        }

        res.json({ success: true, data: updatedIuran });
    } catch (err) {
        console.error(err);
        res.status(500).json({ success: false, message: err.message });
    }
});

// === DELETE (Menghapus Iuran) ===
// DELETE /api/iuran/:id
router.delete('/:id', async (req, res) => {
    try {
        const deletedIuran = await Iuran.findByIdAndDelete(req.params.id);

        if (!deletedIuran) {
            return res.status(404).json({ message: 'Iuran tidak ditemukan' });
        }
        res.json({ message: 'Iuran berhasil dihapus' });

    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

module.exports = router;