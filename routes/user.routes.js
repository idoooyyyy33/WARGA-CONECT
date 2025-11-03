const express = require('express');
const router = express.Router();
const User = require('../models/User'); // <- Mengimpor Model
const bcrypt = require('bcrypt');       // <- Mengimpor bcrypt

// === 1. Route GET /api/users/ (Mengambil Semua User) ===
router.get('/', async (req, res) => {
    try {
        const users = await User.find();
        res.json(users);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// === 2. Route POST /api/users/register (Registrasi User Baru) ===
router.post('/register', async (req, res) => {
    try {
        // 1. Ambil data dari body (dikirim oleh Postman/Flutter)
        const { nik, no_kk, nama_lengkap, email, password, rt, rw, no_hp } = req.body;

        // 2. Cek apakah email sudah ada
        const existingUser = await User.findOne({ email: email });
        if (existingUser) {
            return res.status(400).json({ message: 'Email sudah terdaftar' });
        }

        // 3. Buat hash password
        const salt = await bcrypt.genSalt(10);
        const password_hash = await bcrypt.hash(password, salt);

        // 4. Buat objek user baru (sesuai Model)
        const newUser = new User({
            nik,
            no_kk,
            nama_lengkap,
            email,
            password_hash: password_hash, // Simpan hash, bukan password asli
            rt,
            rw,
            no_hp
        });

        // 5. Simpan user baru ke database
        const savedUser = await newUser.save();
        
        // 6. Kirim balasan sukses (Status 201 = Created)
        res.status(201).json({ message: 'Registrasi berhasil', user: savedUser });

    } catch (err) {
        res.status(500).json({ message: "Gagal mendaftar: " + err.message });
    }
});

// === 3. Route POST /api/users/login (Login User) ===
router.post('/login', async (req, res) => {
    try {
        // 1. Ambil email dan password dari body
        const { email, password } = req.body;

        // 2. Cari user berdasarkan email
        const user = await User.findOne({ email: email });
        if (!user) {
            // JANGAN beri tahu emailnya tidak ada (demi keamanan)
            return res.status(400).json({ message: 'Email atau password salah' });
        }

        // 3. Bandingkan password yang dikirim dengan hash di database
        const isMatch = await bcrypt.compare(password, user.password_hash);
        
        if (!isMatch) {
            // Password tidak cocok
            return res.status(400).json({ message: 'Email atau password salah' });
        }

        // 4. Jika email ada DAN password cocok = LOGIN BERHASIL
        // (Kita hapus password_hash agar tidak ikut terkirim ke client)
        const userResponse = user.toObject();
        delete userResponse.password_hash;

        res.status(200).json({
            message: 'Login berhasil',
            user: userResponse
        });

    } catch (err) {
        res.status(500).json({ message: "Gagal login: " + err.message });
    }
});


// Ekspor file ini agar bisa dibaca oleh index.js
module.exports = router;