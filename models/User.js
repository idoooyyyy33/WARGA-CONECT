const mongoose = require('mongoose');
const Schema = mongoose.Schema;

// Ini adalah "sub-cetakan" untuk array 'keluarga' di dalam User
const KeluargaSchema = new Schema({
    nik: {
        type: String,
        required: true
    },
    nama_lengkap: {
        type: String,
        required: true
    },
    status_hubungan: {
        type: String,
        required: true
    }
});

// Ini adalah cetakan utama untuk collection 'users'
const UserSchema = new Schema({
    nik: {
        type: String,
        required: true, // Wajib diisi
        unique: true      // Tidak boleh ada yang sama
    },
    no_kk: {
        type: String,
        required: true
    },
    nama_lengkap: {
        type: String,
        required: true
    },
    password_hash: {
        type: String,
        required: true
    },
    alamat_lengkap: {
        type: String
    },
    rt: {
        type: String,
        required: true
    },
    rw: {
        type: String,
        required: true
    },
    no_hp: {
        type: String,
        unique: true
    },
    email: {
        type: String,
        required: true,
        unique: true
    },
    role: {
        type: String,
        enum: ['ketua_rt', 'bendahara', 'warga', 'keamanan'], // Hanya boleh diisi ini
        default: 'warga' // Nilai default jika tidak diisi
    },
    status_akun: {
        type: String,
        enum: ['aktif', 'nonaktif', 'menunggu_verifikasi'],
        default: 'aktif'
    },
    keluarga: [KeluargaSchema], // Menggunakan "sub-cetakan" di atas
    createdAt: {
        type: Date,
        default: Date.now
    }
}, {
    // 'users' adalah nama collection di MongoDB Anda
    collection: 'users' 
});

// Ekspor model ini agar bisa dipakai di file lain (seperti index.js)
module.exports = mongoose.model('User', UserSchema);