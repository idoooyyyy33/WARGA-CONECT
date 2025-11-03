const express = require('express');
const router = express.Router();
const Umkm = require('../models/Umkm');

// === CREATE (Mendaftarkan UMKM Baru) ===
// POST /api/umkm
router.post('/', async (req, res) => {
    try {
        const { pemilik_id, nama_usaha, deskripsi, kategori, foto_produk, no_hp_usaha, lokasi } = req.body;

        const umkmBaru = new Umkm({
            pemilik_id,
            nama_usaha,
            deskripsi,
            kategori,
            foto_produk,
            no_hp_usaha,
            lokasi
        });

        const savedUmkm = await umkmBaru.save();
        res.status(201).json(savedUmkm);

    } catch (err) {
        // Tangkap error jika 'nama_usaha' duplikat
        if (err.code === 11000) {
            return res.status(400).json({ message: 'Nama usaha sudah terdaftar' });
        }
        res.status(400).json({ message: err.message });
    }
});

// === READ (Membaca Semua UMKM) ===
// GET /api/umkm
router.get('/', async (req, res) => {
    try {
        const umkm = await Umkm.find()
                            .populate('pemilik_id', 'nama_lengkap')
                            .sort({ nama_usaha: 1 }); // Urutkan A-Z
        res.json(umkm);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// === UPDATE (Mengubah Data UMKM) ===
// PUT /api/umkm/:id
router.put('/:id', async (req, res) => {
    try {
        // Ambil data yang boleh di-update
        const { nama_usaha, deskripsi, kategori, foto_produk, no_hp_usaha, lokasi } = req.body;

        const updatedUmkm = await Umkm.findByIdAndUpdate(
            req.params.id,
            { 
                nama_usaha, 
                deskripsi, 
                kategori, 
                foto_produk, 
                no_hp_usaha, 
                lokasi
            },
            { new: true, runValidators: true } // 'runValidators' untuk cek jika ada data unik
        );

        if (!updatedUmkm) {
            return res.status(404).json({ message: 'UMKM tidak ditemukan' });
        }
        res.json(updatedUmkm);

    } catch (err) {
        if (err.code === 11000) {
            return res.status(400).json({ message: 'Nama usaha sudah terdaftar' });
        }
        res.status(400).json({ message: err.message });
    }
});

// === DELETE (Menghapus UMKM) ===
// DELETE /api/umkm/:id
router.delete('/:id', async (req, res) => {
    try {
        const deletedUmkm = await Umkm.findByIdAndDelete(req.params.id);
        
        if (!deletedUmkm) {
            return res.status(404).json({ message: 'UMKM tidak ditemukan' });
        }
        res.json({ message: 'UMKM berhasil dihapus' });

    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});


module.exports = router;