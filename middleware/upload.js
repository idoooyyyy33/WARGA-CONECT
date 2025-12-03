const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Buat folder uploads jika belum ada
const uploadDir = path.join(__dirname, '../uploads');
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
}

// Konfigurasi storage
const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, uploadDir);
    },
    filename: function (req, file, cb) {
        // Generate unique filename dengan timestamp
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
    }
});

// Filter file yang diizinkan
const fileFilter = (req, file, cb) => {
    // Izinkan hanya file gambar dan PDF
    const allowedExtensions = /\.(jpeg|jpg|png|pdf)$/i;
    const allowedMimetypes = ['image/jpeg', 'image/jpg', 'image/png', 'application/pdf'];
    
    const extname = allowedExtensions.test(file.originalname);
    const mimetype = allowedMimetypes.includes(file.mimetype);
    
    // DEBUG: Log file info untuk troubleshooting
    console.log(`📁 Upload file: ${file.originalname}`);
    console.log(`   - MIME type: ${file.mimetype}`);
    console.log(`   - Extension valid: ${extname}`);
    console.log(`   - MIME valid: ${mimetype}`);

    // Jika extension valid, izinkan (lenient mode untuk client yang berbeda-beda)
    if (extname) {
        return cb(null, true);
    } else {
        console.log(`❌ File rejected: ${file.originalname}`);
        cb(new Error('Tipe file tidak didukung. Gunakan JPG, PNG, atau PDF'));
    }
};

// Konfigurasi multer
const upload = multer({
    storage: storage,
    limits: {
        fileSize: 5 * 1024 * 1024, // 5MB limit
    },
    fileFilter: fileFilter
});

// Middleware untuk upload multiple files
const uploadLampiran = upload.fields([
    { name: 'ktp', maxCount: 1 },
    { name: 'kk', maxCount: 1 },
    { name: 'dokumen_lain', maxCount: 5 }, // Maksimal 5 dokumen tambahan
    { name: 'files', maxCount: 5 } // Field dari Flutter
]);

// Helper: buat middleware single upload untuk field tertentu
const createSingle = (fieldName) => upload.single(fieldName);

module.exports = {
    uploadLampiran,
    createSingle,
};
