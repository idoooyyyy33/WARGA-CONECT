const express = require('express');
const router = express.Router();
const KegiatanWarga = require('../models/KegiatanWarga');
const { authenticateUser } = require('../middleware/auth');

// === CREATE (Membuat Kegiatan Baru) ===
// POST /api/kegiatan
// Require authentication so we can set penanggung_jawab_id from the logged-in user
router.post('/', authenticateUser, async (req, res) => {
    try {
        const { nama_kegiatan, deskripsi, tanggal_kegiatan, lokasi } = req.body;

        // penanggung_jawab_id comes from the authenticated user (req.user)
        const penanggung_jawab_id = req.user && req.user.id ? req.user.id : null;

        const kegiatanBaru = new KegiatanWarga({
            nama_kegiatan,
            deskripsi,
            tanggal_kegiatan,
            lokasi,
            penanggung_jawab_id
        });

        const savedKegiatan = await kegiatanBaru.save();
        res.status(201).json(savedKegiatan);

    } catch (err) {
        res.status(400).json({ message: err.message });
    }
});

// === READ (Membaca Semua Kegiatan) ===
// GET /api/kegiatan
router.get('/', async (req, res) => {
    try {
        const kegiatan = await KegiatanWarga.find()
                            .populate('penanggung_jawab_id', 'nama_lengkap')
                            .sort({ tanggal_kegiatan: 1 }); // Urutkan berdasarkan tanggal
        res.json(kegiatan);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// === UPDATE (Mengubah Kegiatan) ===
// PUT /api/kegiatan/:id
router.put('/:id', async (req, res) => {
    try {
        // Ambil data yang boleh di-update
        const { nama_kegiatan, deskripsi, tanggal_kegiatan, lokasi } = req.body;

        const updatedKegiatan = await KegiatanWarga.findByIdAndUpdate(
            req.params.id,
            { 
                nama_kegiatan, 
                deskripsi, 
                tanggal_kegiatan, 
                lokasi 
            },
            { new: true } 
        );

        if (!updatedKegiatan) {
            return res.status(404).json({ message: 'Kegiatan tidak ditemukan' });
        }
        res.json(updatedKegiatan);

    } catch (err) {
        res.status(400).json({ message: err.message });
    }
});

// === DELETE (Menghapus Kegiatan) ===
// DELETE /api/kegiatan/:id
router.delete('/:id', async (req, res) => {
    try {
        const deletedKegiatan = await KegiatanWarga.findByIdAndDelete(req.params.id);
        
        if (!deletedKegiatan) {
            return res.status(404).json({ message: 'Kegiatan tidak ditemukan' });
        }
        res.json({ message: 'Kegiatan berhasil dihapus' });

    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});


module.exports = router;