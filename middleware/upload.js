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
    const allowedTypes = /jpeg|jpg|png|pdf/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);

    if (mimetype && extname) {
        return cb(null, true);
    } else {
        cb(new Error('File type not allowed. Only JPEG, PNG, and PDF files are allowed.'));
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
    { name: 'dokumen_lain', maxCount: 5 } // Maksimal 5 dokumen tambahan
]);

module.exports = {
    uploadLampiran
};
