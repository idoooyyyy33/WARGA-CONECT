const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const IuranSchema = new Schema({
    // User yang WAJIB bayar
    warga_id: {
        type: Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    // Dibuat oleh siapa
    pembuat_id: {
        type: Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    judul: {
        type: String,
        required: true
    },
    kategori: {
        type: String,
        required: true,
        // Contoh: 'Keamanan', 'Sampah', 'Sosial'
    },
    jumlah: {
        type: Number,
        required: true
    },
    tanggal_tenggat: {
        type: Date,
        required: true
    },
    status_pembayaran: {
        type: String,
        required: true,
        enum: ['Belum Bayar', 'Menunggu Konfirmasi', 'Lunas', 'Dibatalkan'],
        default: 'Belum Bayar'
    },
    // Untuk periode bulan apa iuran ini
    periode_bulan: {
        type: Number, // 1 = Jan, 2 = Feb,
        required: true
    },
    periode_tahun: {
        type: Number, // 2024, 2025
        required: true
    },
    bukti_pembayaran: {
        type: String, // URL/Link ke foto bukti transfer
        required: false
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
}, {
    collection: 'iuran' // Nama collection di MongoDB
});

module.exports = mongoose.model('Iuran', IuranSchema);
