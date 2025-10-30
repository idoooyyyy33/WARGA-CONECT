const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const PengumumanSchema = new Schema({
    penulis_id: {
        type: Schema.Types.ObjectId, // Ini adalah penghubung ke collection 'users'
        ref: 'User', // Merujuk ke Model 'User'
        required: true
    },
    judul: {
        type: String,
        required: true
    },
    isi: {
        type: String,
        required: true
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
}, {
    collection: 'pengumuman' // Pastikan nama collection-nya sama
});

module.exports = mongoose.model('Pengumuman', PengumumanSchema);