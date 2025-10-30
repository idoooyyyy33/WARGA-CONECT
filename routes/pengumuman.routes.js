const express = require('express');
const router = express.Router();
const Pengumuman = require('../models/Pengumuman');

// === CREATE (Membuat Pengumuman Baru) ===
// POST /api/pengumuman/
router.post('/', async (req, res) => {
    try {
        const { penulis_id, judul, isi } = req.body;

        const pengumumanBaru = new Pengumuman({
            penulis_id, // Nanti ini didapat dari user yang sedang login
            judul,
            isi
        });

        const savedPengumuman = await pengumumanBaru.save();
        res.status(201).json(savedPengumuman);

    } catch (err) {
        res.status(400).json({ message: err.message });
    }
});

// === READ (Membaca Semua Pengumuman) ===
// GET /api/pengumuman/
router.get('/', async (req, res) => {
    try {
        // .populate() akan mengambil data penulis dari 'users'
        // .sort() akan mengurutkan dari yang terbaru
        const pengumuman = await Pengumuman.find()
                                         .populate('penulis_id', 'nama_lengkap role')
                                         .sort({ createdAt: -1 }); 
        res.json(pengumuman);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// === UPDATE (Mengedit Pengumuman) ===
// PUT /api/pengumuman/:id
router.put('/:id', async (req, res) => {
    try {
        const { judul, isi } = req.body;

        const updatedPengumuman = await Pengumuman.findByIdAndUpdate(
            req.params.id, // Ambil ID dari URL
            { judul, isi }, // Data yang mau di-update
            { new: true } // Kirim balik data yang sudah ter-update
        );

        if (!updatedPengumuman) {
            return res.status(404).json({ message: 'Pengumuman tidak ditemukan' });
        }
        res.json(updatedPengumuman);

    } catch (err) {
        res.status(400).json({ message: err.message });
    }
});

// === DELETE (Menghapus Pengumuman) ===
// DELETE /api/pengumuman/:id
router.delete('/:id', async (req, res) => {
    try {
        const deletedPengumuman = await Pengumuman.findByIdAndDelete(req.params.id);

        if (!deletedPengumuman) {
            return res.status(404).json({ message: 'Pengumuman tidak ditemukan' });
        }
        res.json({ message: 'Pengumuman berhasil dihapus' });

    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});


module.exports = router;