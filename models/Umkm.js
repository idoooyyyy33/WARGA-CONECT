const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const UmkmSchema = new Schema({
    // Siapa pemilik usaha ini
    pemilik_id: {
        type: Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    nama_usaha: {
        type: String,
        required: true,
        unique: true // Nama usaha tidak boleh sama
    },
    deskripsi: {
        type: String,
        required: true
    },
    kategori: {
        type: String,
        required: true,
        // Contoh: 'Makanan', 'Minuman', 'Jasa', 'Kerajinan', 'Lainnya'
        enum: ['Makanan', 'Minuman', 'Jasa', 'Kerajinan', 'Lainnya']
    },
    foto_produk: {
        type: String, // URL ke foto
        required: false
    },
    no_hp_usaha: {
        type: String,
        required: true
    },
    // Misal diisi 'Blok A No. 10' atau link Google Maps
    lokasi: { 
        type: String,
        required: false
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
}, {
    collection: 'umkm' // Nama collection di MongoDB
});

module.exports = mongoose.model('Umkm', UmkmSchema);