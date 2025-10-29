const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const KegiatanWargaSchema = new Schema({
    nama_kegiatan: {
        type: String,
        required: true
    },
    deskripsi: {
        type: String,
        required: true
    },
    tanggal_kegiatan: {
        type: Date,
        required: true
    },
    lokasi: {
        type: String,
        required: true
    },
    // Siapa yang post/penanggung jawab
    penanggung_jawab_id: {
        type: Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
}, {
    collection: 'kegiatan_warga' // Nama collection di MongoDB
});

module.exports = mongoose.model('KegiatanWarga', KegiatanWargaSchema);