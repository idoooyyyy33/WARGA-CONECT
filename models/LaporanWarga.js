const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const LaporanWargaSchema = new Schema({
    pelapor_id: {
        type: Schema.Types.ObjectId, // Menghubung ke collection 'users'
        ref: 'User', // Merujuk ke Model 'User'
        required: true
    },
    judul_laporan: {
        type: String,
        required: true
    },
    isi_laporan: {
        type: String,
        required: true
    },
    foto_laporan: {
        type: String, // Kita akan simpan URL fotonya di sini
        required: false // Tidak semua laporan wajib ada foto
    },
    kategori_laporan: {
        type: String,
        required: false,
        default: 'Lainnya'
    },
    lokasi: {
        type: String,
        required: false
    },
    tanggapan: {
        type: String,
        required: false
    },
    status_laporan: {
        type: String,
        required: true,
        // enum: memastikan nilainya hanya salah satu dari ini
        enum: ['Diterima', 'Diproses', 'Selesai', 'Ditolak'],
        default: 'Diterima' // Status default saat pertama kali dibuat
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
}, {
    collection: 'laporan_warga' // Nama collection di MongoDB
});

module.exports = mongoose.model('LaporanWarga', LaporanWargaSchema);