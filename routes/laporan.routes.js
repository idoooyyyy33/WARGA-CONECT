const express = require('express');
const router = express.Router();
const LaporanWarga = require('../models/LaporanWarga');
const User = require('../models/User');

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
            foto_laporan, // (Ini akan jadi URL foto)
            status_laporan: 'Diterima' // Explicitly set status
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
// PUT /api/laporan/:id (untuk user/warga)
// PUT /api/admin/laporan/:id (untuk admin)
router.put('/:id', async (req, res) => {
    try {
        // Admin bisa update status dan tanggapan
        const { status_laporan, tanggapan, kategori_laporan, lokasi } = req.body;

        const updateData = {};

        if (status_laporan) {
            if (!['Diterima', 'Diproses', 'Selesai', 'Ditolak'].includes(status_laporan)) {
                return res.status(400).json({ message: 'Status tidak valid' });
            }
            updateData.status_laporan = status_laporan;
        }

        if (tanggapan !== undefined) {
            updateData.tanggapan = tanggapan;
        }

        if (kategori_laporan !== undefined) {
            updateData.kategori_laporan = kategori_laporan;
        }

        if (lokasi !== undefined) {
            updateData.lokasi = lokasi;
        }

        const updatedLaporan = await LaporanWarga.findByIdAndUpdate(
            req.params.id,
            updateData,
            { new: true } // Kirim balik data yang sudah ter-update
        ).populate('pelapor_id', 'nama_lengkap email');

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