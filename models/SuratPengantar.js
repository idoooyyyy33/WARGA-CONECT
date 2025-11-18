const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const SuratPengantarSchema = new Schema({
    pengaju_id: {
        type: Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    jenis_surat: {
        type: String,
        required: true,
        enum: ['KTP', 'KK', 'SKCK', 'Domisili', 'Kelahiran', 'Kematian', 'Nikah', 'Lainnya']
    },
    keperluan: {
        type: String,
        required: true
    },
    keterangan: {
        type: String,
        required: false
    },
    status_pengajuan: {
        type: String,
        required: true,
        enum: ['Diajukan', 'Diproses', 'Disetujui', 'Ditolak'],
        default: 'Diajukan'
    },
    tanggapan_admin: {
        type: String,
        required: false
    },
    file_surat: {
        type: String, // URL file surat yang dihasilkan
        required: false
    },
    lampiran_dokumen: {
        ktp: {
            type: String, // URL file KTP
            required: false
        },
        kk: {
            type: String, // URL file KK
            required: false
        },
        dokumen_lain: [{
            nama_dokumen: {
                type: String,
                required: true
            },
            file_url: {
                type: String,
                required: true
            }
        }]
    },
    createdAt: {
        type: Date,
        default: Date.now
    },
    updatedAt: {
        type: Date,
        default: Date.now
    }
}, {
    collection: 'surat_pengantar'
});

// Update updatedAt sebelum save
SuratPengantarSchema.pre('save', function(next) {
    this.updatedAt = Date.now();
    next();
});

module.exports = mongoose.model('SuratPengantar', SuratPengantarSchema);
