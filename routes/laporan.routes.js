const express = require('express');
const router = express.Router();
const LaporanWarga = require('../models/LaporanWarga');

// === CREATE (Membuat Laporan Baru) ===
// POST /api/laporan
router.post('/', async (req, res) => {
    try {
        // Ambil data dari body
        const { pelapor_id, judul_laporan, isi_laporan, foto_laporan } = req.body;

        const laporanBaru = new LaporanWarga({
            pelapor_id,
            judul_laporan,
            isi_laporan,
            foto_laporan // (Ini akan jadi URL foto)
            // status_laporan akan otomatis 'Diterima'
        });

        const savedLaporan = await laporanBaru.save();
        res.status(201).json(savedLaporan);

    } catch (err) {
        res.status(400).json({ message: err.message });
    }
});

// === READ (Membaca Semua Laporan) ===
// GET /api/laporan
router.get('/', async (req, res) => {
    try {
        const laporan = await LaporanWarga.find()
                            .populate('pelapor_id', 'nama_lengkap') // Ambil nama pelapor
                            .sort({ createdAt: -1 }); // Urutkan dari terbaru
        res.json(laporan);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// === UPDATE (Mengubah Status Laporan, oleh RT/RW) ===
// PUT /api/laporan/:id
router.put('/:id', async (req, res) => {
    try {
        // Admin hanya bisa update status
        const { status_laporan } = req.body;

        if (!['Diterima', 'Diproses', 'Selesai', 'Ditolak'].includes(status_laporan)) {
            return res.status(400).json({ message: 'Status tidak valid' });
        }

        const updatedLaporan = await LaporanWarga.findByIdAndUpdate(
            req.params.id,
            { status_laporan: status_laporan },
            { new: true } // Kirim balik data yang sudah ter-update
        );

        if (!updatedLaporan) {
            return res.status(404).json({ message: 'Laporan tidak ditemukan' });
        }
        res.json(updatedLaporan);

    } catch (err) {
        res.status(400).json({ message: err.message });
    }
});

// === DELETE (Menghapus Laporan) ===
// DELETE /api/laporan/:id
router.delete('/:id', async (req, res) => {
    try {
        const deletedLaporan = await LaporanWarga.findByIdAndDelete(req.params.id);
        
        if (!deletedLaporan) {
            return res.status(404).json({ message: 'Laporan tidak ditemukan' });
        }
        res.json({ message: 'Laporan berhasil dihapus' });

    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});


module.exports = router;